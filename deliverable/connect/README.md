# 打通：笔记本 ↔ HPC ↔ 台式机

本目录是"跨机器打通"的可复用工具与结论。目标形态：**笔记本上的常驻 hub 当跳板**，
用一条命令就能在 HPC 上跑命令、传文件、提交作业、取回结果，台式机同理。

```
     Windows 笔记本 (LAPTOP-R77M5D6M, 24/7 hub)
        │
        │  校园 OpenVPN (10.0.0.15)  ── 2 跳直达，12 ms
        ▼
  WSL Ubuntu-26.04 (w26)  ── ssh 别名 mu01，密钥 id_ed25519
        │
        ▼
  HPC mu01 (25wenshaohua@10.10.5.210)  ← 已通 ✅
        │
        └─ Slurm: cu / fat1 / fat2

     Windows 笔记本 ── Tailscale ──> 台式机 desktop-ieudgs5  ← 离线 8 天 ⛔
     Windows 笔记本 ──────────────>  192.168.1.109           ← 握手被拒 ⛔
```

## 为什么走 WSL 而不是 Windows 原生 ssh

Windows 这台机器的 `~/.ssh` 里虽然有 7 把 key，但**没有一把能过 mu01**；
而 WSL 的 `Ubuntu-26.04` 里早就配好了可用的 `Host mu01` 别名和私钥。
所以所有远程调用都包一层：

```powershell
wsl.exe -d Ubuntu-26.04 -e bash <生成的脚本>
```

好处：不动你现有的 WSL 配置，不改权限，不复制私钥到 Windows。
（想彻底摆脱 WSL 依赖的话，把 `\\wsl$\Ubuntu-26.04\home\w26\.ssh\id_ed25519`
复制到 `C:\Users\文少\.ssh\` 并在 config 里加一个 `Host mu01` 即可 —— 需要你点头我再做。）

## 工具：`hpc.ps1`

一个入口，7 个动作。**注意必须用 `-WorkingDirectory` 指定仓库目录**，
否则 `results\` 相对路径会落到 `C:\Windows\System32`。

```powershell
# 1. 环境盘点（主机、分区、配额、python/conda、家目录）
.\tools\hpc.ps1 -Action info

# 2. 在 HPC 上跑命令（复杂命令写进文件，避免三层引号打架）
.\tools\hpc.ps1 -Action run -Cmd 'squeue -u $USER'
.\tools\hpc.ps1 -Action run -CmdFile .\tools\checks\smoke_out.sh

# 3. 上传 / 下载（rsync over ssh，自动增量）
.\tools\hpc.ps1 -Action put -Local .\data\input.fa      -Remote '~/proj/data/'
.\tools\hpc.ps1 -Action get -Remote  '~/proj/out/result.tsv' -Local .\results\

# 4. 提交作业 + 看状态 + 追日志
.\tools\hpc.ps1 -Action submit -Script .\tools\templates\smoke.sbatch
.\tools\hpc.ps1 -Action jobs
.\tools\hpc.ps1 -Action log -Remote '~/jobs/smoke_92384.out'
```

所有输出同时追加到 `results/jev-monitor/hpc-last.txt`，hub 轮询把它带回工作区，
所以 agent 侧不需要交互式会话也能看到结果。

## HPC 实况（2026-10-27 实测）

| 项目 | 值 |
|---|---|
| 主机 | `mu01`，用户 `25wenshaohua`，CentOS 7.9（kernel 3.10.0-1160.el7） |
| 家目录 | `/mnt/hpc/home/25menglei/25wenshaohua` |
| 存储 | GPFS 1.4 P，已用 38%（525 T / 861 T 可用） |
| 调度 | Slurm，3 个分区 |
| `cu` | 62 节点，64 核 / 515 GB，默认分区，实测空闲 15 台 |
| `fat1` | 8 节点，96 核 / 1 TB，实测 7 台空闲（大内存任务首选） |
| `fat2` | 1 节点 |
| 软件 | miniconda3（python 3.9.25）、mamba、gcc；**没有** apptainer/singularity、没有 nvcc |
| 作业目录 | `~/jobs`（本工具约定，提交和取回都放这里） |

## 端到端验证（真的跑过，不是纸上推演）

```
上传  smoke.sbatch  →  UPLOAD_OK
提交  sbatch        →  JOBID=92384
执行  cu46          →  REACHED_NODE=cu46, CPUS=2, python 3.9.25, GPFS 1.4P
状态  sacct         →  COMPLETED ExitCode 0:0
取回  rsync         →  DOWNLOAD_OK, 133 bytes 落到本地
```

复跑方式：

```bash
# 在 WSL 里
bash /mnt/e/0apps/jev-chat-windows/tools/hpc_smoke.sh /mnt/e/hpc_smoke.txt
bash /mnt/e/0apps/jev-chat-windows/tools/verify_all.sh /mnt/e/verify_all.txt
```

## 还没通的两台（卡在需要你动一下的地方）

### 1. 台式机 `desktop-ieudgs5`（Tailscale `100.84.137.117`）

- Tailscale 面板显示 **offline，上次在线 8 天前**
- `tailscale ping` 超时；`ping` 超时 → 机器没开机，或 Tailscale 没登录
- 需要：开机 + 让 Tailscale 上线（托盘确认状态是 Connected）

一旦上线，接法按机器系统二选一：

```powershell
# A. 台式机是 Windows 且开了 OpenSSH Server
.\tools\hpc.ps1 -Action run -Cmd 'hostname'   # 换成 desktop 别名后再用

# B. 台式机是 Linux / WSL
ssh desktop 'hostname'
```

### 2. `192.168.1.109`（用户 BNI）

- TCP 22 端口 **能连上**，但在密钥交换前就被对端关闭：
  `kex_exchange_identification: Connection closed by remote host`
- 22 / 2222 / 3389 / 5985 / 5986 / 445 / 80 **全都没有 banner** →
  不像正常 sshd，更像中间有一层防火墙/端口转发在做 SYN 应答（真机可能没起来）
- 需要你确认：这台到底是什么（谁的机器、什么系统、sshd 有没有真的在跑）

## 已知坑（踩过的，别再踩）

1. **Windows 侧 `ssh 10.10.5.210` 会超时**，但从 WSL 走就正常 —— 排障别只测 Windows 原生 ssh。
2. `tracert` 只 2 跳说明**校园 VPN 是通的**，别被一次 TCP 超时误导成"网络不通"。
3. **`wsl.exe` 的输出是 UTF-16 混着进度条**，直接管道读会得到乱码；
   让 WSL 写到文件、Windows 再读文件就干净了。
4. `.sh` 脚本经 hub 检出会变成 **CRLF**，bash 会报 `ambiguous redirect`；
   运行前必须 `[IO.File]::ReadAllText(p).Replace("\`r","")`。
5. `Start-Process` **不继承当前目录**（默认 `C:\Windows\System32`），
   一定要带 `-WorkingDirectory`，否则结果写错地方。
6. `powershell.exe -File x.ps1 -Cmd "带 空格 的参数"` 会被拆成多个参数 →
   用 `-CmdFile` 传文件，别在被调用方做多层引号转义。
7. 从 `/mnt/e` 直接 `bash script.sh` 在某些挂载配置下返回 **126**（无执行权限）→ 用 `bash /path/script.sh` 显式调用。
