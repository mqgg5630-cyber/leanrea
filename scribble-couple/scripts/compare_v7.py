from PIL import Image, ImageDraw, ImageFont
import os

CEL_W, CEL_H = 360, 400
HEAD = 54
GAP = 10
PAD = 16
COLS = [
    ("ORIGINAL PHOTO", None),
    ("ARTIST ORIGINAL  =  TARGET", None),
    ("PREVIOUS RENDER", None),
    ("NEW V1  REPRODUCTION", None),
    ("NEW V2  REPRODUCTION", None),
]
rows = [
    ("A", "references/originals/original-A.jpg", "references/artworks/clean/artwork-A.jpg",
     "examples/out-v3/01-A-halfbody.jpg", "examples/out-v7/01-A-v1.jpg", "examples/out-v7/02-A-v2.jpg"),
    ("B", "references/originals/original-B.jpg", "references/artworks/clean/artwork-B.jpg",
     "examples/out-v3/04-B-halfbody.jpg", "examples/out-v7/03-B-v1.jpg", "examples/out-v7/04-B-v2.jpg"),
    ("C", "references/originals/original-C.jpg", "references/artworks/clean/artwork-C.jpg",
     "examples/out-v3/07-C-halfbody.jpg", "examples/out-v7/05-C-v1.jpg", "examples/out-v7/06-C-v2.jpg"),
    ("D", "references/originals/original-D.jpg", "references/artworks/clean/artwork-D.jpg",
     "examples/out-v2/01-style-v2.jpg", "examples/out-v7/07-D-v1.jpg", "examples/out-v7/08-D-v2.jpg"),
    ("E", "references/originals/original-E.jpg", "references/artworks/clean/artwork-E.jpg",
     "examples/out-v4/08-E-heavy.jpg", "examples/out-v7/09-E-v1.jpg", "examples/out-v7/10-E-v2.jpg"),
]

W = PAD * 2 + CEL_W * 5 + GAP * 4
H = PAD * 2 + HEAD + (CEL_H + GAP) * 5
sheet = Image.new("RGB", (W, H), "white")
d = ImageDraw.Draw(sheet)
try:
    font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 19)
    fsmall = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 15)
except Exception:
    font = fsmall = ImageFont.load_default()

for i, (label, _) in enumerate(COLS):
    x = PAD + i * (CEL_W + GAP)
    color = (40, 40, 40)
    if i == 1:
        color = (200, 40, 40)
    if i == 2:
        color = (40, 70, 160)
    d.text((x + 6, PAD + 12), label, font=font, fill=color)

def fit(img, w, h):
    r = min(w / img.width, h / img.height)
    return img.resize((max(1, int(img.width * r)), max(1, int(img.height * r))), Image.LANCZOS)

for r, (tag, *paths) in enumerate(rows):
    y = PAD + HEAD + r * (CEL_H + GAP)
    for c, p in enumerate(paths):
        x = PAD + c * (CEL_W + GAP)
        im = Image.open(p).convert("RGB")
        im = fit(im, CEL_W - 8, CEL_H - 8)
        ox = x + (CEL_W - im.width) // 2
        oy = y + (CEL_H - im.height) // 2
        sheet.paste(im, (ox, oy))
        d.rectangle([x, y, x + CEL_W, y + CEL_H], outline=(215, 215, 215), width=1)
        if c == 2:
            d.rectangle([x - 1, y - 1, x + CEL_W + 1, y + CEL_H + 1], outline=(40, 70, 160), width=4)

sheet.save("examples/compare-v7-five-columns.jpg", quality=91)
print(sheet.size)
