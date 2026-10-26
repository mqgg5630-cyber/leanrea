# -*- coding: utf-8 -*-
"""Auto analysis, on this machine, 24/7 - no API key, nothing leaves the laptop.

Pipeline
    logs/events.jsonl (written by headless_watch.py)
      -> new "her" message detected
      -> wait for a quiet window (a burst of messages is analysed once)
      -> local Ollama model (qwen2.5:3b on the GTX 1650)
      -> intent / emotion / risk / 3 ranked replies
      -> logs/analysis.jsonl        (one JSON per analysis, append-only)
         logs/live.md               (latest card, overwritten - what the dashboard shows)
         docs/live.html? no: logs/live.html is written by render()

Options
    --once      analyse the current tail once and exit
    --model M   override the model name
    --quiet N   seconds of silence before analysing (default 25)
    --maxwait N seconds cap while messages keep coming (default 120)
"""
from __future__ import annotations

import json
import os
import sys
import time
import urllib.error
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
LOGS = os.path.join(ROOT, "logs")
EVENTS = os.path.join(LOGS, "events.jsonl")
ANALYSIS = os.path.join(LOGS, "analysis.jsonl")
LIVE_MD = os.path.join(LOGS, "live.md")
LIVE_HTML = os.path.join(LOGS, "live.html")
STATE = os.path.join(LOGS, "auto_analyze.state")
LOG = os.path.join(LOGS, "auto_analyze.log")

OLLAMA = "http://127.0.0.1:11434/api/chat"
DEFAULT_MODEL = "qwen2.5:3b"
QUIET = 25.0
MAXWAIT = 120.0
CONTEXT = 14

SYSTEM = (
    "你是中文亲密关系沟通顾问，判断准确、不讨好、不说教。"
    "只输出一个 JSON 对象，不要解释，不要 markdown 代码块。"
)

PROMPT = """下面是两个人手机上的聊天记录（她 = 对方，我 = 我）。最后一条是她说的。

对话：
{transcript}

请输出 JSON：
{{"intent":"她最后这句话真正的意思，一句话",
"emotion":"她的情绪和强度，一句话",
"risk":"如果回复不当，最可能出现的问题，一句话",
"replies":["候选1","候选2","候选3"],
"best":0,
"why":"为什么这条最好，一句话"}}

要求：replies 用「我」的口吻，像真人聊天，20~45 字，不要客服腔，不要排比，
不要用「首先/其次」，不要写解释；best 是 0~2 的整数。"""


def log(msg: str) -> None:
    line = "[%s] auto: %s" % (time.strftime("%Y-%m-%d %H:%M:%S"), msg)
    try:
        os.makedirs(LOGS, exist_ok=True)
        with open(LOG, "a", encoding="utf-8") as f:
            f.write(line + "\n")
    except OSError:
        pass


# ------------------------------------------------------------------ events
def read_events() -> list:
    out = []
    try:
        with open(EVENTS, encoding="utf-8-sig") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    out.append(json.loads(line))
                except ValueError:
                    continue
    except OSError:
        pass
    return out


def messages(events: list) -> list:
    return [e for e in events if e.get("kind") == "msg" and (e.get("text") or "").strip()]


def fingerprint(ev: dict) -> str:
    return "%s|%s|%s" % (ev.get("t"), ev.get("who"), (ev.get("text") or "")[:40])


def load_state() -> dict:
    try:
        with open(STATE, encoding="utf-8") as f:
            return json.load(f)
    except (OSError, ValueError):
        return {}


def save_state(st: dict) -> None:
    try:
        with open(STATE, "w", encoding="utf-8") as f:
            json.dump(st, f, ensure_ascii=False)
    except OSError:
        pass


# ------------------------------------------------------------------ model
def ask_model(model: str, prompt: str, timeout: int = 240) -> dict:
    body = json.dumps({
        "model": model,
        "stream": False,
        "keep_alive": "30m",
        "options": {"temperature": 0.4, "num_predict": 700},
        "messages": [
            {"role": "system", "content": SYSTEM},
            {"role": "user", "content": prompt},
        ],
    }, ensure_ascii=False).encode("utf-8")
    req = urllib.request.Request(OLLAMA, data=body,
                                 headers={"Content-Type": "application/json; charset=utf-8"})
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        payload = json.loads(resp.read().decode("utf-8", "replace"))
    text = ((payload.get("message") or {}).get("content") or "").strip()
    start = text.find("{")
    end = text.rfind("}")
    if start < 0 or end <= start:
        raise ValueError("model did not return JSON: %s" % text[:200])
    return json.loads(text[start:end + 1])


