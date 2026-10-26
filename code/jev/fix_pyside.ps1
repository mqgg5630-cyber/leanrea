#Requires -Version 5.1
<#
.SYNOPSIS
    Find a PySide6 build whose QtCore actually imports on this host.

.DESCRIPTION
    6.12.0 fails with "DLL load failed while importing QtCore: The specified
    procedure could not be found" even though both the bundled and the system VC
    runtimes are 14.44 and every Qt DLL is present. So walk down the versions (via
    uv) until one imports, then report the winner in logs\pyside.log and
    logs\pip_status.json. Detached - each attempt downloads ~100 MB.

    ASCII only.
#>
$ErrorActionPreference = 'Continue'
$ProgressPreference    = 'SilentlyContinue'

$Root   = 'E:\0apps\jev-chat-windows'
$Logs   = Join-Path $Root 'logs'
$Log    = Join-Path $Logs 'pyside.log'
$Status = Join-Path $Logs 'pip_status.json'
$VPy    = Join-Path $Root 'venv\Scripts\python.exe'
$Index  = 'https://mirrors.aliyun.com/pypi/simple/'

if (-not (Test-Path -LiteralPath $Logs)) { New-Item -ItemType Directory -Path $Logs -Force | Out-Null }
function Log([string]$m) {
    $line = '[{0}] fix_pyside: {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $m
    Write-Host $line
    try { Add-Content -LiteralPath $Log -Value $line -Encoding UTF8 } catch {}
}

$uv = "$env:USERPROFILE\.local\bin\uv.exe"
if (-not (Test-Path -LiteralPath $uv)) { $c = Get-Command uv.exe -ErrorAction SilentlyContinue; if ($c) { $uv = $c.Source } }
if (-not (Test-Path -LiteralPath $uv)) { Log 'FATAL: uv missing'; exit 3 }

function Try-Import {
    $r = (& $VPy -c "from PySide6 import QtCore; print('QtCore_OK', QtCore.__version__)" 2>&1) -join ' '
    return $r
}

Log ('current: ' + (Try-Import))

$candidates = @('6.8.3', '6.7.3', '6.6.3.1', '6.9.3', '6.5.3')
$winner = ''
foreach ($v in $candidates) {
    Log ('trying PySide6 ' + $v)
    $out = & $uv pip install --python $VPy ("PySide6==" + $v) ("shiboken6==" + $v) --index-url $Index 2>&1
    $code = $LASTEXITCODE
    $out | Select-Object -Last 4 | ForEach-Object { Log ('  ' + $_) }
    Log ('  uv exit=' + $code)
    if ($code -ne 0) { continue }
    $probe = Try-Import
    Log ('  import -> ' + $probe)
    if ($probe -match 'QtCore_OK') { $winner = $v; break }
}

# Fluent widgets must still import and stay compatible with the chosen Qt
$fluent = ''
if ($winner) {
    & $uv pip install --python $VPy "PySide6-Fluent-Widgets" --index-url $Index 2>&1 |
        Select-Object -Last 3 | ForEach-Object { Log ('  fluent: ' + $_) }
    $fluent = (& $VPy -c "import qfluentwidgets; print('fluent_ok')" 2>&1) -join ' '
    Log ('  fluent import -> ' + $fluent)
}

Log ('WINNER=' + $winner)
$okAll = [bool]$winner
try {
    $st = @{ ok = $okAll; stage = 'pyside'; pyside = $winner; fluent = $fluent }
    $st | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $Status -Encoding UTF8
} catch {}
Log ('DONE ok=' + $okAll)
