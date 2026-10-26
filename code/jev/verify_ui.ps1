#Requires -Version 5.1
<#
.SYNOPSIS
    Run the read-only UI check and publish its result to the agent.
    Writes results/jev-monitor/ui-check-<ts>.txt inside the clone (relative cwd),
    which git-sync-hub commits and pushes back.
    ASCII only.
#>
$ErrorActionPreference = 'Continue'

$Root = 'E:\0apps\jev-chat-windows'
$VPy  = Join-Path $Root 'venv\Scripts\python.exe'

$dstDir = Join-Path (Get-Location).Path 'results\jev-monitor'
if (-not (Test-Path -LiteralPath $dstDir)) { New-Item -ItemType Directory -Path $dstDir -Force | Out-Null }
$dst = Join-Path $dstDir ('ui-check-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.txt')

if (-not (Test-Path -LiteralPath $VPy)) {
    'MISSING_VENV=' + $VPy | Set-Content -LiteralPath $dst -Encoding UTF8
    Write-Output 'missing venv'
    exit 3
}
if (-not (Test-Path -LiteralPath (Join-Path $Root 'monitor\verify_ui.py'))) {
    'MISSING_SCRIPT=monitor\verify_ui.py' | Set-Content -LiteralPath $dst -Encoding UTF8
    Write-Output 'missing verify_ui.py'
    exit 3
}

$out = & $VPy (Join-Path $Root 'monitor\verify_ui.py') 2>&1
$code = $LASTEXITCODE
$text = @('exit_code=' + $code) + @($out | ForEach-Object { $_.ToString() })
$text | Set-Content -LiteralPath $dst -Encoding UTF8
$text | ForEach-Object { Write-Output $_ }
