# JevChat-Windows 本机部署 + 常驻监控（agent 侧交付说明）

本机：`LAPTOP-R77M5D6M`（Windows 11 build 26200，用户 `文少`）
源码：<https://github.com/jev-chat/jev-chat-windows>（上游，未改动一行；监控只用钩子注入）
部署根目录：**`E:\0apps\jev-chat-windows`**（不能放 `E:\0github` —— git-sync-hub 的清理逻辑
会把那里除 `.git-sync` / `results` 之外的一切删掉，这是本轮踩到的第一个坑）

---

## 1. 目录结构

```text
E:\0apps\jev-chat-windows\
├─ app\       上游克隆（git，--depth 1；main.py 里只有一段被标记的钩子注入）
├─ venv\      Python 3.11.9 虚拟环境（rapidocr / onnxruntime / PySide6 / windows-capture / SDK）
├─ monitor\   recorder.py（记录钩子）、patch_main.py、verify_ui.py、start_monitor.ps1、sync.ps1
├─ tools\     install.ps1 / pip_worker.ps1 / install_tasks.ps1 / status.ps1 / pull_events.ps1
└─ logs\      events.jsonl、digest-YYYY-MM-DD.md、install.log、pip.log、monitor.log、app_err.log
```

## 2. 监控是怎么接上的（不碰上游逻辑）

`patch_main.py` 在 `app/main.py` 的 `from core.engine import analyze` **之前**插入一段带
`# jev-monitor:hook` 标记的代码（幂等：重复安装只会替换这一段，`git reset --hard` 后重新打一次即可）。
钩子做两件事：

| 钩子 | 记录内容 |
|---|---|
| `app.overlay.Overlay.log_message` | 每一条新消息：会话名、说话人（`her`/`me`）、群昵称、文本、界面时间 |
| `core.engine.analyze` | 程序自己的判断结果：7 道判断题、3 条候选、Jev 给的胜出概率、token 用量 |

- 写入 `logs/events.jsonl`（一行一条 JSON，8 MB 自动轮转）
- 同时写 `logs/digest-YYYY-MM-DD.md`（人可读的当日摘要）
- **不上传**、不落截图：帧仍在内存里（沿用上游硬约束），只有 OCR 出来的文字进日志

QQ 支持也在 `recorder.py` 里：运行期往 `app.chatapps.APPS` 注入一个 `qq` 画像
（`QQ.exe`，我方气泡 `#0099FF` 判左右），上游文件不改；`JEV_MONITOR_QQ=0` 可关掉。


## 2b. 为什么最后是"无界面记录器"（2026-10-26 21:00 更新）

PySide6 **在这台机器上装不起来**：`Qt6Core.dll` 用 ctypes 直接加载就是
`WinError 127 / 找不到指定的程序`（Qt 6.12、Qt 6.8.3、6.7.3 都一样；系统 VC 运行时已是
14.44，PySide6 自带的也是 14.44，所有 Qt DLL 都在）。也就是说这台 Windows（build 26200，
大概率是精简版镜像）缺了 Qt 需要的一个系统导出函数 —— 这是**图形界面**的问题，与采集无关：
numpy / rapidocr / windows-capture 全部导入正常，OCR 模型预热 `OCR_OK`。

所以监控走 `monitor/headless_watch.py`：直接复用上游的 `app/capture.py` + `app/ocr.py`
（Windows Graphics Capture 取帧 → 定位消息区 → OCR 分左右气泡 → 去重），**不需要 Qt**，
也不需要那两把 key。功能对照：

| 能力 | GUI (`app/main.py`) | headless_watch.py |
|---|---|---|
| 截自己屏幕上的聊天窗口 | ✅ | ✅ |
| OCR 分"对方/我" | ✅ | ✅ |
| 新消息去重、记录 | ✅ | ✅ |
| 悬浮窗 + 3 条候选 + 填入输入框 | ✅（需 key + 能加载 Qt） | ❌ |

启动方式：默认就是 headless；想试图形界面用
`monitor\start_monitor.ps1 -Gui`（Qt 修好之后才有意义）。

## 2c. 记录长什么样

`logs/events.jsonl` 一行一条 JSON：

```json
{"t":"2026-10-26 21:12:03","kind":"msg","chat":"小王","who":"her","name":"","text":"在吗","clock":"21:12"}
{"t":"...","kind":"chat_switch","chat":"小王"}
{"t":"...","kind":"heartbeat","frames":812,"messages":37,"chat":"小王"}
```

`logs/digest-2026-10-26.md` 是人可读的当日摘要，`logs/watcher.log` 是运行日志。


## 2d. 真·自动分析（本机模型，无需 key）

需求是"来一条消息就出分析、我不在线也要跑"。API key 一路做不到（没有 key），
所以改成**在本机跑小模型**：

