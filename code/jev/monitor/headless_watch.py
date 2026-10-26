# -*- coding: utf-8 -*-
"""Headless chat watcher: same capture + OCR as the JevChat GUI, no Qt.

Why this exists: on this machine PySide6's Qt6Core.dll refuses to load
(WinError 127 - a Windows API symbol the GUI needs is missing), while numpy,
rapidocr and windows-capture all work. The recorder only needs the capture/OCR
half of the upstream project, so this loop reuses app/capture.py + app/ocr.py
verbatim and keeps the Qt overlay out of the picture.

What it does, forever:
  find the chat window (WeChat / legacy WeChat / QQ / KakaoTalk)
  -> Windows Graphics Capture, in memory only
  -> locate the message pane -> OCR header (conversation name) + bubbles
  -> de-duplicate -> append every new line to logs/events.jsonl + digest-<day>.md

Nothing is sent anywhere. Run with pythonw so no console window appears.
"""
from __future__ import annotations

import os
import sys
import time
import traceback
from datetime import datetime

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
APP = os.path.join(ROOT, "app")
sys.path.insert(0, APP)
sys.path.insert(0, HERE)

import recorder  # noqa: E402

LOGS = os.path.join(ROOT, "logs")
LOG = os.path.join(LOGS, "watcher.log")
PIDFILE = os.path.join(LOGS, "watcher.pid")

FRAME_SLEEP = 0.05
NO_WINDOW_SLEEP = 5.0
HEARTBEAT_S = 60.0


def log(msg: str) -> None:
    line = "[%s] watcher: %s" % (datetime.now().strftime("%Y-%m-%d %H:%M:%S"), msg)
    try:
        os.makedirs(LOGS, exist_ok=True)
        with open(LOG, "a", encoding="utf-8") as f:
            f.write(line + "\n")
    except OSError:
        pass


_MUTEX = None


def acquire_single_instance() -> bool:
    """Named mutex beats a pid file: two watchers started at the same moment both
    read an empty pid file and both proceed."""
    global _MUTEX
    try:
        import ctypes
        from ctypes import wintypes
        k32 = ctypes.windll.kernel32
        k32.CreateMutexW.restype = wintypes.HANDLE
        _MUTEX = k32.CreateMutexW(None, True, "Global\\jev-chat-headless-watcher")
        already = k32.GetLastError() == 183  # ERROR_ALREADY_EXISTS
        return not already
    except Exception:
        return True  # never block the watcher on a guard failure


def already_running() -> bool:
    """One watcher per machine: two of them would double-record every message."""
    try:
        with open(PIDFILE, encoding="utf-8") as f:
            pid = int(f.read().strip() or 0)
    except (OSError, ValueError):
        return False
    if pid <= 0 or pid == os.getpid():
        return False
    try:
        import ctypes
        k32 = ctypes.windll.kernel32
        h = k32.OpenProcess(0x1000, False, pid)
        if not h:
            return False
        code = ctypes.c_ulong()
        ok = k32.GetExitCodeProcess(h, ctypes.byref(code))
        k32.CloseHandle(h)
        return bool(ok) and code.value == 259  # STILL_ACTIVE
    except Exception:
        return False


def write_pid() -> None:
    try:
        os.makedirs(LOGS, exist_ok=True)
        with open(PIDFILE, "w", encoding="utf-8") as f:
            f.write(str(os.getpid()))
    except OSError:
        pass


def main() -> int:
    if not acquire_single_instance():
        log("another watcher holds the mutex - exiting")
        return 0
    if already_running():
        log("another watcher is alive - exiting")
        return 0
    write_pid()
    recorder.install(ROOT)
    recorder.add_qq_support()

    from app import capture as cap_mod
    from app.ocr import Reader, read_title, similar

    log("started pid=%d python=%s" % (os.getpid(), sys.version.split()[0]))
    recorder.record("watcher_start", pid=os.getpid(), python=sys.version.split()[0])

    readers: dict = {}
    title = ""
    no_window_logged = ""
    frames = 0
    messages = 0
    last_beat = time.time()

    while True:
        try:
            hwnd, app = cap_mod.find_chat_hwnd()
        except Exception as exc:
            msg = " ".join(str(exc).split())[:160]
            if msg != no_window_logged:
                log("no chat window: " + msg)
                recorder.record("no_window", detail=msg)
                no_window_logged = msg
            time.sleep(NO_WINDOW_SLEEP)
            continue
        no_window_logged = ""

        try:
            cap = cap_mod.Capture(hwnd)
        except Exception as exc:
            log("capture failed: " + " ".join(str(exc).split())[:200])
            recorder.record("capture_error", detail=" ".join(str(exc).split())[:200])
            time.sleep(NO_WINDOW_SLEEP)
            continue

        log("capturing app=%s hwnd=%s" % (app.key, hwnd))
        recorder.record("capture_start", app=app.key, hwnd=hwnd)
        warn_area = False

        try:
            while cap.alive():
                full = cap.settled()
                if full is None:
                    time.sleep(FRAME_SLEEP)
                    continue
                area = cap_mod.chat_area(full)
                if area is None:
                    if not warn_area:
                        log("message pane not recognised (window too small?)")
                        recorder.record("pane_error", detail="chat_area returned None")
                        warn_area = True
                    continue
                warn_area = False
                x0, y0, x1, y1, bg, y_pane = area

                header = full[y_pane:y0, x0:x1]
                try:
                    name = read_title(header, app)
                except Exception:
                    name = ""
                if name:
                    name = next((k for k in readers if similar(k, name)), name)
                name = name or title or "current chat"
                if name != title:
                    title = name
                    log("conversation: " + title)
                    recorder.record("chat_switch", chat=title)
                    recorder.digest("\n### 会话：%s（%s）\n" % (title, datetime.now().strftime("%H:%M")))

                reader = readers.setdefault(title, Reader(app))
                try:
                    lines = reader.read(full[y0:y1, x0:x1], bg)
                except Exception:
                    log("ocr failed: " + " ".join(traceback.format_exc().split())[-200:])
                    time.sleep(1.0)
                    continue

                for who, gname, text in reader.new_lines(lines):
                    messages += 1
                    clock = datetime.now().strftime("%H:%M")
                    recorder.record_message(title, who, gname, text, clock)
                    log("msg [%s] %s%s: %s" % (title, (gname + " ") if gname else "", who, text[:60]))

                frames += 1
                if time.time() - last_beat >= HEARTBEAT_S:
                    last_beat = time.time()
                    recorder.record("heartbeat", frames=frames, messages=messages, chat=title)
        except Exception:
            log("loop error: " + " ".join(traceback.format_exc().split())[-200:])
        finally:
            try:
                cap.stop()
            except Exception:
                pass
        log("capture ended (window closed?) - re-scanning")
        time.sleep(3.0)


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except KeyboardInterrupt:
        raise SystemExit(0)
