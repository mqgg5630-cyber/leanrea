"""Measure ink/blackness metrics of artworks vs our reproductions.

For each image:
  - black_ratio   : fraction of pixels with gray < 90  (solid ink)
  - dark_ratio    : fraction with gray < 170 (any drawn mark)
  - stroke_px     : median stroke width of the dark mask, in pixels
  - stroke_rel    : stroke_px / image width  (normalised, comparable across sizes)
  - contrast_std  : std of gray values (how "high contrast" the sheet is)
"""
import sys, glob
import numpy as np
from PIL import Image
from scipy import ndimage


def metrics(path):
    im = Image.open(path).convert("L")
    a = np.asarray(im, dtype=np.uint8)
    h, w = a.shape
    black = a < 90
    dark = a < 170
    if dark.sum() == 0:
        return None
    # distance transform inside the dark mask -> half stroke width
    dt = ndimage.distance_transform_edt(dark)
    vals = dt[dark]
    stroke = 2.0 * np.median(vals)
    return dict(path=path, w=w, h=h,
                black=black.mean() * 100,
                dark=dark.mean() * 100,
                stroke_px=stroke,
                stroke_rel=stroke / w,
                std=float(a.std()))


if __name__ == "__main__":
    paths = sys.argv[1:]
    print(f"{'file':52s} {'W':>5s} {'black%':>7s} {'dark%':>6s} {'strk':>5s} {'strk/W':>7s} {'std':>5s}")
    for p in paths:
        m = metrics(p)
        if not m:
            continue
        name = p.split("/")[-1][:50]
        print(f"{name:52s} {m['w']:5d} {m['black']:7.1f} {m['dark']:6.1f} "
              f"{m['stroke_px']:5.1f} {m['stroke_rel']:7.4f} {m['std']:5.1f}")
