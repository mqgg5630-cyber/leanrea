#Requires -Version 5.1
<#
.SYNOPSIS
    Recon for "connect the desktop PC and the HPC": what this laptop already knows.
    Read-only. ASCII only.
#>
$ErrorActionPreference = 'Continue'
function Line([string]$k, [string]$v) { Write-Output ('{0}={1}' -f $k, $v) }

# ---- 1. SSH material (keys / config / known hosts) ---------------------------
$ssh = Join-Path $env:USERPROFILE '.ssh'
Line 'SSH_DIR' ([string](Test-Path -LiteralPath $ssh))
if (Test-Path -LiteralPath $ssh) {
    $files = @(Get-ChildItem -LiteralPath $ssh -Force -ErrorAction SilentlyContinue |
               Select-Object -First 30 | ForEach-Object { $_.Name })
    Line 'SSH_FILES' ($files -join ', ')
    if (Test-Path (Join-Path $ssh 'config')) {
        $cfg = Get-Content -LiteralPath (Join-Path $ssh 'config') -Encoding UTF8 -ErrorAction SilentlyContinue
        Line 'SSH_CONFIG' (($cfg | Where-Object { $_ -match '^\s*(Host|HostName|User|Port|ProxyJump)' }) -join ' | ')
    }
    if (Test-Path (Join-Path $ssh 'known_hosts')) {
        $hosts = @(Get-Content -LiteralPath (Join-Path $ssh 'known_hosts') -Encoding UTF8 -ErrorAction SilentlyContinue |
                   ForEach-Object { ($_ -split '\s+')[0] } | Sort-Object -Unique | Select-Object -First 25)
        Line 'KNOWN_HOSTS' ($hosts -join ', ')
    }
}

# ---- 2. ssh / scp / rsync clients -------------------------------------------
foreach ($c in @('ssh.exe', 'scp.exe', 'sftp.exe', 'rsync', 'sshpass', 'plink.exe', 'pscp.exe')) {
    $cmd = Get-Command $c -ErrorAction SilentlyContinue
    if ($cmd) { Line ('CMD ' + $c) $cmd.Source }
}

# ---- 3. VPN / tunnels -------------------------------------------------------
$vpn = @(Get-Process -ErrorAction SilentlyContinue |
         Where-Object { $_.ProcessName -match 'v2ray|clash|xray|easyconnect|sangfor|anyconnect|openvpn|wireguard|tailscale|zerotier|frp' } |
         ForEach-Object { $_.ProcessName })
Line 'VPN_PROCS' (($vpn -join ', ') -replace '^$', 'none')
$adapters = @(Get-NetAdapter -ErrorAction SilentlyContinue |
              Where-Object { $_.Status -eq 'Up' } |
              ForEach-Object { '{0}:{1}' -f $_.Name, $_.InterfaceDescription })
Line 'NET_UP' (($adapters | Select-Object -First 8) -join ' | ')

# ---- 4. LAN neighbours (desktop PC?) ---------------------------------------
try {
    $arp = @(Get-NetNeighbor -AddressFamily IPv4 -ErrorAction SilentlyContinue |
             Where-Object { $_.IPAddress -match '^(192\.168|10\.|172\.(1[6-9]|2[0-9]|3[01]))' -and $_.State -ne 'Unreachable' } |
             Select-Object -First 30 | ForEach-Object { $_.IPAddress })
    Line 'LAN_NEIGHBORS' ($arp -join ', ')
} catch { Line 'LAN_NEIGHBORS' 'unavailable' }

# ---- 5. any existing remote-work traces ------------------------------------
$hints = @()
foreach ($p in @('C:\Users\' + $env:USERNAME + '\Documents', 'C:\Users\' + $env:USERNAME + '\Desktop', 'D:\', 'E:\')) {
    if (-not (Test-Path -LiteralPath $p)) { continue }
    try {
        $hints += @(Get-ChildItem -LiteralPath $p -Directory -ErrorAction SilentlyContinue |
                    Where-Object { $_.Name -match '(?i)hpc|slurm|pbs|cluster|ssh|scp|workstation' } |
                    Select-Object -First 4 | ForEach-Object { $_.FullName })
    } catch {}
}
Line 'HINT_DIRS' (($hints -join ' | ') -replace '^$', 'none')

# ---- 6. tailscale / frp style mesh ---------------------------------------
$ts = Get-Command tailscale.exe -ErrorAction SilentlyContinue
if ($ts) {
    $st = (& $ts.Source status 2>&1) -join ' ; '
    Line 'TAILSCALE' ($st -replace '\s+', ' ')
} else { Line 'TAILSCALE' 'missing' }

# ---- 7. current jev workload (to be paused) -------------------------------
$hd = @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object {
    $_.CommandLine -and ($_.CommandLine -like '*headless_watch*' -or $_.CommandLine -like '*pull_model_direct*' -or $_.CommandLine -like '*auto_analyze*') })
Line 'JEV_PROCS' (($hd | ForEach-Object { $_.ProcessId.ToString() + ':' + ($_.CommandLine.Substring(0, [Math]::Min(60, $_.CommandLine.Length))) }) -join ' | ')
Line 'RECON_DONE' 'True'
