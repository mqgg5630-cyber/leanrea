# -*- coding: utf-8 -*-
"""Diagnose the PySide6 'DLL load failed while importing QtCore' failure.

Prints facts only; nothing is written to disk.
"""
from __future__ import annotations

import glob
import os
import sys
import traceback

print("python=", sys.version.split()[0], sys.executable)

try:
    import PySide6
    print("pyside_version=", PySide6.__version__)
    print("pyside_dir=", os.path.dirname(PySide6.__file__))
except Exception:
    print("pyside_import_failed")
    print(traceback.format_exc())
    raise SystemExit(1)

pkg = os.path.dirname(PySide6.__file__)
for name in ("Qt6Core.dll", "Qt6Gui.dll", "Qt6Widgets.dll", "pyside6.abi3.dll",
             "MSVCP140.dll", "VCRUNTIME140.dll", "VCRUNTIME140_1.dll", "CONCRT140.dll"):
    print("pkg_has_%s=" % name, os.path.exists(os.path.join(pkg, name)))

for dll in ("vcruntime140.dll", "vcruntime140_1.dll", "msvcp140.dll",
            "msvcp140_1.dll", "msvcp140_2.dll", "concrt140.dll"):
    print("sys32_%s=" % dll, os.path.exists(os.path.join(os.environ.get("SystemRoot", r"C:\Windows"), "System32", dll)))

try:
    from PySide6 import QtCore
    print("QtCore_OK=", QtCore.__version__)
except Exception:
    print("QtCore_IMPORT_FAILED")
    print(traceback.format_exc())

dlls = sorted(os.path.basename(p) for p in glob.glob(os.path.join(pkg, "*.dll")))
print("dll_count=", len(dlls))
print("dll_sample=", ", ".join(dlls[:12]))
print("plugins_dir=", os.path.isdir(os.path.join(pkg, "plugins")))
