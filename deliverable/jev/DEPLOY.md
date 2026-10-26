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

待验证：微信/QQ 窗口的实机 `chat_area` 识别与 OCR（需要窗口开着，用 `verify_ui.py` 出报告）。
