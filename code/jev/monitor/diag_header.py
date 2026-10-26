# -*- coding: utf-8 -*-
"""Diagnose the header/title of the WeChat window: window titles + top-strip OCR."""
from __future__ import annotations

import ctypes
import os
import sys
import time
from ctypes import wintypes

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, os.path.join(ROOT, "app"))
sys.path.insert(0, HERE)

import recorder  # noqa: E402

u32 = ctypes.windll.user32


def titles():
    out = []
    k32 = ctypes.windll.kernel32

    def exe_of(pid):
        h = k32.OpenProcess(0x1000, False, pid)
        if not h:
            return ""
        buf, size = ctypes.create_unicode_buffer(1024), ctypes.c_uint(1024)
        ok = k32.QueryFullProcessImageNameW(h, 0, buf, ctypes.byref(size))
        k32.CloseHandle(h)
        return os.path.basename(buf.value).lower() if ok else ""

    @ctypes.WINFUNCTYPE(ctypes.c_bool, ctypes.c_void_p, ctypes.c_void_p)
    def cb(hwnd, _):
        if not u32.IsWindowVisible(hwnd):
            return True
        pid = ctypes.c_ulong()
        u32.GetWindowThreadProcessId(hwnd, ctypes.byref(pid))
        exe = exe_of(pid.value)
        if exe in ("weixin.exe", "wechat.exe", "qq.exe"):
            t = ctypes.create_unicode_buffer(256)
            u32.GetWindowTextW(hwnd, t, 256)
            r = wintypes.RECT()
            u32.GetWindowRect(hwnd, ctypes.byref(r))
            out.append((exe, hwnd, t.value, r.right - r.left, r.bottom - r.top))
        return True

    u32.EnumWindows(cb, 0)
    return out


def main() -> int:
    for exe, hwnd, title, w, h in titles():
        print("WINDOW exe=%s hwnd=%s size=%dx%d title=%r" % (exe, hwnd, w, h, title))

    recorder.add_qq_support()
    from app import capture as cap_mod
    from app.ocr import _engine, read_title

    hwnd, app = cap_mod.find_chat_hwnd()
    print("picked=%s hwnd=%s" % (app.key, hwnd))
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
    area = cap_mod.chat_area(frame)
    print("area_full=", area)
    if not area:
        return 2
    x0, y0, x1, y1, bg, y_pane = area
    print("x0=%s y_top=%s x1=%s y_in=%s pane_top=%s" % (x0, y0, x1, y1, y_pane))

    eng = _engine(app)
    for label, crop in (
        ("pane_top-64..top", frame[max(0, y_pane - 64):y0, x0:x1]),
        ("top-40..top+40", frame[max(0, y0 - 40):y0 + 40, x0:x1]),
        ("0..120", frame[0:120, x0:x1]),
        ("read_title_input", frame[y_pane:y0, x0:x1]),
    ):
        try:
            res, _ = eng(crop, use_cls=False)
        except Exception as exc:
            print("%-20s ERROR %s" % (label, exc))
            continue
        txt = " | ".join(r[1] for r in (res or []))
        print("%-20s shape=%s ocr=%r" % (label, crop.shape, txt))
    try:
        print("read_title=", repr(read_title(frame[y_pane:y0, x0:x1], app)))
    except Exception as exc:
        print("read_title error", exc)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
