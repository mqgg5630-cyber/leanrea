# -*- coding: utf-8 -*-
"""jev-monitor recorder: capture every new chat line the JevChat app sees.

Nothing here talks to the network. It only appends JSON lines to a local file so
the leanrea agent (via git) can read the conversation later, and writes a daily
Markdown digest a human can skim.

Hook points (patched by install(), never editing upstream logic):
  * app.overlay.Overlay.log_message  -> every new incoming/outgoing line
  * core.engine.analyze              -> the Jev judgement + the 3 candidates

Files (root = the deployment folder, e.g. E:\\0github\\apps\\jev-chat-windows):
  logs/events.jsonl              append-only machine log
  logs/digest-YYYY-MM-DD.md      human digest, one file per day
  logs/monitor.log               hook install / errors
"""
from __future__ import annotations

import json
import os
import sys
import threading
import time
import traceback
from datetime import datetime

_LOCK = threading.Lock()
_ROOT = ""
_LOG_DIR = ""
_ORIG_ANALYZE = None

MAX_EVENTS_BYTES = 8 * 1024 * 1024   # rotate at 8 MB, keep one .1 backup
MAX_TEXT = 4000                      # one long pasted message must not bloat the log


def _now() -> str:
    return datetime.now().strftime("%Y-%m-%d %H:%M:%S")


def _root() -> str:
    global _ROOT
    if _ROOT:
        return _ROOT
    env = os.environ.get("JEV_MONITOR_ROOT")
    if env:
        _ROOT = env
    else:
        _ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    return _ROOT


def _logs() -> str:
    global _LOG_DIR
    if not _LOG_DIR:
        _LOG_DIR = os.path.join(_root(), "logs")
    return _LOG_DIR


def _ensure_dir(path: str) -> None:
    try:
        os.makedirs(path, exist_ok=True)
    except OSError:
        pass


def _note(msg: str) -> None:
    """Boot / error notes: they must never raise inside the app."""
    try:
        _ensure_dir(_logs())
        with open(os.path.join(_logs(), "monitor.log"), "a", encoding="utf-8") as f:
            f.write("[%s] %s\n" % (_now(), msg))
    except OSError:
        pass


def _rotate() -> None:
    path = os.path.join(_logs(), "events.jsonl")
    try:
        if os.path.getsize(path) > MAX_EVENTS_BYTES:
            backup = path + ".1"
            if os.path.exists(backup):
                os.remove(backup)
            os.replace(path, backup)
    except OSError:
        pass


def record(kind: str, **fields) -> None:
    """Append one JSON line + return nothing. Never raises."""
    rec = {"t": _now(), "ts": round(time.time(), 3), "kind": kind}
    rec.update(fields)
    with _LOCK:
        try:
            _ensure_dir(_logs())
            _rotate()
            with open(os.path.join(_logs(), "events.jsonl"), "a", encoding="utf-8") as f:
                f.write(json.dumps(rec, ensure_ascii=False) + "\n")
        except (OSError, TypeError, ValueError):
            try:
                _note("record failed: " + " ".join(traceback.format_exc().split())[-300:])
            except Exception:
                pass


def _digest_path() -> str:
    return os.path.join(_logs(), "digest-%s.md" % datetime.now().strftime("%Y-%m-%d"))


def digest(line: str) -> None:
    with _LOCK:
        try:
            _ensure_dir(_logs())
            path = _digest_path()
            new = not os.path.exists(path)
            with open(path, "a", encoding="utf-8") as f:
                if new:
                    f.write("# JevChat 聊天记录摘要 %s\n\n" % datetime.now().strftime("%Y-%m-%d"))
                f.write(line.rstrip("\n") + "\n")
        except OSError:
            pass


def _short(text, limit: int = MAX_TEXT) -> str:
    s = "" if text is None else str(text)
    return s if len(s) <= limit else s[:limit] + " ...[truncated]"


# --------------------------------------------------------------------------- hooks
def _on_message(who, text, name="", timestamp=None, chat=None) -> None:
    try:
        record("msg", chat=chat or "", who=who or "", name=name or "",
               text=_short(text), clock=timestamp or "")
        who_cn = {"her": "对方", "me": "我"}.get(who, who or "?")
        speaker = (name + " ") if name else ""
        digest("- %s %s%s：%s" % (timestamp or datetime.now().strftime("%H:%M"),
                                  speaker, who_cn, _short(text, 300)))
    except Exception:
        _note("message hook failed: " + " ".join(traceback.format_exc().split())[-300:])


def record_message(chat, who, name, text, clock=None) -> None:
    """Public entry for callers that are not the GUI (headless watcher)."""
    _on_message(who, text, name or "", clock, chat or "")


