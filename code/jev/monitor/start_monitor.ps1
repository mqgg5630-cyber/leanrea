#Requires -Version 5.1
<#
.SYNOPSIS
    Start the JevChat app with the recorder hook attached (single instance).
    Called by the scheduled task jev-chat-monitor (at logon) and by hand.
    ASCII only.
#>
$ErrorActionPreference = 'Continue'

$Root   = 'E:\0apps\jev-chat-windows'
$AppDir = Join-Path $Root 'app'
$Logs   = Join-Path $Root 'logs'
$Py     = Join-Path $Root 'venv\Scripts\pythonw.exe'
$Note   = Join-Path $Logs 'monitor.log'

if (-not (Test-Path -LiteralPath $Logs)) { New-Item -ItemType Directory -Path $Logs -Force | Out-Null }

function Note([string]$m) {
    try { Add-Content -LiteralPath $Note -Value ('[{0}] start_monitor: {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $m) -Encoding UTF8 } catch {}
}

if (-not (Test-Path -LiteralPath $Py)) {
    Note 'venv pythonw.exe missing - run tools\install.ps1 first'
    exit 3
}
if (-not (Test-Path -LiteralPath (Join-Path $AppDir 'main.py'))) {
    Note 'app\main.py missing - run tools\install.ps1 first'
    exit 3
}

# single instance: the app is a GUI, a second copy would duplicate OCR + windows
$running = @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object {
    $_.CommandLine -and ($_.CommandLine -match 'jev-chat-windows\\app\\main\.py') })
if ($running.Count -gt 0) {
    Note ('already running (pid ' + (($running | ForEach-Object { $_.ProcessId }) -join ',') + ') - nothing to do')
    exit 0
}

$env:JEV_MONITOR_ROOT = $Root
Start-Process -FilePath $Py -ArgumentList 'main.py' -WorkingDirectory $AppDir `
    -RedirectStandardError (Join-Path $Logs 'app_err.log') `
    -RedirectStandardOutput (Join-Path $Logs 'app_out.log')
Note 'launched pythonw main.py (recorder hook active)'
Write-Output 'started'
