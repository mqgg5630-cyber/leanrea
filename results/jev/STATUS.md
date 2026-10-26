# JevChat 部署 + 常驻监控 —— 最终状态

更新时间：2026-10-26 21:10（本机时间 UTC+8）

## 一句话

程序已装在 `E:\0apps\jev-chat-windows`，无界面记录器（`headless_watch.py`）已作为计划任务
`jev-chat-monitor` 常驻运行、登录自启；它每帧截微信/QQ 窗口做离线 OCR，把新消息写进
`logs\events.jsonl`。**现在只差你把微信（或 QQ）打开、点开一个会话**，它立刻开始记录。

## 已完成并验证

| 项 | 结果 |
|---|---|
| git-sync-hub 通道 | `D:\桌面\测试成功.txt` 21 字节写入成功、10 s 回执（`tasks_all_ok=true`） |
| 部署根目录 | `E:\0apps\jev-chat-windows`（`E:\0github` 会被 hub 清理，已绕开） |
| 上游源码 | `app_head=c6d3a10`，`main.py` 已注入 `# jev-monitor:hook` |
| venv | Python 3.11.9 + uv 安装全套依赖（1041 MB），`numpy / rapidocr / windows_capture / openai / anthropic / google.genai / winsdk` 全部 import OK，OCR 预热 `OCR_OK` |
| 记录器 | `headless_watch.py` 运行中（pythonw，无窗口），命名互斥体保证单实例 |
| 计划任务 | `jev-chat-monitor`（登录自启 + 单实例），`jev-chat-sync` **未注册**（按你选的"只本地留档"） |
| 拉取闭环 | `pull_events.ps1` → `results/jev-monitor/pull-*.md` → hub 推回 agent（已跑通两次） |
| 分支 | 远端只剩 `main` + `arena/4d729933-leanrea`（旧的 `arena/626378d6-leanrea` 已删除，hub 基底仓已切到本分支并验证仍可工作） |
| 桌面 | `D:\桌面\测试成功.txt`、`D:\桌面\JevChat-使用说明.txt` |

## 关键发现（踩坑记录）

1. **`E:\0github` 不能放东西** —— hub 每轮 `Invoke-ResultsOnlyCleanup` 会把除 `.git-sync`/`results`
   之外的全部删掉（第一次部署的 venv 就是这样消失的）。
2. **v2rayN 代理（127.0.0.1:18088）会传坏大 wheel** —— pip 反复
   `THESE PACKAGES DO NOT MATCH THE HASHES`；同样的 URL 用 `curl --http1.1 -x` 拿到的
   sha256 却是对的。直连国内镜像干净但只有 ~200 KB/s。最后用 **uv（并行下载）** 2 分钟装完。
3. **PySide6 在这台机器加载不了** —— `Qt6Core.dll` 直接 ctypes 加载就是
   `WinError 127（找不到指定的程序）`；6.12 / 6.8.3 / 6.7.3 都一样，系统与包内 VC 运行时都是
   14.44，Qt DLL 齐全。结论：这台 Windows（build 26200，疑似精简镜像）缺 Qt 依赖的系统导出。
   所以监控走**无 Qt 的 headless 记录器**（采集/OCR 全部正常），图形悬浮窗暂时不可用。
4. `pull_events.ps1` 里的函数名 `R` 撞上了 PowerShell 内置别名 `r`（Invoke-History），
   导致快照文件为空 —— 已改名 `Rep`。

## 下一步（需要你配合 1 分钟）

1. 打开微信：`E:\新建文件夹\Weixin\Weixin.exe`（或 QQ），**点开一个正在聊的会话**；
   窗口不要最小化（被别的窗口盖住没问题）。
2. 让对方发一条消息（或自己发一条也行，能触发 OCR 就有数据）。
3. 回到 Arena 说「拉一下」，我会：
   - 用 `verify_ui.py` 验证消息区/气泡识别（微信已知可用；**QQ 的布局需要在实机上校准**）
   - 把记录拉上来，给出意图判断 + 3 条候选回复，写到
     `results/jev-monitor/analysis-*.md`，并镜像到本机
     `E:\0github\results\leanrea-4d729933-leanrea\jev-monitor\`

## 说明

- 没有 `JEV_API_KEY` / `LLM_API_KEY`：程序自己不产出候选（它只会记录），分析由 agent 完成。
  想恢复原版悬浮窗（3 条候选 + 一键填入）需要两件事：这台机器能加载 Qt，以及两把 key。
- 想改成"后台每 5 分钟自动推送到仓库"：运行
  `E:\0apps\jev-chat-windows\tools\install_tasks.ps1 -WithSync`（默认关闭）。