# ------------------------------------------------------------------ output
def render(rec: dict) -> None:
    def esc(s: str) -> str:
        return (s or "").replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")

    replies = rec.get("replies") or []
    best = rec.get("best") or 0
    try:
        best = max(0, min(len(replies) - 1, int(best)))
    except (TypeError, ValueError):
        best = 0
    lines = []
    for i, r in enumerate(replies):
        lines.append("- **%s%s** %s" % ("① ② ③"[i] if i < 3 else str(i + 1),
                                        " ← 推荐" if i == best else "", r))
    md = "\n".join([
        "# 实时分析 %s" % rec.get("t", ""),
        "",
        "会话：`%s`　模型：`%s`（本机，无云端）" % (rec.get("chat") or "-", rec.get("model") or "-"),
        "",
        "**她最后说**：%s" % (rec.get("last") or ""),
        "",
        "| 项 | 判断 |",
        "|---|---|",
        "| 真实意图 | %s |" % (rec.get("intent") or "-"),
        "| 情绪 | %s |" % (rec.get("emotion") or "-"),
        "| 风险 | %s |" % (rec.get("risk") or "-"),
        "",
        "## 候选回复",
        "",
    ] + lines + [
        "",
        "> %s" % (rec.get("why") or ""),
        "",
        "---",
        "",
        "（秒级自动更新；历史在同目录 analysis.jsonl）",
    ])
    try:
        with open(LIVE_MD, "w", encoding="utf-8") as f:
            f.write(md + "\n")
    except OSError:
        pass

    html = """<!doctype html><html lang="zh"><head><meta charset="utf-8">
<meta http-equiv="refresh" content="5"><title>聊天实时分析</title>
<style>
body{{background:#14161a;color:#e8e8ea;font:16px/1.7 "Microsoft YaHei",system-ui;margin:0;padding:24px}}
.card{{max-width:820px;margin:0 auto;background:#1c1f26;border-radius:14px;padding:22px 26px;
box-shadow:0 8px 30px rgba(0,0,0,.35)}}
h1{{font-size:18px;color:#8ab4f8;margin:0 0 4px}}
.meta{{color:#7d828c;font-size:13px;margin-bottom:16px}}
.q{{background:#232733;border-left:4px solid #8ab4f8;padding:10px 14px;border-radius:6px;margin:14px 0}}
table{{border-collapse:collapse;width:100%;margin:14px 0}}
td{{border-bottom:1px solid #2b2f3a;padding:8px 6px;vertical-align:top}}
td:first-child{{color:#8b93a3;width:96px}}
.r{{padding:10px 14px;border-radius:8px;background:#20242d;margin:8px 0;cursor:pointer}}
.best{{background:#1f3a2c;border:1px solid #2f6b4a}}
.tag{{color:#5ad18a;font-size:12px;margin-left:8px}}
.why{{color:#9aa3b2;font-size:13px;margin-top:12px}}
</style></head><body><div class="card">
<h1>聊天实时分析</h1>
<div class="meta">会话 {chat} · 模型 {model} · 更新于 {t} · 每 5 秒自动刷新</div>
<div class="q">她最后说：{last}</div>
<table>
<tr><td>真实意图</td><td>{intent}</td></tr>
<tr><td>情绪</td><td>{emotion}</td></tr>
<tr><td>风险</td><td>{risk}</td></tr>
</table>
{replies}
<div class="why">{why}</div>
</div></body></html>"""

    cards = []
    for i, r in enumerate(replies):
        cards.append('<div class="r%s">%s%s<div style="color:#6f7686;font-size:12px;margin-top:4px">'
                     '点一下复制</div></div>' % (
                         " best" if i == best else "",
                         esc(r),
                         '<span class="tag">推荐</span>' if i == best else ""))
    try:
        with open(LIVE_HTML, "w", encoding="utf-8") as f:
            f.write(html.format(
                chat=esc(rec.get("chat") or "-"), model=esc(rec.get("model") or "-"),
                t=esc(rec.get("t") or ""), last=esc(rec.get("last") or ""),
                intent=esc(rec.get("intent") or "-"), emotion=esc(rec.get("emotion") or "-"),
                risk=esc(rec.get("risk") or "-"), replies="\n".join(cards),
                why=esc(rec.get("why") or "")))
    except OSError:
        pass


