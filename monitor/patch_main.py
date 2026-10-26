# -*- coding: utf-8 -*-
"""Idempotently add the jev-monitor hook to the upstream app/main.py.

The hook block is delimited, so re-running after a `git reset --hard` (or after an
upstream update) replaces the old block instead of stacking another one.

The hook is inserted BEFORE `from core.engine import analyze` so that main.py
binds the recording wrapper, not the original function.
"""
from __future__ import annotations

import io
import os
import sys

BEGIN = "# jev-monitor:hook -- managed by leanrea monitor, do not edit"
END = "# jev-monitor:end"
ANCHOR = "from core.engine import analyze"

BLOCK = """{begin}
try:
    import os as _jm_os, sys as _jm_sys
    _jm_root = _jm_os.path.dirname(_jm_os.path.dirname(_jm_os.path.abspath(__file__)))
    _jm_sys.path.insert(0, _jm_os.path.join(_jm_root, "monitor"))
    import recorder as _jm_recorder
    _jm_recorder.install(_jm_root)
except Exception as _jm_err:  # monitoring must never stop the app from starting
    print("jev-monitor: hook failed:", _jm_err)
{end}
""".format(begin=BEGIN, end=END)


def patch(path: str) -> str:
    with io.open(path, "r", encoding="utf-8") as f:
        text = f.read()

    # drop an old block first (keeps the file stable across re-installs)
    if BEGIN in text and END in text:
        head, rest = text.split(BEGIN, 1)
        _old, tail = rest.split(END, 1)
        text = head + tail.lstrip("\r\n")

    if ANCHOR not in text:
        raise SystemExit("anchor not found in %s: %r" % (path, ANCHOR))

    text = text.replace(ANCHOR, BLOCK + ANCHOR, 1)
    with io.open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)
    return path


def main() -> int:
    root = sys.argv[1] if len(sys.argv) > 1 else os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    target = os.path.join(root, "app", "main.py")
    if not os.path.exists(target):
        print("MISSING:", target)
        return 2
    patch(target)
    with io.open(target, "r", encoding="utf-8") as f:
        ok = BEGIN in f.read()
    print("PATCHED:", target, "hook_present=", ok)
    return 0 if ok else 3


if __name__ == "__main__":
    raise SystemExit(main())
