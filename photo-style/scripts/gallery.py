#!/usr/bin/env python3
"""Build a contact sheet + preview.html for photo-style test runs.

Usage:
    python3 scripts/gallery.py            # writes examples/contact-sheet.jpg + preview.html

Reads  examples/sources/*.jpg|png|webp  and  examples/out/<style-id>/*
and lays them out as rows = style, columns = source. Missing cells stay empty,
so the sheet can be rebuilt while a test batch is still running.
"""
import html
import os
import sys

from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
EX = os.path.join(ROOT, "examples")
SRC = os.path.join(EX, "sources")
OUT = os.path.join(EX, "out")
CELL = 340
PAD = 16
LABEL = 30
BG = (245, 241, 232)
INK = (59, 35, 20)

STYLE_NAMES = {
    "s1-anime-cel": "R01 动漫赛璐璐",
    "s2-ghibli": "R02 吉卜力绘本",
    "s3-crayon": "R03 奶油蜡笔",
    "s4-clay": "R04 3D 黏土",
    "s5-watercolor": "R05 透明水彩",
    "s9-felt": "R09 毛毡玩偶",
    "s10-colored-pencil": "R10 彩铅绘本",
    "s11-korean-painterly": "R11 韩系厚涂",
    "s16-pixar3d": "R16 3D 动画",
    "s17-shoujo-manga": "R17 少女漫画",
    "s6-paper-collage": "R06 撕纸拼贴",
    "s7-anime-night": "R07 新海诚夜景",
    "s8-jp-film": "R08 日系胶片",
}


def sources():
    if not os.path.isdir(SRC):
        return []
    files = [f for f in sorted(os.listdir(SRC)) if f.lower().endswith((".jpg", ".jpeg", ".png", ".webp"))]
    return files


STYLE_ORDER = [
    "s1-anime-cel", "s2-ghibli", "s3-crayon", "s4-clay", "s5-watercolor",
    "s9-felt", "s10-colored-pencil", "s11-korean-painterly",
    "s16-pixar3d", "s17-shoujo-manga",
    "s6-paper-collage", "s7-anime-night", "s8-jp-film",
]


def styles():
    if not os.path.isdir(OUT):
        return []
    found = [d for d in os.listdir(OUT) if os.path.isdir(os.path.join(OUT, d))]
    return sorted(found, key=lambda d: (STYLE_ORDER.index(d) if d in STYLE_ORDER else 99, d))


def fit(im, size):
    im = im.convert("RGB")
    im.thumbnail((size, size), Image.LANCZOS)
    return im


def main():
    src = sources()
    sty = styles()
    if not src or not sty:
        sys.exit("no sources or no styles found")
    cols, rows = len(src), len(sty) + 1
    w = PAD + cols * (CELL + PAD)
    h = PAD + rows * (CELL + LABEL + PAD)
    sheet = Image.new("RGB", (w, h), BG)
    d = ImageDraw.Draw(sheet)

    for c, name in enumerate(src):
        x = PAD + c * (CELL + PAD)
        im = fit(Image.open(os.path.join(SRC, name)), CELL)
        sheet.paste(im, (x + (CELL - im.width) // 2, PAD + LABEL + (CELL - im.height) // 2))
        d.text((x + 4, PAD + 8), name.rsplit(".", 1)[0], fill=INK)

    for r, sid in enumerate(sty, start=1):
        y = PAD + r * (CELL + LABEL + PAD)
        d.text((PAD + 4, y + 8), STYLE_NAMES.get(sid, sid), fill=INK)
        for c, name in enumerate(src):
            stem = name.rsplit(".", 1)[0]
            hits = [f for f in os.listdir(os.path.join(OUT, sid)) if f.rsplit(".", 1)[0] == stem]
            if not hits:
                continue
            x = PAD + c * (CELL + PAD)
            im = fit(Image.open(os.path.join(OUT, sid, hits[0])), CELL)
            sheet.paste(im, (x + (CELL - im.width) // 2, y + LABEL + (CELL - im.height) // 2))

    out_path = os.path.join(EX, "contact-sheet.jpg")
    sheet.save(out_path, quality=85, optimize=True)
    print("wrote", out_path, sheet.size)

    # ---- preview.html ----
    cards = []
    for sid in sty:
        cells = []
        for name in src:
            stem = name.rsplit(".", 1)[0]
            hits = [f for f in os.listdir(os.path.join(OUT, sid)) if f.rsplit(".", 1)[0] == stem]
            if not hits:
                continue
            cells.append(
                f'<figure><img src="out/{sid}/{html.escape(hits[0])}" loading="lazy">'
                f'<figcaption>{html.escape(stem)}</figcaption></figure>'
            )
        if cells:
            cards.append(
                f'<section><h2>{html.escape(STYLE_NAMES.get(sid, sid))}</h2>'
                f'<div class="row">{"".join(cells)}</div></section>'
            )
    page = f"""<!doctype html><meta charset="utf-8">
<title>photo-style 测试预览</title>
<style>
body{{background:#F5F1E8;color:#3B2314;font:15px/1.5 -apple-system,"PingFang SC",sans-serif;margin:0;padding:32px}}
h1{{font-size:22px;margin:0 0 4px}} .sub{{opacity:.6;margin:0 0 28px}}
section{{margin:0 0 36px}} h2{{font-size:16px;margin:0 0 10px;font-weight:600}}
.row{{display:flex;gap:14px;flex-wrap:wrap;align-items:flex-start}}
figure{{margin:0;background:#fff;border-radius:12px;padding:8px;box-shadow:0 1px 4px rgba(0,0,0,.07)}}
img{{display:block;max-height:420px;max-width:100%;height:auto;border-radius:8px}}
figcaption{{font-size:12px;opacity:.55;margin-top:6px;text-align:center}}
</style>
<h1>photo-style · 照片转风格测试</h1>
<p class="sub">原图见 sources/；每行一种画风，图片顺序与 sources/ 一致。</p>
{"".join(cards)}
"""
    p = os.path.join(EX, "preview.html")
    with open(p, "w", encoding="utf-8") as f:
        f.write(page)
    print("wrote", p)


if __name__ == "__main__":
    main()
