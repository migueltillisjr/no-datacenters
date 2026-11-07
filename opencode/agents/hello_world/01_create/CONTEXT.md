## Rules

- For python script `*.py` scripts, Use the shared python agent environment at `/orchestra/environments/agents/business_card`; its dependencies are already installed.
- Run every Python command through `/orchestra/environments/agents/agents/hello_world/bin/python` so the shared environment's libraries are used.
- Do not create a local virtual environment, install packages, or fall back to the system interpreter. If the shared environment is missing, stop and report it.
- Always save generated work to disk in `agents/hello_world/01_create/output/business_card.html`. Do not merely display the design in chat.
- Never generate assets or modify the card before the mandatory Confirm Card Data step below is complete.
- Keep `TEMPLATE.html` as one runnable document with exactly two `.card` surfaces: `.front` first and `.back` second.
- After this process completes successfully, continue by following `agents/hello_world/02_print_prep/CONTEXT.md` to copy the card forward and export it.

## Source Layout

| Path | Responsibility |
|------|----------------|
| `agents/hello_world/01_create/CONTEXT.md` | Authoritative design brief and exact copy (this file) |
| `agents/hello_world/01_create/references/CARD_DATA.json` | Templated business name, person name, phone, email, website, and fixed QR destination |
| `agents/hello_world/01_create/references/partials/front.html` | Front card markup and inline icons |
| `agents/hello_world/01_create/references/partials/back.html` | Back card markup and QR area |
| `agents/hello_world/01_create/references/images/` | Canonical portrait and generated QR assets |
| `agents/hello_world/01_create/references/styles/base.css` | Tokens, reset, page preview, shared card rules |
| `agents/hello_world/01_create/references/styles/front.css` | Front-side layout and portrait treatment |
| `agents/hello_world/01_create/references/styles/back.css` | Back-side gradient, typography, marks, and QR styling |
| `agents/hello_world/01_create/references/styles/print.css` | 100% print sizing, bleed, page breaks, and print cleanup |
| `agents/hello_world/01_create/references/scripts/build_template.py` | Deterministic assembler for businss card,  `TEMPLATE.html` and `output/business_card.html` |
| `agents/hello_world/01_create/references/scripts/generate_qr_code.py` | Regenerates `agents/hello_world/01_create/output/images/qr-code.jpg` from `agents/hello_world/01_create/references/CARD_DATA.json`'s `qr_destination` |
| `agents/hello_world/01_create/references/TEMPLATE.html` | Runnable assembled preview and print source |

## Mandatory First Step: Confirm Card Data

Before building, generating a QR code, copying assets, editing card markup, or modifying the assembled output, always read `agents/hello_world/01_create/references/CARD_DATA.json` and show the user its current values in a readable JSON block. Then ask exactly:

> Please confirm that the `agents/hello_world/01_create/references/CARD_DATA.json` information is correct before I continue. Reply `confirm` to proceed, or provide the corrections you want written to the file.

Stop and wait for the user's response. Do not continue on implied approval, silence, or a general request to build. If the user provides corrections, update only the requested fields in `agents/hello_world/01_create/references/CARD_DATA.json`, display the complete updated JSON again, and ask for confirmation again. Continue only after an explicit confirmation such as `confirm`, `yes, it is correct`, or equivalent.

After confirmation, validate that `website_url` and `qr_destination` are both valid HTTP(S) URLs. They may be different. Only then inspect assets, generate the QR code, and build the card.

## Process

1. Edit the source section files (`agents/hello_world/01_create/references/partials/`, `agents/hello_world/01_create/references/styles/`) and `agents/hello_world/01_create/references/CARD_DATA.json` — never the generated assembled HTML directly.
2. Install dependencies with `/orchestra/environments/agents/agents/hello_world/bin/python -m pip install -r agents/hello_world/requirements.txt` when needed.
3. Run `/orchestra/environments/agents/agents/hello_world/bin/python agents/hello_world/01_create/references/scripts/build_template.py`.
4. Every build removes and regenerates `qr-code.jpg` by explicitly passing `agents/hello_world/01_create/references/CARD_DATA.json` to `agents/hello_world/01_create/references/scripts/generate_qr_code.py`; the script encodes only that file's independent `qr_destination` URL and validates it separately from `website_url`.
5. The build copies `headshot_pic.jpg` and the fresh `qr-code.jpg` into `agents/hello_world/01_create/output/images/`, then assembles the final HTML with `images/...` paths, saving it to `agents/hello_world/01_create/output/business_card.html`.
6. Tell the user to review the HTML output; `agents/hello_world/01_create/references/TEMPLATE.html` is the maintained assembled reference, not the final delivery location.

