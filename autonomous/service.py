#!/usr/bin/env python3
# Purpose: Run a local autonomous status-and-result loop with bounded retries.
# Usage:   ./autonomous/service.py [--config PATH]
# Example: AUTONOMOUS_STATUS_COMMAND='printf ready' ./autonomous/service.py

"""Small, dependency-free long-running service for local harness workflows."""

from __future__ import annotations

import argparse
import json
import logging
import os
import shlex
import signal
import subprocess
import sys
import tempfile
import threading
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Any


HARNESS_PATHS = {
    "opencode": "local/opencode/start.sh",
    "codex": "local/codex/start.sh",
    "claude_code": "local/claude_code/start.sh",
    "copilot": "local/copilot/start.sh",
}
VALID_STATUSES = {"ready", "pending", "failed"}
SECRET_WORDS = ("key", "secret", "token", "password", "credential")


class ConfigurationError(ValueError):
    """Raised when service configuration is missing or unsafe."""


class ServiceInterrupted(Exception):
    """Raised when a termination signal requests a clean shutdown."""


@dataclass(frozen=True)
class Config:
    interval_seconds: float
    max_retries: int
    timeout_seconds: float
    status_command: tuple[str, ...]
    result_command: tuple[str, ...]
    log_file: Path
    result_file: Path
    harness: str | None
    harness_args: tuple[str, ...]
    harness_log: Path


