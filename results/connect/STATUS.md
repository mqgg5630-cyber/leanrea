# 跨机器打通 · 状态

更新：2026-10-27（本地）
负责人：agent（笔记本 hub 侧）

## 一句话

**HPC 已打通并端到端验证**（ssh / 上传 / 提交 Slurm 作业 / 取回结果全通）；
**台式机与 192.168.1.109 未通**，两台都卡在只有你能处理的地方。

## 链路

```
Windows 笔记本 → (校园 VPN) → WSL Ubuntu-26.04(w26) → ssh mu01 → HPC
Windows 笔记本 → (Tailscale) → desktop-ieudgs5      ⛔ offline 8d
Windows 笔记本 → (?)        → 192.168.1.109         ⛔ kex 被拒
```

## 已验证（有据可查）

| 步骤 | 证据 |
|---|---|
| SSH 登录 mu01 | `AUTH_OK / hostname=mu01 / whoami=25wenshaohua` |
| 环境 | CentOS 7.9, kernel 3.10.0-1160.el7, python 3.9.25 (miniconda3), mamba 有, singularity 无 |
| 存储 | GPFS 1.4P, 38% 用, HOME=/mnt/hpc/home/25menglei/25wenshaohua |
| 调度 | Slurm：cu 62 节点(64C/515G, 空闲 15) / fat1 8 节点(96C/1T, 空闲 7) / fat2 1 节点 |
| 上传 | `UPLOAD_OK`，`~/jobs/smoke.sbatch` 392 B |
| 提交 | `JOBID=92384`，节点 `cu46` |
| 执行 | `REACHED_NODE=cu46`, `CPUS=2`, `python 3.9.25`, `GPFS 1.4P` |
| 记账 | `sacct` → `COMPLETED ExitCode 0:0` |
| 取回 | `DOWNLOAD_OK`，133 B 落到本地 `fetched/smoke_92384.out` |

## 工具

`code/connect/hpc.ps1` —— 7 个动作：`info / run / put / get / submit / jobs / log`。
文档见 `deliverable/connect/README.md`。配套脚本：

- `code/connect/hpc_smoke.sh` —— 端到端自检（上传→提交→轮询→取回）
- `code/connect/checks/verify_all.sh` —— 下载链路 + 两台目标机诊断
- `code/connect/templates/smoke.sbatch` —— 最小可跑作业模板（cu 分区，2 核 2G）
- `code/connect/probe_*.ps1`、`hpc_info.sh`、`wsl_probe.sh` —— 侦察脚本（只读）

## 阻塞项（需要用户动作）

1. **台式机 `desktop-ieudgs5`**：Tailscale 离线 8 天 → 请开机并确认 Tailscale 已登录。
2. **`192.168.1.109`**：TCP 能连但密钥交换前被关，全端口无 banner
   → 需确认这台是什么、sshd 是否真在跑（疑似防火墙/端口转发在假应答）。
3. 可选：是否把 WSL 里的 `mu01` 私钥复制到 Windows 侧，摆脱 WSL 依赖。

## 下一步（通了之后）

- 台式机上线后：注册成 hub 的第二个执行目标（`-Action` 复用，加 `-Target desktop`）。
- HPC：把 `amp_pipeline` 那套长任务接进来（fat1 大内存 + 96 核），
  作业模板 → 提交 → `sacct` 轮询 → rsync 取回，形成和本地一致的"提交即可走开"体验。
