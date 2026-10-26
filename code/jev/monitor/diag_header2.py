# -*- coding: utf-8 -*-
"""Second pass: where exactly is the conversation name? Prints every OCR box."""
from __future__ import annotations

import os
import sys
import time

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, os.path.join(ROOT, "app"))
sys.path.insert(0, HERE)

import recorder  # noqa: E402


def dump(eng, label, crop):
    res, _ = eng(crop, use_cls=False)
    print("== %s shape=%s" % (label, crop.shape))
    for box, text, score in (res or []):
        xs = [p[0] for p in box]
        ys = [p[1] for p in box]
        print("   box=(%4d,%4d)-(%4d,%4d) score=%.2f text=%r" % (
            min(xs), min(ys), max(xs), max(ys), score, text))


def upscale(img, k=2):
    return np.repeat(np.repeat(img, k, axis=0), k, axis=1)


def main() -> int:
    recorder.add_qq_support()
    from app import capture as cap_mod
    from app.ocr import _engine

    hwnd, app = cap_mod.find_chat_hwnd()
    cap = cap_mod.Capture(hwnd)
    frame = None
    deadline = time.time() + 12
    while time.time() < deadline:
        frame = cap.settled()
        if frame is not None:
            break
        time.sleep(0.1)
    cap.stop()
    if frame is None:
        print("no frame")
        return 2
    eng = _engine(app)
    area = cap_mod.chat_area(frame)
    x0, y0, x1, y1, bg, y_pane = area
    print("frame=%s area=(%s,%s,%s,%s) pane_top=%s" % (frame.shape, x0, y0, x1, y1, y_pane))

    dump(eng, "full top 0..260 (pane)", frame[0:260, x0:x1])
    dump(eng, "top 0..260 upscaled x2", upscale(frame[0:260, x0:x1], 2))
    dump(eng, "left 60% of top 0..140", frame[0:140, x0:x0 + int((x1 - x0) * 0.6)])
    dump(eng, "left list 0..140 (x 0..x0)", frame[0:140, 0:x0])
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
