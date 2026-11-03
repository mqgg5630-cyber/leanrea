#!/usr/bin/env python3
"""Build a 5x2 style sheet for one source photo.

Usage:
    python3 scripts/batch_sheet.py 10-couple-cn

Scans examples/out/*/<stem>.jpg and writes examples/batch-<stem>.jpg plus
examples/batch-<stem>.html. Order follows STYLE_ORDER in gallery.py.
"""
import html
import os
import sys

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gallery import EX, OUT, STYLE_ORDER, STYLE_NAMES, BG, INK  # noqa: E402

CELL = 470
PAD = 18
LABEL = 34
COLS = 5


def main():
    if len(sys.argv) < 2:
        sys.exit("usage: batch_sheet.py <source-stem>")
    stem = sys.argv[1]

    rows = []
    for sid in STYLE_ORDER:
        p = os.path.join(OUT, sid, stem + ".jpg")
        if os.path.exists(p):
            rows.append((sid, p))
    if not rows:
        sys.exit(f"no outputs for {stem}")

    ncol = min(COLS, len(rows))
    nrow = (len(rows) + ncol - 1) // ncol
    w = PAD + ncol * (CELL + PAD)
    h = PAD + nrow * (CELL + LABEL + PAD)
    sheet = Image.new("RGB", (w, h), BG)
    d = ImageDraw.Draw(sheet)

    for i, (sid, p) in enumerate(rows):
        c, r = i % ncol, i // ncol
        x = PAD + c * (CELL + PAD)
        y = PAD + r * (CELL + LABEL + PAD)
        d.text((x + 4, y + 10), STYLE_NAMES.get(sid, sid), fill=INK)
        im = Image.open(p).convert("RGB")
        im.thumbnail((CELL, CELL), Image.LANCZOS)
        sheet.paste(im, (x + (CELL - im.width) // 2, y + LABEL + (CELL - im.height) // 2))

    out = os.path.join(EX, f"batch-{stem}.jpg")
    sheet.save(out, quality=86, optimize=True)
    print("wrote", out, sheet.size, f"{len(rows)} styles")

    cards = "".join(
        f'<figure><img src="out/{sid}/{stem}.jpg" loading="lazy">'
        f'<figcaption>{html.escape(STYLE_NAMES.get(sid, sid))}</figcaption></figure>'
        for sid, _ in rows
    )
    page = f"""<!doctype html><meta charset="utf-8"><title>{html.escape(stem)} · 风格对照</title>
<style>
body{{background:#F5F1E8;color:#3B2314;font:15px/1.5 -apple-system,"PingFang SC",sans-serif;margin:0;padding:28px}}
h1{{font-size:20px;margin:0 0 18px}} .row{{display:flex;flex-wrap:wrap;gap:14px}}
figure{{margin:0;background:#fff;border-radius:12px;padding:8px;box-shadow:0 1px 4px rgba(0,0,0,.07)}}
img{{display:block;max-height:380px;border-radius:8px}}
figcaption{{font-size:12px;opacity:.6;margin-top:6px;text-align:center}}
</style>
<h1>{html.escape(stem)} · 10 种治愈可爱动漫风</h1>
<div class="row">{cards}</div>
"""
    with open(os.path.join(EX, f"batch-{stem}.html"), "w", encoding="utf-8") as f:
        f.write(page)


if __name__ == "__main__":
    main()
