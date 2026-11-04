from PIL import Image, ImageDraw
import sys
pairs = "ABCDE"
cols = ["1 ORIGINAL PHOTO", "2 ARTIST DRAWING = TARGET",
        "3 V1 COPY OF COL.2", "4 V2 PHOTO + COL.2"]
W, H, LAB = 380, 400, 26
cw = W + 16
canvas = Image.new("RGB", (cw*4+16, (H+LAB)*5+16), (255, 255, 255))
d = ImageDraw.Draw(canvas)
for j, t in enumerate(cols):
    d.text((16+j*cw, 6), t, fill=(0, 0, 0))
for i, p in enumerate(pairs):
    row = [f"references/originals/original-{p}.jpg",
           f"references/artworks/clean/artwork-{p}.jpg",
           f"tests/v10/p1-{p}.jpg",
           f"tests/v10/u-{p}.jpg"]
    for j, f in enumerate(row):
        x = 16+j*cw; y = 16+(H+LAB)*i+LAB
        im = Image.open(f).convert("RGB")
        im.thumbnail((W, H-6), Image.LANCZOS)
        canvas.paste(im, (x+(W-im.width)//2, y+(H-6-im.height)//2))
canvas.save("tests/v10/deliverable-10.jpg", quality=92)
print(canvas.size)
