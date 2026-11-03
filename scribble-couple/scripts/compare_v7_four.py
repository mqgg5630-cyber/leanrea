from PIL import Image, ImageDraw, ImageFont

CEL_W, CEL_H = 400, 440
HEAD = 54
GAP = 12
PAD = 18
COLS = ["ORIGINAL PHOTO", "ARTIST ORIGINAL  =  TARGET", "REPRODUCTION V1  WAX", "REPRODUCTION V2  PENCIL"]
rows = [
    ("references/originals/original-A.jpg", "references/artworks/clean/artwork-A.jpg",
     "examples/out-v7/01-A-v1.jpg", "examples/out-v7/02-A-v2.jpg"),
    ("references/originals/original-B.jpg", "references/artworks/clean/artwork-B.jpg",
     "examples/out-v7/03-B-v1.jpg", "examples/out-v7/04-B-v2.jpg"),
    ("references/originals/original-C.jpg", "references/artworks/clean/artwork-C.jpg",
     "examples/out-v7/05-C-v1.jpg", "examples/out-v7/06-C-v2.jpg"),
    ("references/originals/original-D.jpg", "references/artworks/clean/artwork-D.jpg",
     "examples/out-v7/07-D-v1.jpg", "examples/out-v7/08-D-v2.jpg"),
    ("references/originals/original-E.jpg", "references/artworks/clean/artwork-E.jpg",
     "examples/out-v7/09-E-v1.jpg", "examples/out-v7/10-E-v2.jpg"),
]
W = PAD * 2 + CEL_W * 4 + GAP * 3
H = PAD * 2 + HEAD + (CEL_H + GAP) * len(rows)
sheet = Image.new("RGB", (W, H), "white")
d = ImageDraw.Draw(sheet)
font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 20)

for i, label in enumerate(COLS):
    x = PAD + i * (CEL_W + GAP)
    color = (200, 40, 40) if i == 1 else (40, 40, 40)
    d.text((x + 6, PAD + 12), label, font=font, fill=color)

def fit(img, w, h):
    r = min(w / img.width, h / img.height)
    return img.resize((max(1, int(img.width * r)), max(1, int(img.height * r))), Image.LANCZOS)

for r, paths in enumerate(rows):
    y = PAD + HEAD + r * (CEL_H + GAP)
    for c, p in enumerate(paths):
        x = PAD + c * (CEL_W + GAP)
        im = fit(Image.open(p).convert("RGB"), CEL_W - 8, CEL_H - 8)
        sheet.paste(im, (x + (CEL_W - im.width) // 2, y + (CEL_H - im.height) // 2))
        d.rectangle([x, y, x + CEL_W, y + CEL_H], outline=(215, 215, 215), width=1)
        if c == 1:
            d.rectangle([x - 1, y - 1, x + CEL_W + 1, y + CEL_H + 1], outline=(200, 40, 40), width=3)
        if c == 2:
            d.rectangle([x - 1, y - 1, x + CEL_W + 1, y + CEL_H + 1], outline=(40, 70, 160), width=3)

sheet.save("examples/compare-v7-four-columns.jpg", quality=91)
print(sheet.size)
