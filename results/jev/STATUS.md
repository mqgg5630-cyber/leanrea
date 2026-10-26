# JevChat 部署进度（agent 实时记录）

更新时间：2026-10-26 20:24（本机时间，UTC+8）

## 已完成

| 项 | 证据 |
|---|---|
| git-sync-hub 链路可用 | `D:\桌面\测试成功.txt` 写入成功（21 字节，UTF-8），往返 10 s，`tasks_all_ok=true`（commit `3214c55`） |
| 本机环境探明 | Win11 build 26200 / PS 5.1 / Python 3.11.9 (`E:\spider\python.exe`) / git 2.54 / node 22 / E: 剩 267 GB / PyPI+镜像可达 |
| 微信位置确认 | `E:\新建文件夹\Weixin\Weixin.exe`（Weixin 4.x，进程名 `weixin.exe`）；QQ 在 `E:\Program Files\QQ.exe` |
| 部署根目录 | **`E:\0apps\jev-chat-windows`**（`E:\0github` 会被 hub 清理逻辑清空，已踩过并绕开） |
| 上游源码 | 克隆完成 `app_head=c6d3a10`，`main.py` 已注入 `# jev-monitor:hook` |
| venv | Python 3.11.9 + pip 24.0（`E:\0apps\jev-chat-windows\venv`） |
| 依赖 | 安装中：numpy 2.4.6、pillow 已就位；rapidocr / PySide6 / SDK 排队 |
| 计划任务 | `jev-chat-monitor`（登录自启，单实例）已注册；`jev-chat-sync` 按"仅本地留档"要求**不注册** |

## 正在做

依赖安装（直连国内镜像；本机 v2rayN 代理 `127.0.0.1:18088` 会把大 wheel 传坏，
curl 单连接却正常，所以 pip 走代理必失败 —— 已改为直连 + 失败重试）。
日志：`E:\0apps\jev-chat-windows\logs\pip.log`。

## 待办

1. 依赖装完 → 重跑 `install.ps1` 的收尾阶段（导入自检、OCR 模型预热、任务注册）
2. 启动程序（`Start-ScheduledTask jev-chat-monitor`）→ 弹设置页（先关掉，没 key 也能采集）
3. `verify_ui.py` 实机验证：微信/QQ 窗口的消息区识别 + OCR（需要窗口开着、不最小化）
4. 拉取第一份记录 `pull_events.ps1` → 我给出分析

## 已知限制

- 没有 `JEV_API_KEY` / `LLM_API_KEY`：程序自己不产出候选，采集与记录照常；
  分析由 agent 侧完成（拉取 → 分析 → `results/jev-monitor/analysis-*.md` → hub 镜像回本机）。
- QQ 适配是运行期注入的画像（我方气泡 `#0099FF`），消息区启发式按微信调的，需要实机校准。
- 微信窗口**不能被最小化**（Windows 不给最小化窗口出帧），被别的窗口盖住没问题。
