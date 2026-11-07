#!/usr/bin/env python3
"""Render the assembled business card as a portable, two-page PDF."""

import json
import sys
import tempfile
from pathlib import Path

try:
    from fpdf import FPDF
    from PIL import Image, ImageChops, ImageDraw
except ImportError:
    print("Missing dependency. Install the project's requirements.txt first.", file=sys.stderr)
    sys.exit(1)

STAGE_ROOT = Path(__file__).resolve().parent.parent.parent
DATA_FILE = STAGE_ROOT / "references" / "CARD_DATA.json"
IMAGES_DIR = STAGE_ROOT / "output" / "images"
PDF_FILE = STAGE_ROOT / "output" / "business_card.pdf"

TEAL = (15, 118, 110)
TEAL_DARK = (11, 90, 84)
CREAM = (241, 239, 233)
CREAM_SOFT = (232, 229, 220)
INK = (27, 27, 27)
MUTED = (90, 89, 83)
PAGE_WIDTH = 3.75
PAGE_HEIGHT = 2.25
CARD_X = 0.0
CARD_Y = 0.0
CARD_WIDTH = PAGE_WIDTH
CARD_HEIGHT = PAGE_HEIGHT


def load_data() -> dict[str, str]:
    return json.loads(DATA_FILE.read_text(encoding="utf-8"))


def add_card_page(pdf: FPDF, data: dict[str, str], front: bool) -> None:
    pdf.add_page()
    pdf.set_fill_color(*(CREAM if front else TEAL_DARK))
    pdf.rect(0, 0, PAGE_WIDTH, PAGE_HEIGHT, style="F")
    if not front:
        pdf.set_fill_color(*TEAL)
        pdf.rect(CARD_X, CARD_Y, CARD_WIDTH, CARD_HEIGHT, style="F")

    if front:
        draw_front(pdf, data)
    else:
        draw_back(pdf, data)


def fit_font_size(
    pdf: FPDF, text: str, family: str, style: str, start_size: float, max_width: float, min_size: float = 5.0
) -> float:
    """Shrink the font size until `text` fits within `max_width`, so long
    strings never overflow into the adjacent photo column."""
    size = start_size
    pdf.set_font(family, style, size)
    while size > min_size and pdf.get_string_width(text) > max_width:
        size -= 0.3
        pdf.set_font(family, style, size)
    return size


def draw_front(pdf: FPDF, data: dict[str, str]) -> None:
    left = 0.36
    top = 0.36
    content_width = 1.48
    photo_left = 1.86
    text_gap = 0.04

    pdf.set_fill_color(*TEAL)
    pdf.ellipse(left, top + 0.015, 0.07, 0.07, style="F")
    pdf.set_text_color(*INK)
    business_name_x = left + 0.11
    fit_font_size(pdf, data["business_name"].upper(), "Helvetica", "B", 10, photo_left - text_gap - business_name_x)
    pdf.set_xy(business_name_x, top)
    pdf.cell(content_width, 0.1, data["business_name"].upper())

    pdf.set_text_color(*INK)
    fit_font_size(pdf, data["person_name"], "Helvetica", "B", 15, photo_left - text_gap - left)
    pdf.set_xy(left, top + 0.28)
    pdf.cell(content_width, 0.2, data["person_name"])

    pdf.set_text_color(*TEAL)
    fit_font_size(pdf, data["title"].upper(), "Helvetica", "B", 7, photo_left - text_gap - left)
    pdf.set_xy(left, top + 0.52)
    pdf.cell(content_width, 0.1, data["title"].upper())

    pdf.set_text_color(*INK)
    tagline = "Real Outcomes. Real ROI. Real Results."
    fit_font_size(pdf, tagline, "Helvetica", "B", 6.8, photo_left - text_gap - left)
    pdf.set_xy(left, top + 0.68)
    pdf.cell(content_width, 0.1, tagline)

    pdf.set_draw_color(*CREAM_SOFT)
    pdf.line(left, 1.24, left + content_width, 1.24)

    contact_rows = (data["phone"], data["email"], data["website"])
    contact_x = left + 0.1
    for index, value in enumerate(contact_rows):
        y = 1.38 + index * 0.16
        pdf.set_text_color(*TEAL)
        pdf.ellipse(left, y + 0.015, 0.055, 0.055, style="F")
        pdf.set_text_color(*MUTED)
        fit_font_size(pdf, value, "Helvetica", "B", 6.7, photo_left - text_gap - contact_x)
        pdf.set_xy(contact_x, y)
        pdf.cell(photo_left - text_gap - contact_x, 0.08, value)

    photo = IMAGES_DIR / "headshot_pic.jpg"
    photo_w, photo_h = 1.60, 2.0
    if photo.is_file():
        with tempfile.TemporaryDirectory(prefix="business-card-assets-") as temp_dir:
            portrait = Path(temp_dir) / "portrait.png"
            make_rounded_portrait(photo, portrait, photo_w, photo_h)
            pdf.image(str(portrait), x=2.00, y=0.125, w=photo_w, h=photo_h)
    else:
        pdf.set_fill_color(*CREAM_SOFT)
        pdf.rect(1.92, 0.05, 1.76, 2.14, style="F")
        pdf.set_text_color(*TEAL)
        pdf.set_font("Helvetica", "B", 20)
        pdf.set_xy(2.55, 1.0)
        pdf.cell(0.5, 0.2, "MT", align="C")


