# Arena Desk

本地控制面板 + Notion 实例台账；不是另一个 LLM，也不是 Notion 实时同步服务。

- 程序：`E:\0apps\ArenaDesk`；入口：桌面 `Arena Desk.lnk`。
- 本地服务：`127.0.0.1:18765`；只绑定回环，不供局域网访问。
- `git-sync-hub` 只读、后端白名单拒绝控制；不修改其计划任务或源码。
- 可选：JevChat monitor/analyze、DSH Web、独立桌宠。停止会禁用未来自动启动并停止当前任务。
- 默认发现 `E:\0github\results\*\status\hub_sync_receipt.json`；每十秒刷新。
- 回执仅是历史结果；实时计划任务状态单独采样；缺失、过期与失败如实显示。
- 提示词手动登记，或随会话提交 `results/status/session_manifest.json`。只存用户任务，不存系统消息、凭据、私聊。
- 本地数据在 `data/`，不入 Git。提示词编辑有本地历史，控制有本地审计日志。
- Notion 实例和字段通过已授权连接器维护；标识见 `notion-links.json`。不要索要 token。
- 自动发现目录不代表能恢复所有旧会话的提示词，也不代表接入所有外部 Agent 的实时任务。

## 验证

`python -m unittest discover -s code/panel -p 'test*.py' -v`

Windows 部署：由已有 hub 执行 `code/panel/deploy.ps1`，用户不用开终端。
安装器只注册自己命名的计划任务，保留已有基座；真实 Windows 上做 PS 语法检查和 HTTP 验证。
重装部署会重新启用本面板管理的 DSH/桌宠任务；日常启停请使用面板，不要用部署脚本代替控制。
登录启动需要该用户已登录；睡眠/关机不可能持续监控。

## 可选软件

DSH Host / 数据 / npm 缓存：`E:\0apps\DSH`。
桌宠采用 MerZlin/dsh-pet-indesktop 的 v4.4.0 非聊天便携包，核对 GitHub release SHA-256 后解压。
通过包装脚本为该桌宠进程单独设置 APPDATA/LOCALAPPDATA 到 E 盘，不改系统全局变量。
`dsh-video-skin` 自带启动动画；独立 boot-animation 不默认叠加，避免双重全屏遮罩。
`dsh-wallpaper-engine` npm 包已撤下，必须单独审查源码安装与壁纸库兼容性。
DSH 插件是第三方代码，不给它们配置 AI 密钥，不赋予管理基座的功能。
启动动画属于 DSH 应用（可登录后启动），不修改 Windows 登录前动画。

## 参考而非复制产品身份

- Existing skill: `skills/git-sync/SKILL.md` (permanent hub, results-only receipts)
- https://github.com/NousResearch/hermes-agent (persistent sessions, skills, scheduling, executor boundaries)
- https://github.com/deepseek-ai/deepseek-harness (experimental host; read SAFETY.md)
- https://github.com/Something11235/dsh-video-skin
- https://github.com/MeteorNOX/DeepSeek-Balance-Whale-Widget
- https://github.com/MerZlin/dsh-pet-indesktop
- https://github.com/elysia395/dsh-wallpaper-engine

不能承诺 Arena 对话空闲监控的最长时限；持续性来自本地服务，不来自保持对话不结束。
