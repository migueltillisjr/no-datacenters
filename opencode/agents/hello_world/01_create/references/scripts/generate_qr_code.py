#!/usr/bin/env python3

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path
from urllib.parse import urlparse

import qrcode


MEDIA_DIR = Path(__file__).resolve().parent
DEFAULT_OUTPUT = MEDIA_DIR / "qr-code.jpg"
DATA_FILE = MEDIA_DIR.parent / "CARD_DATA.json"


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Generate the predefined website QR code.")
    parser.add_argument(
        "-o",
        "--output",
        type=Path,
        default=DEFAULT_OUTPUT,
        help=f"JPEG output path (default: {DEFAULT_OUTPUT.name})",
    )
    parser.add_argument(
        "--data-file",
        type=Path,
        default=DATA_FILE,
        help=f"CARD_DATA.json path (default: {DATA_FILE})",
    )
    return parser


def main() -> None:
    args = build_parser().parse_args()
    data = json.loads(args.data_file.read_text(encoding="utf-8"))
    if "qr_destination" not in data:
        raise ValueError("CARD_DATA.json must define qr_destination")
    qr_destination = data["qr_destination"]
    parsed = urlparse(str(qr_destination))
    if parsed.scheme not in {"http", "https"} or not parsed.netloc:
        raise ValueError("qr_destination must be a valid HTTP(S) URL")

    qr_code = qrcode.QRCode(
        version=None,
        error_correction=qrcode.constants.ERROR_CORRECT_M,
        box_size=10,
        border=4,
    )
    qr_code.add_data(qr_destination)
    qr_code.make(fit=True)
    image = qr_code.make_image(fill_color="black", back_color="white").convert("RGB")
    args.output.parent.mkdir(parents=True, exist_ok=True)
    generated_at = datetime.now(timezone.utc).isoformat()
    image.save(args.output, format="JPEG", quality=95, comment=f"Generated {generated_at}".encode())
    print(f"Generated {args.output} for {qr_destination} at {generated_at}")


if __name__ == "__main__":
    main()