from PIL import Image, ImageDraw
pairs = "ABCDE"
cols = ["1 ORIGINAL PHOTO", "2 ARTIST DRAWING = TARGET",
        "3 V1 COPY OF COL.2", "4 V2 FROM COL.1 ONLY"]
W, H, LAB = 380, 400, 26
cw = W + 16
c = Image.new("RGB", (cw*4+16, (H+LAB)*5+16), (255, 255, 255))
d = ImageDraw.Draw(c)
for j, t in enumerate(cols):
    d.text((16+j*cw, 6), t, fill=(0, 0, 0))
for i, p in enumerate(pairs):
    row = [f"references/originals/original-{p}.jpg",
           f"references/artworks/clean/artwork-{p}.jpg",
           f"examples/out-v10/{i*2+1:02d} {p} 复刻① 照第二列.jpg",
           f"tests/v11/x2-{p}.jpg"]
    for j, f in enumerate(row):
        x = 16+j*cw; y = 16+(H+LAB)*i+LAB
        im = Image.open(f).convert("RGB")
        im.thumbnail((W, H-6), Image.LANCZOS)
        c.paste(im, (x+(W-im.width)//2, y+(H-6-im.height)//2))
c.save("tests/v11/deliverable-v11.jpg", quality=92)
print(c.size)
