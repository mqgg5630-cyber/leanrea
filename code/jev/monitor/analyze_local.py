# -*- coding: utf-8 -*-
"""Host-side auto analysis: the upstream JevChat brain without the Qt GUI.

core/engine.py + core/questions.py + core/draft.py + core/jev_client.py are
pure Python (no Qt), so with the two API keys the *machine itself* can produce
"intent judgement + 3 ranked candidate replies" for every new message - exactly
what the overlay would show, just written to a file instead.

Usage
    python monitor/analyze_local.py            # newest burst of messages
    python monitor/analyze_local.py --all      # whole log
    python monitor/analyze_local.py --loop     # poll the log, analyse new bursts

Result (also appended to logs/analysis.jsonl):
    {"t": ..., "chat": ..., "messages": [...], "answers": {...},
     "candidates": [...], "best_index": 0, "scores": [...]}

Without keys it prints a clear "no key" line and exits 0 - recording never
depends on this script.
"""
from __future__ import annotations

import json
import os
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
APP = os.path.join(ROOT, "app")
sys.path.insert(0, APP)
sys.path.insert(0, HERE)

LOGS = os.path.join(ROOT, "logs")
EVENTS = os.path.join(LOGS, "events.jsonl")
OUT = os.path.join(LOGS, "analysis.jsonl")


def load_messages(limit: int = 40) -> list:
    msgs = []
    try:
        with open(EVENTS, encoding="utf-8-sig") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    rec = json.loads(line)
                except ValueError:
                    continue
                if rec.get("kind") != "msg":
                    continue
                who = "her" if rec.get("who") == "her" else "me"
                text = rec.get("text") or ""
                name = rec.get("name") or ""
                msgs.append((who, text, name) if name else (who, text))
    except OSError:
        return []
    return msgs[-limit:]


def analyse(messages: list) -> dict:
    from core.engine import analyze
    from app import settings

    kwargs = dict(
        relationship=settings.relationship(),
        context=settings.context(),
        provider=settings.draft_provider(),
        model=settings.draft_model() or None,
        base_url=settings.draft_base_url() or None,
        style=settings.style(),
        thinking=settings.thinking(),
        jev_provider=settings.jev_provider(),
        jev_model=settings.jev_model() or None,
    )
    return analyze(messages, **kwargs)


def analyse_llm_only(messages: list) -> dict:
    """One key (LLM_API_KEY) only: draft with core.draft, then ask the same model
    to judge intent + pick the best candidate. No Jev call at all."""
    import json as _json

    from app import settings
    from core import draft, llm, providers

    kwargs = dict(relationship=settings.relationship(), context=settings.context(),
                  provider=settings.draft_provider(),
                  model=settings.draft_model() or None,
                  base_url=settings.draft_base_url() or None,
                  style=settings.style(), thinking=settings.thinking())
    cands = draft.draft_candidates(messages, **kwargs)
    if not cands:
        return {"candidates": [], "best_index": 0, "answers": {}, "scores": [],
                "mode": "llm_only"}
    spec = providers.DRAFT_PROVIDERS[kwargs["provider"]]
    transcript = "\n".join(
        ("%s: %s" % ("她" if m[0] == "her" else "我", m[1])) for m in messages[-12:])
    prompt = (
        "下面是一段聊天记录和三句候选回复。用中文回答，只输出 JSON：\n"
        '{"intent":"对方这句话真正的意思，一句话",'
        '"emotion":"对方情绪，一句话",'
        '"risk":"如果照现在这样回，最可能出的问题，一句话",'
        '"best_index":0到2之间的整数}'
        "\n\n对话：\n%s\n\n候选：\n0: %s\n1: %s\n2: %s"
        % (transcript, cands[0], cands[1] if len(cands) > 1 else "",
           cands[2] if len(cands) > 2 else "")
    )
    key = settings.llm_key()
    raw = llm.chat(spec.protocol, kwargs["base_url"] or spec.base, key,
                   kwargs["model"] or spec.default,
                   "你是关系沟通顾问，判断准确、不讨好。", [prompt],
                   temperature=0.3, max_tokens=500, thinking=False,
                   extra_body=spec.extra(False), headers=spec.headers, timeout=60)
    try:
        start = raw.index("{")
        verdict = _json.loads(raw[start:raw.rindex("}") + 1])
    except (ValueError, IndexError):
        verdict = {}
    best = verdict.get("best_index", 0)
    try:
        best = max(0, min(len(cands) - 1, int(best)))
    except (TypeError, ValueError):
        best = 0
    return {"candidates": cands, "best_index": best, "scores": [],
            "answers": verdict, "mode": "llm_only"}


def keys_present() -> bool:
    from app import settings
    return bool(settings.has_jev_key() and settings.has_llm_key())


def run_once(limit: int = 40) -> int:
    from app import settings
    have_llm = settings.has_llm_key()
    have_jev = settings.has_jev_key()
    if not have_llm and not have_jev:
        print("no_key: JEV_API_KEY,LLM_API_KEY - recording continues, analysis skipped")
        return 0
    if not have_llm:
        print("no_key: LLM_API_KEY (drafting) - recording continues, analysis skipped")
        return 0
    msgs = load_messages(limit)
    if not msgs:
        print("no messages yet")
        return 0
    if msgs[-1][0] != "her":
        print("latest message is ours - nothing to answer")
        return 0
    result = analyse(msgs) if have_jev else analyse_llm_only(msgs)
    payload = {
        "t": time.strftime("%Y-%m-%d %H:%M:%S"),
        "messages": [list(m) for m in msgs],
        "candidates": result.get("candidates"),
        "best_index": result.get("best_index"),
        "scores": result.get("scores"),
        "answers": result.get("answers"),
        "usage": result.get("usage"),
    }
    os.makedirs(LOGS, exist_ok=True)
    with open(OUT, "a", encoding="utf-8") as f:
        f.write(json.dumps(payload, ensure_ascii=False) + "\n")
    print(json.dumps(payload, ensure_ascii=False, indent=2))
    return 0


def run_loop(interval: int = 20) -> int:
    seen = 0
    while True:
        try:
            n = len(load_messages(100000))
        except Exception:
            n = seen
        if n != seen:
            seen = n
            try:
                run_once()
            except Exception as exc:  # keep the loop alive
                print("analysis error: %s" % exc)
        time.sleep(interval)


def main() -> int:
    args = sys.argv[1:]
    if "--loop" in args:
        return run_loop()
    limit = 100000 if "--all" in args else 40
    return run_once(limit)


if __name__ == "__main__":
    raise SystemExit(main())