def _compact_answers(answers) -> dict:
    """Jev answers -> {question: value/confidence} so the JSONL stays readable."""
    out = {}
    if not isinstance(answers, dict):
        return out
    for key, val in answers.items():
        if not isinstance(val, dict):
            out[key] = val
            continue
        pick = {}
        for k in ("type", "choice", "score", "noul", "confidence"):
            if k in val:
                pick[k] = val[k]
        out[key] = pick
    return out


def _on_analyze(*args, **kwargs):
    result = _ORIG_ANALYZE(*args, **kwargs)
    try:
        messages = args[0] if args else kwargs.get("messages") or []
        relationship = args[1] if len(args) > 1 else kwargs.get("relationship", "")
        flat = []
        for m in (messages or []):
            try:
                flat.append({"who": m[0], "text": _short(m[1], 500),
                             "name": (m[2] if len(m) > 2 else "")})
            except (IndexError, TypeError):
                continue
        record("analysis",
               relationship=relationship,
               messages=flat,
               candidates=[_short(c) for c in (result.get("candidates") or [])],
               best_index=result.get("best_index"),
               best_reply=_short(result.get("best_reply")),
               scores=result.get("scores"),
               answers=_compact_answers(result.get("answers")),
               usage=result.get("usage"))
        cands = result.get("candidates") or []
        best = result.get("best_index") or 0
        extra = []
        for i, c in enumerate(cands):
            extra.append("  - %s%s" % ("★" if i == best else " ", _short(c, 200)))
        digest("\n**分析 %s**\n%s\n" % (datetime.now().strftime("%H:%M"), "\n".join(extra)))
    except Exception:
        _note("analysis hook failed: " + " ".join(traceback.format_exc().split())[-300:])
    return result


# --------------------------------------------------------------------------- QQ
def _qq_me(bg) -> bool:
    """QQ's own bubble is #0099FF: blue clearly above red and green.
    The other side is white, the chat ground is light grey, so both stay clear."""
    try:
        b, g, r = int(bg[2]), int(bg[1]), int(bg[0])
    except (IndexError, TypeError, ValueError):
        return False
    return bool(b > 180 and b > r + 120 and b > g)


def add_qq_support() -> bool:
    """Register QQ (QQ.exe) as a chat app at runtime, so the upstream checkout is
    never edited. Same OCR path as WeChat; only the "my bubble" rule differs.
    Disable with JEV_MONITOR_QQ=0."""
    if os.environ.get("JEV_MONITOR_QQ", "1") == "0":
        return False
    try:
        from app import chatapps
        if "qq" in chatapps.APPS:
            return True
        chatapps.APPS["qq"] = chatapps.ChatApp(
            key="qq", label="QQ", exes=("qq.exe",), main_title="QQ",
            skip_titles=(), ocr="rapidocr", join="", is_me=_qq_me)
        _note("qq profile injected")
        return True
    except Exception:
        _note("qq profile failed: " + " ".join(traceback.format_exc().split())[-300:])
        return False


def install(root: str | None = None) -> bool:
    """Patch the running app once. Safe to call twice. Returns True when active."""
    global _ROOT, _LOG_DIR, _ORIG_ANALYZE
    if _ORIG_ANALYZE is not None:
        return True
    if root:
        _ROOT = os.path.abspath(root)
        _LOG_DIR = ""
    _ensure_dir(_logs())
    try:
        from app.overlay import Overlay
        if getattr(Overlay.log_message, "_jev_monitor", False) is False:
            orig = Overlay.log_message
            _orig_message = orig

            def log_message(self, who, text, name="", timestamp=None, chat=None):
                _on_message(who, text, name, timestamp, chat)
                return _orig_message(self, who, text, name, timestamp, chat)

            log_message._jev_monitor = True
            log_message.__wrapped__ = orig
            Overlay.log_message = log_message
    except Exception:
        # Headless mode has no Qt at all (PySide6 cannot load on this host), so a
        # failed overlay patch is expected and must not stop the rest.
        _note("overlay patch skipped: " + " ".join(traceback.format_exc().split())[-200:])

    try:
        import core.engine as engine
        if _ORIG_ANALYZE is None:
            _ORIG_ANALYZE = engine.analyze

            def analyze(*args, **kwargs):
                return _on_analyze(*args, **kwargs)

            analyze.__wrapped__ = _ORIG_ANALYZE
            engine.analyze = analyze
        main_mod = sys.modules.get("__main__")
        if main_mod is not None and getattr(main_mod, "analyze", None) is _ORIG_ANALYZE:
            main_mod.analyze = engine.analyze
    except Exception:
        _note("engine patch skipped: " + " ".join(traceback.format_exc().split())[-200:])

    add_qq_support()

    record("app_start", pid=os.getpid(), argv=_short(sys.argv, 300),
           python=sys.version.split()[0])
    digest("\n## 程序启动 %s\n" % _now())
    _note("hooks installed (pid %d)" % os.getpid())
    return True


def summary() -> dict:
    """Small self-description used by the status script."""
    return {"root": _root(), "logs": _logs(), "active": _ORIG_ANALYZE is not None}
