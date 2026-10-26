# -*- coding: utf-8 -*-
"""Read-only UI check for the JevChat deployment.

Finds the chat window (WeChat 4.x, legacy WeChat, QQ or KakaoTalk), grabs one
settled frame through Windows Graphics Capture, locates the message pane and OCRs
the header + visible lines. Nothing is written to disk except this stdout: the
frame stays in memory (upstream rule: screenshots are never persisted).

Run with the deployment venv:
    venv\\Scripts\\python.exe monitor\\verify_ui.py
"""
from __future__ import annotations

import os
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
APP = os.path.join(ROOT, "app")
sys.path.insert(0, APP)
sys.path.insert(0, HERE)


def line(key, value):
    print("%s=%s" % (key, value))


def main() -> int:
    try:
        import numpy as np  # noqa: F401
    except Exception as exc:  # pragma: no cover
        line("IMPORT_NUMPY", "fail: %s" % exc)
        return 3

    # QQ support lives in the recorder hook; installing it is enough here.
    try:
        import recorder
        recorder.add_qq_support()
    except Exception as exc:
        line("RECORDER", "fail: %s" % exc)

    try:
        from app import capture as cap_mod
        from app import chatapps
        from app.ocr import Reader, read_title, similar
    except Exception as exc:
        line("IMPORT_APP", "fail: %s" % exc)
        return 3

    line("APPS", ",".join(sorted(chatapps.APPS.keys())))

    try:
        hwnd, app = cap_mod.find_chat_hwnd()
    except Exception as exc:
        line("FIND_WINDOW", "fail: %s" % exc)
        return 2
    line("FIND_WINDOW", "ok")
    line("APP_KEY", app.key)
    line("HWND", hwnd)

    try:
        cap = cap_mod.Capture(hwnd)
    except Exception as exc:
        line("CAPTURE", "fail: %s" % exc)
        return 2
    frame = None
    deadline = time.time() + 12
    try:
        while time.time() < deadline:
            frame = cap.settled()
            if frame is not None:
                break
            time.sleep(0.1)
    finally:
        try:
            cap.stop()
        except Exception:
            pass
    if frame is None:
        line("CAPTURE", "fail: no settled frame in 12s (window hidden/minimized?)")
        return 2
    line("FRAME", "%dx%d" % (frame.shape[1], frame.shape[0]))

    area = cap_mod.chat_area(frame)
    line("CHAT_AREA", area[:4] if area else "None")
    if not area:
        line("VERDICT", "no message pane found - layout not recognised")
        return 2
    x0, y0, x1, y1, bg, y_pane = area
    line("PANE_BG", tuple(int(v) for v in bg))

    header = frame[y_pane:y0, x0:x1]
    title = ""
    try:
        title = read_title(header, app)
    except Exception as exc:
        line("TITLE_ERROR", exc)
    line("TITLE", title)

    try:
        reader = Reader(app)
        lines = reader.read(frame[y0:y1, x0:x1], bg)
    except Exception as exc:
        line("OCR", "fail: %s" % exc)
        return 2
    line("OCR_LINES", len(lines))
    for who, name, text, _bgc in lines[-8:]:
        line("LINE", "%s|%s|%s" % (who, name or "-", text))

    line("VERDICT", "ok")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
