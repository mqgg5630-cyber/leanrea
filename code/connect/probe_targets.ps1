#Requires -Version 5.1
<#
.SYNOPSIS
    Reachability + identity probe for the desktop PC and the HPC candidates.
    Non-interactive (BatchMode) so nothing hangs waiting for a password.
    ASCII only.
#>
$ErrorActionPreference = 'Continue'
function Line([string]$k, [string]$v) { Write-Output ('{0}={1}' -f $k, $v) }

$targets = @(
    @{ key = 'desktop_lan'; host = '192.168.1.109'; port = 22 },
    @{ key = 'hpc_campus';  host = '10.10.5.210';    port = 22 },
    @{ key = 'hpc_paratera'; host = 'wheshell.hpccube.com'; port = 65032 },
    @{ key = 'hpc_scnet';   host = 'zzeshell.scnet.cn';     port = 65032 }
)

function Tcp-Test([string]$h, [int]$p) {
    try {
        $c = New-Object System.Net.Sockets.TcpClient
        $iar = $c.BeginConnect($h, $p, $null, $null)
        $ok = $iar.AsyncWaitHandle.WaitOne(4000, $false)
        if (-not $ok) { $c.Close(); return 'timeout' }
        $c.EndConnect($iar); $c.Close(); return 'open'
    } catch { return 'refused/err' }
}

foreach ($t in $targets) {
    Line ('TCP ' + $t.key + ' ' + $t.host + ':' + $t.port) (Tcp-Test $t.host $t.port)
    $cmd = 'echo OK; hostname; whoami; uname -a 2>/dev/null || ver'
    $out = & ssh.exe -o BatchMode=yes -o StrictHostKeyChecking=accept-new -o ConnectTimeout=6 `
             -p $t.port $t.host $cmd 2>&1
    $code = $LASTEXITCODE
    Line ('SSH ' + $t.key) ('exit=' + $code + ' :: ' + ((($out -join ' | ') -replace '\s+', ' ').Substring(0, [Math]::Min(220, (($out -join ' | ') -replace '\s+', ' ').Length))))
}

# ---- LAN sweep for a desktop on the wired LAN ------------------------------
$local = @(Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
           Where-Object { $_.IPAddress -match '^(192\.168|10\.)' -and $_.InterfaceAlias -notmatch 'Loopback|Tailscale|vEthernet' } |
           ForEach-Object { $_.IPAddress + '@' + $_.InterfaceAlias })
Line 'LOCAL_IPS' ($local -join ', ')

# ---- tailscale peers -------------------------------------------------------
$ts = Get-Command tailscale.exe -ErrorAction SilentlyContinue
if ($ts) {
    $st = (& $ts.Source status --peers 2>&1) -join "`n"
    $desk = ($st -split "`n" | Where-Object { $_ -match 'desktop|muse' }) -join ' ;; '
    Line 'TS_PEERS' (($desk -replace '\s+', ' ').Substring(0, [Math]::Min(400, ($desk -replace '\s+', ' ').Length)))
    Line 'TS_PING_DESKTOP' ((((& $ts.Source ping -c 1 --timeout 5s 100.84.137.117 2>&1) -join ' ') -replace '\s+', ' '))
    Line 'TS_PING_MUSE' ((((& $ts.Source ping -c 1 --timeout 5s 100.109.207.34 2>&1) -join ' ') -replace '\s+', ' '))
}

# ---- HPC scheduler hints from config --------------------------------------
$cfg = Join-Path $env:USERPROFILE '.ssh\config'
if (Test-Path -LiteralPath $cfg) {
    Line 'SSH_CONFIG_RAW' ((Get-Content -LiteralPath $cfg -Encoding UTF8 | Where-Object { $_ -notmatch '^\s*#' -and $_.Trim() -ne '' }) -join ' | ')
}
Line 'PROBE_DONE' 'True'
