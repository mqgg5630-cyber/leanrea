#Requires -Version 5.1
<#
.SYNOPSIS
    Why are BOTH Sunlogin and Tailscale offline for the desktop?
    Collects tailnet state, subnet routes, netcheck, and local-LAN hints.
    ASCII only.
#>
$ErrorActionPreference = 'Continue'
function Line([string]$k, [string]$v) { Write-Output ('{0}={1}' -f $k, $v) }
function Clean([string]$s) { return (($s -replace '\s+', ' ') -replace '[^\x20-\x7E]', '') }

$ts = 'E:\Tailscale\tailscale.exe'
if (-not (Test-Path -LiteralPath $ts)) { $c = Get-Command tailscale.exe -ErrorAction SilentlyContinue; if ($c) { $ts = $c.Source } }
Line 'TS_EXE' ([string](Test-Path -LiteralPath $ts))
if (-not (Test-Path -LiteralPath $ts)) { Line 'FATAL' 'tailscale.exe not found'; exit 2 }

# ---- 1. full peer table ----------------------------------------------------
$st = (& $ts status 2>&1) -join "`n"
foreach ($ln in ($st -split "`n")) { if ($ln.Trim()) { Line 'PEER' (Clean $ln) } }

# ---- 2. subnet routers / advertised routes (does anything expose the office LAN?)
$json = (& $ts status --json 2>&1) -join ''
try {
    $j = $json | ConvertFrom-Json
    Line 'SELF_ONLINE' ([string]$j.Self.Online)
    foreach ($p in $j.Peer.PSObject.Properties) {
        $v = $p.Value
        $routes = @()
        if ($v.PrimaryRoutes) { $routes += $v.PrimaryRoutes }
        if ($v.AllowedIPs) { $routes += @($v.AllowedIPs | Where-Object { $_ -notmatch '/32$' }) }
        Line ('NODE ' + $v.HostName) (Clean ('online=' + $v.Online + ' ip=' + ($v.TailscaleIPs -join ',') + ' os=' + $v.OS +
            ' relay=' + $v.Relay + ' lastseen=' + $v.LastSeen + ' exitnode=' + $v.ExitNode +
            ' routes=' + (($routes | Select-Object -Unique) -join ',')))
    }
} catch { Line 'JSON_PARSE' ('failed: ' + $_.Exception.Message) }

# ---- 3. netcheck (is the laptop's own tailnet healthy?) --------------------
$nc = (& $ts netcheck 2>&1) -join ' ; '
Line 'NETCHECK' (Clean $nc)
Line 'NETCHECK_UDP' (Clean ((($nc -split ';') | Where-Object { $_ -match 'UDP|IPv4|MappingVariesByDestIP|Nearest' }) -join ' | '))

# ---- 4. ports -----------------------------------------------------------------
function Test-Port([string]$h, [int]$p, [int]$ms = 2000) {
    try {
        $c = New-Object System.Net.Sockets.TcpClient
        $ok = $c.BeginConnect($h, $p, $null, $null).AsyncWaitHandle.WaitOne($ms, $false)
        if (-not $ok) { $c.Close(); return 'timeout' }
        $c.EndConnect($null) | Out-Null; $c.Close(); return 'open'
    } catch { return 'reject' }
}
foreach ($h in @('192.168.1.109', '100.84.137.117', '100.109.207.34')) {
    foreach ($p in @(22, 3389, 445, 5938)) {
        Line ("PORT $h`: $p") (Test-Port $h $p)
    }
}

# ---- 5. is Sunlogin installed here, and does it have a device list? ---------
$sun = @()
foreach ($p in @("$env:ProgramFiles\Oray", "${env:ProgramFiles(x86)}\Oray", "$env:ProgramFiles\Sunlogin",
                 "${env:ProgramFiles(x86)}\Sunlogin", "$env:ProgramData\Oray")) {
    if (Test-Path -LiteralPath $p) { $sun += $p }
}
Line 'SUNLOGIN_DIRS' (($sun -join ' | ') -replace '^$', 'none')
$sunProc = @(Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -match 'Sunlogin|Oray|Sunflower' } | ForEach-Object { $_.ProcessName })
Line 'SUNLOGIN_PROCS' (($sunProc -join ',') -replace '^$', 'none')
$sunSvc = @(Get-Service -ErrorAction SilentlyContinue | Where-Object { $_.Name -match 'Sunlogin|Oray' } | ForEach-Object { $_.Name + ':' + $_.Status })
Line 'SUNLOGIN_SVCS' (($sunSvc -join ',') -replace '^$', 'none')

# ---- 6. local LAN: is the desktop actually next to us? ---------------------
$localIps = @(Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
              Where-Object { $_.IPAddress -match '^192\.168\.' -and $_.InterfaceAlias -notmatch 'Loopback|Tailscale' } |
              ForEach-Object { $_.IPAddress })
Line 'LOCAL_LAN_IPS' ($localIps -join ', ')
$nb = @(Get-NetNeighbor -AddressFamily IPv4 -ErrorAction SilentlyContinue |
        Where-Object { $_.State -in @('Reachable', 'Stale', 'Permanent') -and $_.IPAddress -notmatch '^(224|239|255)\.' } |
        Select-Object -First 40 | ForEach-Object { $_.IPAddress + '/' + $_.LinkLayerAddress })
Line 'LAN_NEIGHBORS' ($nb -join ' | ')
foreach ($ip in $localIps) {
    $sub = $ip.Substring(0, $ip.LastIndexOf('.'))
    foreach ($n in @('1', '109', '2')) {
        $h = $sub + '.' + $n
        $r = Test-Port $h 22 900
        if ($r -eq 'open') { Line ('LAN_SSH ' + $h) 'open' }
    }
}
Line 'DIAG_DONE' 'True'
