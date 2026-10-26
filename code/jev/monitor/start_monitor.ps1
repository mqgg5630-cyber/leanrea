#Requires -Version 5.1
<#
.SYNOPSIS
    Start the chat recorder (single instance).

.DESCRIPTION
    Default: monitor\headless_watch.py - capture + OCR without Qt. Needed on hosts
    where PySide6 cannot load (this machine: Qt6Core.dll WinError 127), and enough
    for recording, which is what the agent analyses.

    -Gui: start the upstream JevChat overlay (app\main.py) instead - only works
    when PySide6 imports; it additionally needs the two API keys to draft replies.

    ASCII only.
#>
param(
    [switch]$Gui
)
$ErrorActionPreference = 'Continue'

$Root   = 'E:\0apps\jev-chat-windows'
$AppDir = Join-Path $Root 'app'
$Logs   = Join-Path $Root 'logs'
$Note   = Join-Path $Logs 'monitor.log'

if (-not (Test-Path -LiteralPath $Logs)) { New-Item -ItemType Directory -Path $Logs -Force | Out-Null }

function Note([string]$m) {
    try { Add-Content -LiteralPath $Note -Value ('[{0}] start_monitor: {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $m) -Encoding UTF8 } catch {}
}

if ($Gui) {
    $Py = Join-Path $Root 'venv\Scripts\pythonw.exe'
    $marker = 'jev-chat-windows\\app\\main\.py'
    $script = 'main.py'
    $wd = $AppDir
} else {
    $Py = Join-Path $Root 'venv\Scripts\pythonw.exe'
    $marker = 'jev-chat-windows\\monitor\\headless_watch\.py'
    $script = Join-Path $Root 'monitor\headless_watch.py'
    $wd = $Root
}

if (-not (Test-Path -LiteralPath $Py)) { Note 'venv pythonw.exe missing - run tools\install.ps1 first'; exit 3 }
if (-not (Test-Path -LiteralPath $script)) { Note ('missing ' + $script); exit 3 }

$running = @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object {
    $_.CommandLine -and ($_.CommandLine -match $marker) })
if ($running.Count -gt 0) {
    Note ('already running (pid ' + (($running | ForEach-Object { $_.ProcessId }) -join ',') + ') - nothing to do')
    exit 0
}

$env:JEV_MONITOR_ROOT = $Root
Start-Process -FilePath $Py -ArgumentList ('"' + $script + '"') -WorkingDirectory $wd `
    -RedirectStandardError (Join-Path $Logs 'app_err.log') `
    -RedirectStandardOutput (Join-Path $Logs 'app_out.log')
Note ('launched ' + $script)
Write-Output 'started'