| 项 | 值 |
|---|---|
| 运行时 | Ollama 0.40（静默安装，服务常驻 127.0.0.1:11434） |
| 模型 | `qwen2.5:3b`（Q4，~2 GB，完全塞进 GTX 1650 的 4 GB 显存） |
| 触发 | `monitor/auto_analyze.py` 跟读 `logs/events.jsonl`，出现**对方新消息**后等 25 秒安静窗口（一句话一段、连发多条只分析一次，最长等 120 秒） |
| 输出 | `logs/analysis.jsonl`（全部历史）、`logs/live.md`、`logs/live.html`（每 5 秒自动刷新的卡片：意图/情绪/风险/3 条候选/推荐理由） |
| 常驻 | 计划任务 `jev-chat-analyze`（登录自启）；模型没装好时每 30 秒重试，不影响记录 |
| 隐私 | 提示词和聊天内容只在本机 GPU 上算，不出网、不花钱 |

整条链：`headless_watch.py`（截屏+OCR，一直跑）→ `events.jsonl` →
`auto_analyze.py`（本机模型）→ `live.html` + `analysis.jsonl`。
原来的付费路径保留：`monitor/analyze_local.py` 在填了 `LLM_API_KEY` 时可以直接
用 DeepSeek 起草 + 判断（更快更准），填了 `JEV_API_KEY` 则走官方 Jev 排序。

下载说明：这台机器的代理会在 10 秒左右掐断长连接，`fetch_ollama.ps1` 因此把
1.6 GB 安装包切成 199 个 8 MB 分片、4 个并发、每片带校验和重试、拼完后与官方
`sha256sum.txt` 对账。

## 3. 常驻方式

| 计划任务 | 触发 | 作用 |
|---|---|---|
| `jev-chat-monitor` | 用户登录时 | `monitor\start_monitor.ps1` → 单实例启动 `pythonw main.py`（带钩子）；失败 1 分钟后重试 3 次 |
| `jev-chat-sync` | —— | **未注册**（你选的是"只在本地留档"）。需要自动推送时运行 `tools\install_tasks.ps1 -WithSync` |

单实例判定：命令行匹配 `jev-chat-windows\app\main.py`，已在跑就不再开第二个。

## 4. 两把 key 与"没有 key"时的行为

- 程序需要 `JEV_API_KEY`（判断）和 `LLM_API_KEY`（起草），只在设置页写进 `HKCU\Environment`，
  任何文件里都不会出现。
- 没填 key 时：**采集与记录照常工作**，只是程序自己不产出候选（状态栏提示"请先在设置中配置模型"）。
  此时分析由 agent 侧完成 —— 记录经 hub 拉取后，agent 给出意图判断 + 候选回复，写成
  `results/jev-monitor/analysis-*.md`，再由 hub 镜像回本机
  `E:\0github\results\leanrea-4d729933-leanrea\jev-monitor\`。

## 5. 每次要"看一眼"时 agent 做什么

```powershell
# agent 侧（通过 git-sync-hub 在本机执行，产物随 push 回传）
powershell -NoProfile -ExecutionPolicy Bypass -File code\jev\pull_events.ps1
```

它产出 `results/jev-monitor/pull-<时间戳>.md`：健康快照（进程/任务/钩子/key/app HEAD）
＋ 最近 120 条会话记录 ＋ 程序自己的判断与候选。agent 读完写分析，再镜像回本机。

## 6. 排障入口

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File E:\0apps\jev-chat-windows\tools\status.ps1
```

一行一项：`APP_CLONE`、`VENV`、`HOOK_IN_MAIN`、`APP_RUNNING`、任务状态、`KEY`、`WECHAT_PROC`、
日志大小，以及 `events.jsonl` 的最后 12 条。

常见故障：

| 现象 | 原因 / 处理 |
|---|---|
| `采集停了（聊天窗口关了？）` | 微信/QQ 主窗口必须存在且**不能最小化**（被别的窗口盖住没事） |
| `消息区认不出来（窗口太小？）` | 窗口拉大一点；这个启发式是按微信布局调的，QQ 需要实测校准 |
| `pip` 报 `THESE PACKAGES DO NOT MATCH THE HASHES` | 本机 v2rayN 代理（`127.0.0.1:18088`）会破坏大文件下载；`pip_worker.ps1 -NoProxy` + 国内镜像解决 |
| 启动就弹设置页 | 没配 key；关掉即可，采集不受影响 |

## 7. 已验证 / 待验证

已验证：venv 可用（3.11.9 + pip 24）、上游克隆完成（`app_head=c6d3a10`）、依赖与 OCR 模型安装、
计划任务注册、`D:\桌面\测试成功.txt` 写入与回执（hub 链路 10 s 往返）。

待验证：微信/QQ 窗口的实机 `chat_area` 识别与 OCR —— 需要你先把微信（或 QQ）打开、
点开一个会话、**不要最小化**，然后 agent 跑 `monitor/verify_ui.py` 出报告。