class JsonLineLogger:
    def __init__(self, path: Path) -> None:
        self.path = path
        self.path.parent.mkdir(parents=True, exist_ok=True)
        self._logger = logging.getLogger("autonomous")
        self._logger.setLevel(logging.INFO)
        handler = logging.FileHandler(self.path, encoding="utf-8")
        handler.setFormatter(logging.Formatter("%(message)s"))
        self._logger.addHandler(handler)
        self._handler = handler

    def event(self, name: str, **fields: Any) -> None:
        payload = {"timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()), "event": name}
        payload.update(fields)
        self._logger.info(json.dumps(payload, sort_keys=True))
        self._handler.flush()

    def close(self) -> None:
        self._handler.close()
        self._logger.removeHandler(self._handler)


def _read_config_file(path: str | None) -> dict[str, Any]:
    if not path:
        return {}
    config_path = Path(path).expanduser()
    try:
        with config_path.open(encoding="utf-8") as stream:
            data = json.load(stream)
    except (OSError, json.JSONDecodeError) as exc:
        raise ConfigurationError(f"cannot read config file {config_path}: {exc}") from exc
    if not isinstance(data, dict):
        raise ConfigurationError("config file must contain a JSON object")
    return {str(key).upper(): value for key, value in data.items()}


def _setting(name: str, file_config: dict[str, Any], default: Any = None) -> Any:
    return os.environ.get(name, file_config.get(name, default))


def _positive_float(name: str, value: Any) -> float:
    try:
        result = float(value)
    except (TypeError, ValueError) as exc:
        raise ConfigurationError(f"{name} must be a positive number") from exc
    if result <= 0:
        raise ConfigurationError(f"{name} must be a positive number")
    return result


def _nonnegative_int(name: str, value: Any) -> int:
    try:
        result = int(value)
    except (TypeError, ValueError) as exc:
        raise ConfigurationError(f"{name} must be a non-negative integer") from exc
    if result < 0:
        raise ConfigurationError(f"{name} must be a non-negative integer")
    return result


def _command(name: str, value: Any) -> tuple[str, ...]:
    if not isinstance(value, str) or not value.strip():
        raise ConfigurationError(f"{name} is required")
    try:
        command = tuple(shlex.split(value))
    except ValueError as exc:
        raise ConfigurationError(f"{name} is not valid shell-like command text") from exc
    if not command or any(part in {"|", ";", "&&", "||", ">", "<", "&"} for part in command):
        raise ConfigurationError(f"{name} must be a single command without shell operators")
    return command


def load_config(config_path: str | None, repo_dir: Path) -> Config:
    file_config = _read_config_file(config_path or os.environ.get("AUTONOMOUS_CONFIG_FILE"))
    status_command = _command("AUTONOMOUS_STATUS_COMMAND", _setting("AUTONOMOUS_STATUS_COMMAND", file_config))
    result_command = _command("AUTONOMOUS_RESULT_COMMAND", _setting("AUTONOMOUS_RESULT_COMMAND", file_config))
    log_file = Path(_setting("AUTONOMOUS_LOG_FILE", file_config, str(repo_dir / "autonomous.log"))).expanduser()
    result_file = Path(_setting("AUTONOMOUS_RESULT_FILE", file_config, str(repo_dir / "autonomous-result.txt"))).expanduser()
    harness = _setting("AUTONOMOUS_HARNESS", file_config)
    if harness:
        harness = str(harness)
        if harness not in HARNESS_PATHS:
            raise ConfigurationError(f"AUTONOMOUS_HARNESS must be one of: {', '.join(HARNESS_PATHS)}")
        harness_path = repo_dir / HARNESS_PATHS[harness]
        if not harness_path.is_file() or not os.access(harness_path, os.X_OK):
            raise ConfigurationError(f"configured harness is not executable: {harness_path}")
    harness_args_value = _setting("AUTONOMOUS_HARNESS_ARGS", file_config, "")
    try:
        harness_args = tuple(shlex.split(str(harness_args_value)))
    except ValueError as exc:
        raise ConfigurationError("AUTONOMOUS_HARNESS_ARGS is not valid command text") from exc
    harness_log = Path(_setting("AUTONOMOUS_HARNESS_LOG", file_config, str(log_file.with_suffix(".harness.log")))).expanduser()
    return Config(
        interval_seconds=_positive_float("AUTONOMOUS_INTERVAL_SECONDS", _setting("AUTONOMOUS_INTERVAL_SECONDS", file_config, 60)),
        max_retries=_nonnegative_int("AUTONOMOUS_MAX_RETRIES", _setting("AUTONOMOUS_MAX_RETRIES", file_config, 3)),
        timeout_seconds=_positive_float("AUTONOMOUS_TIMEOUT_SECONDS", _setting("AUTONOMOUS_TIMEOUT_SECONDS", file_config, 30)),
        status_command=status_command,
        result_command=result_command,
        log_file=log_file,
        result_file=result_file,
        harness=harness,
        harness_args=harness_args,
        harness_log=harness_log,
    )


def _safe_command_name(command: tuple[str, ...]) -> str:
    return Path(command[0]).name


def _command_exists(command: tuple[str, ...]) -> bool:
    executable = command[0]
    if os.path.isabs(executable) or "/" in executable:
        return os.access(executable, os.X_OK)
    return any(os.access(Path(directory) / executable, os.X_OK) for directory in os.environ.get("PATH", "").split(os.pathsep))


def validate_dependencies(config: Config) -> None:
    for name, command in (("status", config.status_command), ("result", config.result_command)):
        if not _command_exists(command):
            raise ConfigurationError(f"{name} command is not executable: {_safe_command_name(command)}")
    config.log_file.parent.mkdir(parents=True, exist_ok=True)
    config.result_file.parent.mkdir(parents=True, exist_ok=True)


def _classify_status(output: str) -> str:
    text = output.strip()
    try:
        parsed = json.loads(text)
    except json.JSONDecodeError:
        parsed = text.lower()
    if isinstance(parsed, dict):
        parsed = parsed.get("status")
    if not isinstance(parsed, str) or parsed.lower() not in VALID_STATUSES:
        raise ValueError("status output must be ready, pending, failed, or JSON with a status field")
    return parsed.lower()


def _terminate_process(process: subprocess.Popen[str]) -> None:
    if process.poll() is not None:
        return
    try:
        os.killpg(process.pid, signal.SIGTERM)
    except ProcessLookupError:
        return
    try:
        process.wait(timeout=2)
    except subprocess.TimeoutExpired:
        try:
            os.killpg(process.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
        process.wait()


def run_command(command: tuple[str, ...], timeout: float, stop_event: threading.Event) -> tuple[int, str, bool]:
    command_started = time.monotonic()
    try:
        process: subprocess.Popen[str] = subprocess.Popen(
            list(command),
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
            start_new_session=True,
        )
    except OSError as exc:
        raise ConfigurationError(f"cannot start {_safe_command_name(command)}: {exc}") from exc
    try:
        while True:
            if stop_event.is_set():
                _terminate_process(process)
                return 143, "", False
            try:
                remaining = timeout - (time.monotonic() - command_started)
                if remaining <= 0:
                    _terminate_process(process)
                    return 124, "", True
                stdout, _ = process.communicate(timeout=min(0.2, remaining))
                return process.returncode, stdout, False
            except subprocess.TimeoutExpired:
                if time.monotonic() - command_started >= timeout:
                    _terminate_process(process)
                    return 124, "", True
    finally:
        if process.poll() is None:
            _terminate_process(process)


def atomic_write(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists():
        return
    fd, temporary_name = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent, text=True)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as stream:
            stream.write(content)
            stream.flush()
            os.fsync(stream.fileno())
        try:
            os.link(temporary_name, path)
        except FileExistsError:
            pass
    finally:
        try:
            os.unlink(temporary_name)
        except FileNotFoundError:
            pass


def start_harness(config: Config, repo_dir: Path, logger: JsonLineLogger, stop_event: threading.Event) -> subprocess.Popen[str] | None:
    if not config.harness:
        return None
    harness_path = repo_dir / HARNESS_PATHS[config.harness]
    config.harness_log.parent.mkdir(parents=True, exist_ok=True)
    output = config.harness_log.open("a", encoding="utf-8")
    process = subprocess.Popen(
        [str(harness_path), *config.harness_args],
        cwd=repo_dir,
        stdout=output,
        stderr=subprocess.STDOUT,
        text=True,
        start_new_session=True,
    )
    logger.event("harness_started", harness=config.harness, pid=process.pid)
    stop_event.process_output = output  # type: ignore[attr-defined]
    return process


def stop_harness(process: subprocess.Popen[str] | None, stop_event: threading.Event) -> None:
    if process is not None:
        _terminate_process(process)
    output = getattr(stop_event, "process_output", None)
    if output is not None:
        output.close()


def execute(config: Config, repo_dir: Path) -> int:
    validate_dependencies(config)
    logger = JsonLineLogger(config.log_file)
    stop_event = threading.Event()

    def request_stop(signum: int, _frame: Any) -> None:
        stop_event.set()

    signal.signal(signal.SIGINT, request_stop)
    signal.signal(signal.SIGTERM, request_stop)
    harness_process: subprocess.Popen[str] | None = None
    started = time.monotonic()
    try:
        if config.result_file.exists() and config.result_file.stat().st_size > 0:
            logger.event("already_completed", result_file=str(config.result_file), exit_status=0)
            return 0
        harness_process = start_harness(config, repo_dir, logger, stop_event)
        logger.event("started", attempt=0, elapsed_seconds=0.0)
        failed_attempts = 0
        while not stop_event.is_set():
            status_code, status_output, timed_out = run_command(config.status_command, config.timeout_seconds, stop_event)
            if stop_event.is_set():
                raise ServiceInterrupted
            if timed_out:
                status = "failed"
                reason = "status_timeout"
            elif status_code != 0:
                status = "failed"
                reason = "status_exit"
            else:
                try:
                    status = _classify_status(status_output)
                    reason = ""
                except ValueError:
                    status = "failed"
                    reason = "malformed_status"
            logger.event("status_checked", status=status, attempt=failed_attempts, reason=reason or None, elapsed_seconds=round(time.monotonic() - started, 3))
            if status == "pending":
                if stop_event.wait(config.interval_seconds):
                    raise ServiceInterrupted
                continue
            if status == "failed":
                failed_attempts += 1
                if failed_attempts > config.max_retries:
                    logger.event("failed", attempt=failed_attempts, reason=reason or "status_failed", exit_status=1)
                    return 1
                logger.event("retrying", attempt=failed_attempts, max_retries=config.max_retries)
                if stop_event.wait(config.interval_seconds):
                    raise ServiceInterrupted
                continue
            result_code, result_output, result_timed_out = run_command(config.result_command, config.timeout_seconds, stop_event)
            if stop_event.is_set():
                raise ServiceInterrupted
            if result_code == 0 and not result_timed_out:
                atomic_write(config.result_file, result_output)
                logger.event("completed", attempt=failed_attempts, result_file=str(config.result_file), exit_status=0)
                return 0
            failed_attempts += 1
            reason = "result_timeout" if result_timed_out else "result_exit"
            if failed_attempts > config.max_retries:
                logger.event("failed", attempt=failed_attempts, reason=reason, exit_status=1)
                return 1
            logger.event("retrying", attempt=failed_attempts, max_retries=config.max_retries, reason=reason)
            if stop_event.wait(config.interval_seconds):
                raise ServiceInterrupted
        raise ServiceInterrupted
    except ServiceInterrupted:
        logger.event("shutdown", attempt=0, reason="signal", exit_status=143)
        return 143
    finally:
        stop_harness(harness_process, stop_event)
        logger.close()


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--config", help="optional JSON configuration file")
    args = parser.parse_args(argv)
    repo_dir = Path(__file__).resolve().parent.parent
    try:
        config = load_config(args.config, repo_dir)
        return execute(config, repo_dir)
    except ConfigurationError as exc:
        print(f"autonomous: configuration error: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