def analyse(model: str, msgs: list) -> dict:
    tail = msgs[-CONTEXT:]
    transcript = "\n".join("%s：%s" % ("她" if m.get("who") == "her" else "我", m.get("text"))
                           for m in tail)
    data = ask_model(model, PROMPT.format(transcript=transcript))
    rec = {
        "t": time.strftime("%Y-%m-%d %H:%M:%S"),
        "chat": tail[-1].get("chat") or "",
        "model": model,
        "last": (tail[-1].get("text") or "")[:200],
        "intent": data.get("intent") or "",
        "emotion": data.get("emotion") or "",
        "risk": data.get("risk") or "",
        "replies": [str(x) for x in (data.get("replies") or [])][:3],
        "best": data.get("best"),
        "why": data.get("why") or "",
        "context": [{"who": m.get("who"), "text": m.get("text")} for m in tail],
    }
    with open(ANALYSIS, "a", encoding="utf-8") as f:
        f.write(json.dumps(rec, ensure_ascii=False) + "\n")
    render(rec)
    return rec


# ------------------------------------------------------------------ loop
def wait_quiet(quiet: float, maxwait: float, since_n: int) -> int:
    """Wait until no new message for `quiet` s (or `maxwait` s total)."""
    start = time.time()
    n = since_n
    while True:
        time.sleep(2.0)
        cur = len(messages(read_events()))
        if cur != n:
            n = cur
            start = time.time()  # burst still going
            continue
        if time.time() - start >= quiet or time.time() - start >= maxwait:
            return cur


def run_loop(model: str, quiet: float, maxwait: float) -> int:
    log("loop start model=%s quiet=%.0fs maxwait=%.0fs" % (model, quiet, maxwait))
    st = load_state()
    seen = st.get("last", "")
    while True:
        try:
            msgs = messages(read_events())
            if not msgs:
                time.sleep(5)
                continue
            last = msgs[-1]
            key = fingerprint(last)
            if key == seen:
                time.sleep(5)
                continue
            if last.get("who") != "her":
                # our own message: nothing to answer, but remember it
                seen = key
                save_state({"last": key})
                time.sleep(5)
                continue
            n = wait_quiet(quiet, maxwait, len(msgs))
            msgs = messages(read_events())[:n]
            if not msgs or msgs[-1].get("who") != "her":
                seen = fingerprint(msgs[-1]) if msgs else seen
                save_state({"last": seen})
                continue
            rec = analyse(model, msgs)
            seen = fingerprint(msgs[-1])
            save_state({"last": seen})
            log("analysed: %s -> %d replies" % (rec.get("last", "")[:40], len(rec.get("replies") or [])))
        except urllib.error.URLError as exc:
            log("ollama unreachable: %s (retry in 30s)" % exc)
            time.sleep(30)
        except Exception as exc:
            log("error: %s (retry in 20s)" % exc)
            time.sleep(20)


def main() -> int:
    args = sys.argv[1:]
    model = DEFAULT_MODEL
    quiet, maxwait = QUIET, MAXWAIT
    for i, a in enumerate(args):
        if a == "--model" and i + 1 < len(args):
            model = args[i + 1]
        elif a == "--quiet" and i + 1 < len(args):
            quiet = float(args[i + 1])
        elif a == "--maxwait" and i + 1 < len(args):
            maxwait = float(args[i + 1])
    try:
        if "--once" in args:
            msgs = messages(read_events())
            if not msgs:
                print("no messages")
                return 0
            rec = analyse(model, msgs)
            print(json.dumps(rec, ensure_ascii=False, indent=2))
            return 0
    except Exception as exc:
        print("error: %s" % exc)
        return 2
    return run_loop(model, quiet, maxwait)


if __name__ == "__main__":
    raise SystemExit(main())
