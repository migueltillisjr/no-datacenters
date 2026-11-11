#!/usr/bin/env python3
"""Focused tests for the dependency-free autonomous service."""

from __future__ import annotations

import json
import os
import signal
import subprocess
import sys
import tempfile
import time
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
SERVICE = ROOT / "autonomous" / "service.py"


class AutonomousServiceTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp_dir = tempfile.TemporaryDirectory()
        self.work = Path(self.temp_dir.name)

    def tearDown(self) -> None:
        self.temp_dir.cleanup()

    def command(self, name: str, body: str) -> str:
        path = self.work / name
        path.write_text("#!/bin/sh\nset -eu\n" + body + "\n", encoding="utf-8")
        path.chmod(0o700)
        return str(path)

    def run_service(self, status: str, result: str = "done", retries: int = 2, interval: str = "0.01", timeout: str = "0.2", extra: dict[str, str] | None = None) -> subprocess.CompletedProcess[str]:
        status_command = self.command("status.sh", status)
        result_command = self.command("result.sh", f"printf '%s' {result!r}")
        env = os.environ.copy()
        env.update({
            "AUTONOMOUS_INTERVAL_SECONDS": interval,
            "AUTONOMOUS_MAX_RETRIES": str(retries),
            "AUTONOMOUS_TIMEOUT_SECONDS": timeout,
            "AUTONOMOUS_STATUS_COMMAND": status_command,
            "AUTONOMOUS_RESULT_COMMAND": result_command,
            "AUTONOMOUS_LOG_FILE": str(self.work / "service.log"),
            "AUTONOMOUS_RESULT_FILE": str(self.work / "result.txt"),
        })
        if extra:
            env.update(extra)
        return subprocess.run([sys.executable, str(SERVICE)], cwd=ROOT, env=env, text=True, capture_output=True, timeout=5)

    def read_events(self) -> list[dict[str, object]]:
        return [json.loads(line) for line in (self.work / "service.log").read_text(encoding="utf-8").splitlines()]

    def test_pending_then_ready(self) -> None:
        status = self.command("status.sh", 'if [ ! -f "$STATUS_MARKER" ]; then touch "$STATUS_MARKER"; printf pending; else printf ready; fi')
        marker = self.work / "marker"
        env = os.environ.copy()
        env.update({"STATUS_MARKER": str(marker), "AUTONOMOUS_INTERVAL_SECONDS": "0.01", "AUTONOMOUS_MAX_RETRIES": "1", "AUTONOMOUS_TIMEOUT_SECONDS": "0.2", "AUTONOMOUS_STATUS_COMMAND": status, "AUTONOMOUS_RESULT_COMMAND": "printf result", "AUTONOMOUS_LOG_FILE": str(self.work / "service.log"), "AUTONOMOUS_RESULT_FILE": str(self.work / "result.txt")})
        completed = subprocess.run([sys.executable, str(SERVICE)], cwd=ROOT, env=env, text=True, capture_output=True, timeout=5)
        self.assertEqual(completed.returncode, 0, completed.stderr)
        self.assertEqual((self.work / "result.txt").read_text(), "result")

    def test_success_and_result_is_not_duplicated_on_restart(self) -> None:
        first = self.run_service("printf ready")
        second = self.run_service("printf failed")
        self.assertEqual(first.returncode, 0, first.stderr)
        self.assertEqual(second.returncode, 0, second.stderr)
        self.assertEqual([event["event"] for event in self.read_events()][-1], "already_completed")

    def test_retry_then_success(self) -> None:
        status = self.command("status.sh", 'if [ ! -f "$RETRY_MARKER" ]; then touch "$RETRY_MARKER"; printf failed; else printf ready; fi')
        completed = self.run_with_status(status, {"RETRY_MARKER": str(self.work / "retry")})
        self.assertEqual(completed.returncode, 0, completed.stderr)
        self.assertIn("retrying", [event["event"] for event in self.read_events()])

    def test_retry_exhaustion_and_malformed_status(self) -> None:
        completed = self.run_service("printf nonsense", retries=1)
        self.assertEqual(completed.returncode, 1)
        events = self.read_events()
        self.assertEqual(events[-1]["event"], "failed")
        self.assertEqual(events[-1]["reason"], "malformed_status")

    def test_timeout(self) -> None:
        completed = self.run_service("sleep 1", retries=0, timeout="0.05")
        self.assertEqual(completed.returncode, 1)
        self.assertEqual(self.read_events()[-1]["reason"], "status_timeout")

    def test_signal_shutdown(self) -> None:
        status = self.command("status.sh", "sleep 5")
        env = os.environ.copy()
        env.update({"AUTONOMOUS_INTERVAL_SECONDS": "1", "AUTONOMOUS_MAX_RETRIES": "1", "AUTONOMOUS_TIMEOUT_SECONDS": "5", "AUTONOMOUS_STATUS_COMMAND": status, "AUTONOMOUS_RESULT_COMMAND": "printf result", "AUTONOMOUS_LOG_FILE": str(self.work / "service.log"), "AUTONOMOUS_RESULT_FILE": str(self.work / "result.txt")})
        process = subprocess.Popen([sys.executable, str(SERVICE)], cwd=ROOT, env=env, text=True)
        time.sleep(0.1)
        process.send_signal(signal.SIGTERM)
        self.assertEqual(process.wait(timeout=3), 143)
        self.assertEqual(self.read_events()[-1]["event"], "shutdown")

    def run_with_status(self, status: str, extra: dict[str, str]) -> subprocess.CompletedProcess[str]:
        return self.run_service("printf ready", extra={**extra, "AUTONOMOUS_STATUS_COMMAND": status})


if __name__ == "__main__":
    unittest.main()
