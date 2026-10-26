# -*- coding: utf-8 -*-
"""Which DLL actually refuses to load? Loads Qt's own DLLs directly with ctypes."""
from __future__ import annotations

import ctypes
import os
import traceback

pkg = r"E:\0apps\jev-chat-windows\venv\Lib\site-packages\PySide6"

targets = ["Qt6Core.dll", "pyside6.abi3.dll", "QtCore.pyd", "Qt6Gui.dll"]
for name in targets:
    path = os.path.join(pkg, name)
    if not os.path.exists(path):
        print("%-18s MISSING" % name)
        continue
    try:
        ctypes.WinDLL(path)
        print("%-18s LOAD_OK" % name)
    except OSError as exc:
        print("%-18s FAIL winerr=%s :: %s" % (name, getattr(exc, "winerror", "?"), exc))
    except Exception:
        print("%-18s FAIL other :: %s" % (name, " ".join(traceback.format_exc().split())[-160:]))

# also try the CRT that ships next to Qt
for name in ("msvcp140.dll", "vcruntime140.dll", "vcruntime140_1.dll"):
    path = os.path.join(pkg, name)
    try:
        ctypes.WinDLL(path)
        print("%-18s LOAD_OK (bundled)" % name)
    except Exception as exc:
        print("%-18s FAIL (bundled) :: %s" % (name, exc))