## Design Process

- Use `agents/hello_world/01_create/references/TEMPLATE.html` as the HTML/CSS starting point and preserve its established `.card`, `.front`, `.back`, portrait, QR, and print-layout hooks.
- Use `agents/hello_world/01_create/references/CARD_DATA.json` as the templated source for the business name, person name, phone, email, website, and QR destination. `website_url` is the displayed website and `qr_destination` is an independent URL that may point elsewhere. Do not hardcode those identity values in generated markup or scripts.
- Business card size: **3.5 × 2 inches**, landscape orientation.
- Preserve exact print dimensions while making the browser preview responsive.
- Display front and back cards side by side in the browser preview.
- Use rounded corners and soft shadows for the digital preview only.
- Remove shadows and rounded corners when printing.
- Include print styles for 100% scale and actual-size printing.
- Ensure each side prints on its own page.
- Maintain generous internal padding, print-safe spacing, and bleed awareness.
- Do not place explanatory marketing copy outside the card designs.

## Visual System

Use a warm cream base, deep teal branding, near-black text, and restrained decoration. Typography should be similar to Sora: bold, geometric, and sans-serif.

| Token | Value |
|-------|-------|
| Deep teal | `#0F766E` |
| Dark teal | `#0B5A54` |
| Warm cream | `#F1EFE9` |
| Soft cream-gray | `#E8E5DC` |
| Near-black | `#1B1B1B` |
| Muted gray | `#5A5953` |

Avoid clutter, excessive gradients, and unnecessary decorative elements. Use `-webkit-print-color-adjust: exact` and `print-color-adjust: exact` in print styles.

## Front Side

Create a warm cream card with a split visual composition.

### Left Content Area

Use a small teal circular dot followed by uppercase text for the Info Pioneer wordmark. The wordmark should be the strongest typographic element on the front. Keep the following content aligned and easy to scan:

- **Info Pioneer**
- **Miguel Tillis Jr.**
- **TECH CONSULTANT · FOUNDER**
- **Real Outcomes. Real ROI. Real Results.**

Contact information:

- Phone: `619-704-5891`
- Email: `miguel@infopioneer.ai`
- Website: `infopnr.com`

Use small teal line icons for phone, email, and website. The title must be teal and uppercase. The tagline must be bold, black, and compact. Prevent all left-side content from overlapping the portrait.

### Right Photo Area

Use `headshot_pic.jpg` as the portrait image if it is available. Place the portrait on approximately the right half of the card. Crop it into a distinctive large curved frame with a rounded outer edge, extending slightly beyond the top, right, and bottom boundaries. Separate it from the content area with a warm cream border. Preserve the subject's face and shoulders clearly, and make the result polished and editorial rather than a generic circular avatar.

If the image is unavailable, keep the layout stable and use a deliberate, non-misleading fallback rather than unrelated placeholder imagery.

## Back Side

Use a deep teal back with a subtle diagonal gradient from `#0F766E` to `#0B5A54`. Center the content horizontally and vertically. Use cream-colored text and a cream-colored dot beside the Info Pioneer wordmark.

Include:

- **Info Pioneer**
- **Real Outcomes. Real ROI. Real Results.**
- **Via Sustainable Accessible and Transparent AI.**

Add two subtle oversized translucent circular marks behind the content: one near the top-left and one near the bottom-right. Keep them understated.

## QR Code

Place a newly generated, real, scannable QR code near the lower center of the back side on every build. Encode only the predefined `qr_destination` URL from `agents/hello_world/01_create/references/CARD_DATA.json`; it may be different from the displayed `website_url`. Do not encode a vCard, contact details, or any user-supplied alternate destination. Use a small cream-translucent QR container with a thin cream border and slightly rounded corners. Add the label **Scan for Contact Info** next to or below the code. Preserve strong contrast and sufficient quiet space around the QR code so it remains scannable when printed.

## Quality Requirements

- Text must remain readable at actual print size.
- No text may touch the card edges.
- Use stable dimensions so labels, icons, the portrait, and QR code cannot shift the layout.
- Ensure the design remains usable on desktop and mobile previews.
- Do not use placeholder copy except when an image or QR asset is genuinely unavailable.
- The final result should look like a refined technology consultant business card for a founder focused on practical, sustainable, accessible, and transparent AI.
