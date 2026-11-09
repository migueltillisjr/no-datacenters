#!/usr/bin/env python3
"""Check relative Markdown links against files in the repository.

Usage: python3 scripts/check_links.py
"""

from __future__ import annotations

import re
import sys
from pathlib import Path
from urllib.parse import unquote, urlparse

ROOT = Path(__file__).resolve().parents[1]
LINK_RE = re.compile(r"!?\[[^\]]*\]\(([^)]+)\)")


def markdown_files() -> list[Path]:
    return sorted(
        path
        for path in ROOT.rglob("*.md")
        if ".git" not in path.parts
        and not any(part.endswith(("_venv", ".venv")) for part in path.parts)
    )


def check_file(path: Path) -> list[str]:
    errors: list[str] = []
    for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        for raw_target in LINK_RE.findall(line):
            target = raw_target.strip().split()[0].strip("<>")
            parsed = urlparse(target)
            if parsed.scheme or target.startswith("//") or target.startswith("#"):
                continue

            target_path = unquote(parsed.path)
            resolved = (path.parent / target_path).resolve()
            try:
                resolved.relative_to(ROOT)
            except ValueError:
                errors.append(f"{path.relative_to(ROOT)}:{line_number}: link escapes repository: {target}")
                continue

            if not resolved.exists():
                errors.append(f"{path.relative_to(ROOT)}:{line_number}: missing link target: {target}")
    return errors


def main() -> int:
    errors = [error for path in markdown_files() for error in check_file(path)]
    if errors:
        print("Markdown link check failed:", file=sys.stderr)
        print("\n".join(errors), file=sys.stderr)
        return 1
    print(f"Markdown link check passed ({len(markdown_files())} files).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