def draw_back(pdf: FPDF, data: dict[str, str]) -> None:
    pdf.set_fill_color(8, 78, 73)
    pdf.ellipse(-0.2, -0.2, 0.95, 0.95, style="F")
    pdf.set_fill_color(22, 132, 122)
    pdf.ellipse(3.1, 1.55, 0.9, 0.9, style="F")

    pdf.set_text_color(*CREAM)
    pdf.set_font("Helvetica", "B", 13)
    pdf.set_xy(CARD_X, 0.53)
    pdf.cell(CARD_WIDTH, 0.18, data["business_name"].upper(), align="C")

    pdf.set_font("Helvetica", "B", 8.5)
    pdf.set_xy(0.45, 0.88)
    pdf.cell(2.85, 0.12, "Real Outcomes. Real ROI. Real Results.", align="C")
    pdf.set_font("Helvetica", "B", 7)
    pdf.set_xy(0.45, 1.08)
    pdf.cell(2.85, 0.12, "Via Sustainable Accessible and Transparent AI.", align="C")

    qr = IMAGES_DIR / "qr-code.jpg"
    if qr.is_file():
        pdf.image(str(qr), x=1.35, y=1.38, w=0.58, h=0.58)
    pdf.set_font("Helvetica", "B", 7)
    pdf.set_xy(2.0, 1.59)
    pdf.cell(1.0, 0.1, "Scan for Contact Info")


def make_rounded_portrait(source: Path, destination: Path, target_w: float, target_h: float) -> None:
    image = Image.open(source).convert("RGB")

    # emulate CSS object-fit: cover, center-cropping so the source aspect
    # ratio matches the placement box instead of stretching it
    target_ratio = target_w / target_h
    src_ratio = image.width / image.height
    if src_ratio > target_ratio:
        new_width = round(image.height * target_ratio)
        left = (image.width - new_width) // 2
        image = image.crop((left, 0, left + new_width, image.height))
    else:
        new_height = round(image.width / target_ratio)
        top = (image.height - new_height) // 2
        image = image.crop((0, top, image.width, top + new_height))

    image.thumbnail((900, 900), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", image.size, (0, 0, 0, 0))
    canvas.paste(image, (0, 0))

    # match the HTML frame's pill shape: border-radius: 50% 20px 20px 50%
    # (fully rounded left edge, slightly rounded right corners). Build the two
    # sides as separate masks and AND them together, since drawing both onto
    # one mask would re-fill each other's rounded corners as square.
    box = (0, 0, image.width - 1, image.height - 1)
    left_radius = image.height // 2
    right_radius = max(1, int(image.height * 0.09))

    left_mask = Image.new("L", image.size, 0)
    ImageDraw.Draw(left_mask).rounded_rectangle(
        box, radius=left_radius, fill=255, corners=(True, False, False, True)
    )
    right_mask = Image.new("L", image.size, 0)
    ImageDraw.Draw(right_mask).rounded_rectangle(
        box, radius=right_radius, fill=255, corners=(False, True, True, False)
    )
    mask = ImageChops.darker(left_mask, right_mask)
    canvas.putalpha(mask)
    canvas.save(destination, format="PNG")


def main() -> None:
    data = load_data()
    PDF_FILE.parent.mkdir(parents=True, exist_ok=True)
    # format is given as (width, height); orientation="L" would swap them, so use "P" to keep 3.75x2.25 landscape
    pdf = FPDF(orientation="P", unit="in", format=(3.75, 2.25))
    pdf.set_auto_page_break(False)
    add_card_page(pdf, data, front=True)
    add_card_page(pdf, data, front=False)
    pdf.output(str(PDF_FILE))
    print(f"Wrote {PDF_FILE}")


if __name__ == "__main__":
    main()
