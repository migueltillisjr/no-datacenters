#!/usr/bin/env python3
"""Generate assets and assemble the split sources into the reference and final HTML files."""

import shutil
import subprocess
import sys
import html
import json
from pathlib import Path
from urllib.parse import urlparse

REFERENCE_ROOT = Path(__file__).resolve().parent.parent
STAGE_ROOT = REFERENCE_ROOT.parent
REFERENCE_OUTPUT = REFERENCE_ROOT / "TEMPLATE.html"
FINAL_OUTPUT = STAGE_ROOT / "output" / "business_card.html"
REFERENCE_IMAGES = REFERENCE_ROOT / "images"
FINAL_IMAGES = STAGE_ROOT / "output" / "images"
PORTRAIT = REFERENCE_IMAGES / "headshot_pic.jpg"
QR_CODE = REFERENCE_IMAGES / "qr-code.jpg"
QR_GENERATOR = REFERENCE_ROOT / "scripts" / "generate_qr_code.py"
DATA_FILE = REFERENCE_ROOT / "CARD_DATA.json"

STYLE_FILES = [
    "styles/base.css",
    "styles/front.css",
    "styles/back.css",
    "styles/print.css",
]
PARTIAL_FILES = [
    "partials/front.html",
    "partials/back.html",
]


def read(relative_path: str) -> str:
    return (REFERENCE_ROOT / relative_path).read_text(encoding="utf-8").strip()


def load_card_data() -> dict[str, str]:
    data = json.loads(DATA_FILE.read_text(encoding="utf-8"))
    required = {"business_name", "person_name", "title", "phone", "email", "website", "website_url", "qr_destination"}
    missing = required - data.keys()
    if missing:
        raise ValueError(f"Missing CARD_DATA.json fields: {', '.join(sorted(missing))}")
    for field in ("website_url", "qr_destination"):
        parsed = urlparse(str(data[field]))
        if parsed.scheme not in {"http", "https"} or not parsed.netloc:
            raise ValueError(f"{field} must be a valid HTTP(S) URL")
    return {key: html.escape(str(value)) for key, value in data.items()}


def generate_assets() -> None:
    if not PORTRAIT.exists():
        raise FileNotFoundError(f"Portrait image not found: {PORTRAIT}")

    REFERENCE_IMAGES.mkdir(parents=True, exist_ok=True)
    QR_CODE.unlink(missing_ok=True)
    subprocess.run(
        [
            sys.executable,
            str(QR_GENERATOR),
            "--data-file",
            str(DATA_FILE),
            "--output",
            str(QR_CODE),
        ],
        check=True,
    )

    FINAL_IMAGES.mkdir(parents=True, exist_ok=True)
    shutil.copy2(PORTRAIT, FINAL_IMAGES / PORTRAIT.name)
    shutil.copy2(QR_CODE, FINAL_IMAGES / QR_CODE.name)


def main() -> None:
    data = load_card_data()
    generate_assets()
    styles = "\n\n".join(read(path) for path in STYLE_FILES)
    cards = "\n\n".join(read(path) for path in PARTIAL_FILES)
    for key, value in data.items():
        cards = cards.replace("{{" + key + "}}", value)
    document = f'''<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{data["business_name"]} - Business Card</title>
<style>
  @import url('https://fonts.googleapis.com/css2?family=Sora:wght@400;500;600;700;800&display=swap');

{styles}
</style>
</head>
<body>
{cards}
</body>
</html>
'''
    REFERENCE_OUTPUT.write_text(document, encoding="utf-8")
    FINAL_OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    FINAL_OUTPUT.write_text(document, encoding="utf-8")
    print(f"Wrote {REFERENCE_OUTPUT}")
    print(f"Wrote {FINAL_OUTPUT}")


if __name__ == "__main__":
    main()
