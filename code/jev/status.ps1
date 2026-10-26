#Requires -Version 5.1
<#
.SYNOPSIS
    One-shot status report for the jev-chat-windows deployment.
    ASCII only; safe to run any time (read-only).
#>
$ErrorActionPreference = 'Continue'

$Root    = 'E:\0github\apps\jev-chat-windows'
$AppDir  = Join-Path $Root 'app'
$Logs    = Join-Path $Root 'logs'
$Venv    = Join-Path $Root 'venv'
$VPy     = Join-Path $Venv 'Scripts\python.exe'

function Line([string]$k, [string]$v) { Write-Output ('{0}={1}' -f $k, $v) }

Line 'COMPUTER' $env:COMPUTERNAME
Line 'NOW_LOCAL' (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Line 'ROOT_EXISTS' ([string](Test-Path -LiteralPath $Root))
Line 'APP_CLONE' ([string](Test-Path -LiteralPath (Join-Path $AppDir 'main.py')))
if (Test-Path -LiteralPath (Join-Path $AppDir '.git')) {
    $h = (& git -C $AppDir rev-parse --short HEAD 2>&1) -join ' '
    Line 'APP_HEAD' $h
    $dirty = (& git -C $AppDir status --porcelain 2>&1) -join ' '
    Line 'APP_DIRTY' ($dirty -replace '^$', 'clean')
}
Line 'VENV' ([string](Test-Path -LiteralPath $VPy))
if (Test-Path -LiteralPath $VPy) {
    Line 'VENV_PY' ((& $VPy -c "import sys;print(sys.version.split()[0])" 2>&1) -join '')
}
Line 'HOOK_IN_MAIN' ([string](@(Select-String -LiteralPath (Join-Path $AppDir 'main.py') -Pattern 'jev-monitor:hook' -SimpleMatch -ErrorAction SilentlyContinue).Count -gt 0))

foreach ($f in @('install.log', 'install_status.json', 'events.jsonl', 'monitor.log', 'app_err.log')) {
    $p = Join-Path $Logs $f
    if (Test-Path -LiteralPath $p) {
        $it = Get-Item -LiteralPath $p
        Line ('FILE ' + $f) ('{0} bytes, modified {1}' -f $it.Length, $it.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss'))
    } else { Line ('FILE ' + $f) 'missing' }
}
$digests = @(Get-ChildItem -LiteralPath $Logs -Filter 'digest-*.md' -ErrorAction SilentlyContinue)
Line 'DIGESTS' ([string]$digests.Count)

$events = Join-Path $Logs 'events.jsonl'
if (Test-Path -LiteralPath $events) {
    $last = @(Get-Content -LiteralPath $events -Tail 12 -Encoding UTF8)
    Line 'EVENTS_TAIL_COUNT' ([string]$last.Count)
    foreach ($l in $last) { Line 'EVENT' $l }
}

$proc = @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object {
    $_.CommandLine -and ($_.CommandLine -match 'jev-chat-windows\\app\\main\.py') })
Line 'APP_RUNNING' ([string]($proc.Count -gt 0))
if ($proc.Count -gt 0) { Line 'APP_PIDS' (($proc | ForEach-Object { $_.ProcessId }) -join ',') }

foreach ($n in @('jev-chat-monitor', 'jev-chat-sync', 'git-sync-hub')) {
    try {
        $t = Get-ScheduledTask -TaskName $n -ErrorAction Stop
        $info = & schtasks.exe /query /tn $n /fo LIST 2>&1
        $lastRun = ($info | Where-Object { $_ -match 'Last Run Time|Last Result' }) -join ' ; '
        Line ('TASK ' + $n) ($t.State + ' | ' + ($lastRun -replace '\s+', ' '))
    } catch { Line ('TASK ' + $n) 'missing' }
}

foreach ($k in @('JEV_API_KEY', 'LLM_API_KEY')) {
    Line ('KEY ' + $k) ([string]([bool]([Environment]::GetEnvironmentVariable($k, 'User'))))
}

if (Test-Path -LiteralPath (Join-Path $AppDir 'config.json')) {
    try { Line 'APP_CONFIG' ((Get-Content -LiteralPath (Join-Path $AppDir 'config.json') -Raw -Encoding UTF8) -replace '\s+', ' ') } catch {}
} else { Line 'APP_CONFIG' 'missing (defaults; first run writes it)' }

Line 'WECHAT_PROC' ([string](@(Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -match '^(weixin|wechat|kakaotalk)$' }).Count -gt 0))
Line 'STATUS_DONE' 'True'
