#Requires -Version 5.1
<#
.SYNOPSIS
    Is the desktop reachable now? Tailscale status, ping, and which services answer.
    Read-only. ASCII only.
#>
$ErrorActionPreference = 'Continue'
function Line([string]$k, [string]$v) { Write-Output ('{0}={1}' -f $k, $v) }

$ts = 'C:\Program Files\Tailscale\tailscale.exe'
if (-not (Test-Path -LiteralPath $ts)) { $c = Get-Command tailscale.exe -ErrorAction SilentlyContinue; if ($c) { $ts = $c.Source } }
Line 'TS_EXE' $ts

if (Test-Path -LiteralPath $ts) {
    $st = (& $ts status 2>&1) -join "`n"
    $mine = ($st -split "`n" | Select-Object -First 8) -join ' ; '
    Line 'TS_STATUS_HEAD' (($mine -replace '\s+', ' ') -replace '[^\x20-\x7E]', '')

    $peers = @($st -split "`n" | Where-Object { $_ -match 'desktop|muse|laptop' })
    Line 'TS_PEERS' ((($peers -join ' ;; ') -replace '\s+', ' ') -replace '[^\x20-\x7E]', '')

    foreach ($ip in @('100.84.137.117', '100.109.207.34')) {
        $p = (& $ts ping -c 2 --timeout 4s $ip 2>&1) -join ' ; '
        Line ('TS_PING ' + $ip) (($p -replace '\s+', ' ') -replace '[^\x20-\x7E]', '')
    }
}

# ---- port sweep on the desktop over Tailscale ------------------------------
function Test-Port([string]$h, [int]$p, [int]$ms = 2500) {
    try {
        $c = New-Object System.Net.Sockets.TcpClient
        $ok = $c.BeginConnect($h, $p, $null, $null).AsyncWaitHandle.WaitOne($ms, $false)
        if (-not $ok) { $c.Close(); return 'timeout' }
        $c.EndConnect($null) | Out-Null
        $c.Close(); return 'open'
    } catch { return 'err' }
}
foreach ($h in @('100.84.137.117', '100.109.207.34')) {
    foreach ($p in @(22, 5985, 5986, 3389, 445, 8000, 8080)) {
        Line ("PORT $h`: $p") (Test-Port $h $p)
    }
}

# ---- banner grab on 22 (ssh vs something else) -----------------------------
function Banner([string]$h, [int]$p) {
    try {
        $c = New-Object System.Net.Sockets.TcpClient
        $c.Connect($h, $p)
        $c.ReceiveTimeout = 4000
        $s = $c.GetStream()
        $buf = New-Object byte[] 96
        $n = $s.Read($buf, 0, $buf.Length)
        $c.Close()
        if ($n -le 0) { return '<no banner>' }
        return ([Text.Encoding]::ASCII.GetString($buf, 0, $n) -replace '\s+', ' ').Trim()
    } catch { return 'conn-err: ' + $_.Exception.Message }
}
Line 'BANNER 100.84.137.117:22' (Banner '100.84.137.117' 22)
Line 'BANNER 192.168.1.109:22' (Banner '192.168.1.109' 22)

# ---- try a non-interactive ssh (BatchMode, every key) ---------------------
$keys = @('id_ed25519', 'id_rsa', 'id_ed25519_shaohua', 'id_ed25519_mqgg')
foreach ($u in @('BNI', 'w24e', 'shaohuawen03')) {
    foreach ($k in $keys) {
        $kp = Join-Path $env:USERPROFILE ('.ssh\' + $k)
        if (-not (Test-Path -LiteralPath $kp)) { continue }
        $o = & ssh.exe -o BatchMode=yes -o StrictHostKeyChecking=accept-new -o ConnectTimeout=6 `
                -o IdentitiesOnly=yes -i $kp ($u + '@100.84.137.117') 'hostname; whoami' 2>&1
        $code = $LASTEXITCODE
        $j = (($o -join ' | ') -replace '\s+', ' ')
        if ($j.Length -gt 120) { $j = $j.Substring(0, 120) }
        Line ('SSH_TRY ' + $u + '/' + $k) ('exit=' + $code + ' :: ' + $j)
        if ($code -eq 0) { return }
    }
}
Line 'DESKTOP_PROBE_DONE' 'True'
