#!/usr/bin/env python3
"""Build a contact sheet for scribble-couple examples.

Usage:
    python3 scripts/sheet.py                 # examples/out  -> examples/contact-sheet.jpg
    python3 scripts/sheet.py out-v2          # examples/out-v2 -> examples/contact-sheet-v2.jpg

Only depends on Pillow.
"""
import os
import sys

from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SUB = sys.argv[1] if len(sys.argv) > 1 else "out"
OUT = os.path.join(ROOT, "examples", SUB)
EX = os.path.join(ROOT, "examples")
STEM = "contact-sheet" if SUB == "out" else f"contact-sheet-{SUB.replace('out-', '')}"
CELL = 520
PAD = 18
LABEL = 30
COLS = 3
BG = (255, 255, 255)
INK = (40, 40, 40)


def main():
    files = sorted(f for f in os.listdir(OUT) if f.lower().endswith(".jpg"))
    if not files:
        raise SystemExit(f"no images in {OUT}")
    rows = (len(files) + COLS - 1) // COLS
    w = PAD + COLS * (CELL + PAD)
    h = PAD + rows * (CELL + LABEL + PAD)
    sheet = Image.new("RGB", (w, h), BG)
    d = ImageDraw.Draw(sheet)

    for i, name in enumerate(files):
        c, r = i % COLS, i // COLS
        x = PAD + c * (CELL + PAD)
        y = PAD + r * (CELL + LABEL + PAD)
        d.text((x + 2, y + 8), name.rsplit(".", 1)[0], fill=INK)
        im = Image.open(os.path.join(OUT, name)).convert("RGB")
        im.thumbnail((CELL, CELL), Image.LANCZOS)
        sheet.paste(im, (x + (CELL - im.width) // 2, y + LABEL + (CELL - im.height) // 2))
        d.rectangle([x, y + LABEL, x + CELL, y + LABEL + CELL], outline=(230, 230, 230))

    out = os.path.join(EX, STEM + ".jpg")
    sheet.save(out, quality=88, optimize=True)
    print("wrote", out, sheet.size, f"{len(files)} images")


if __name__ == "__main__":
    main()
