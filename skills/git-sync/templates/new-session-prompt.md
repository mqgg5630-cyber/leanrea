# 新对话免终端打通提示词模板 (`git-sync-hub v4.0.0`)

在任何新的 Arena 对话中，用户只需复制发送以下**一句话**即可触发安装并与本地电脑（`LAPTOP-R77M5D6M`）自动打通：

```text
请先执行 git clone --quiet --depth 1 -b arena/626378d6-leanrea https://github.com/mqgg5630-cyber/leanrea.git /tmp/git-sync-src 阅读其中的 01a0a821.md 和 results/cleanup/PERMANENT_HUB_READY.md，然后运行 bash /tmp/git-sync-src/skills/git-sync/scripts/agent-install.sh --source /tmp/git-sync-src --force 安装 git-sync v4.0 技能，并用 bash skills/git-sync/scripts/agent-hub.sh 与我本地电脑（已常驻运行 git-sync-hub v4.0 轮询服务）打通验证。
```

或者超短版（Agent 克隆或抓取该分支页面后同样可读取根 `README.md` 与 `01a0a821.md`）：

```text
安装 https://github.com/mqgg5630-cyber/leanrea/tree/arena%2F626378d6-leanrea 的 skills，通过其中的 git-sync-hub v4.0 机制与本地打通
```
