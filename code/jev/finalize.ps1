#Requires -Version 5.1
<#
.SYNOPSIS
    Post-install finalisation: hook, self-tests, tasks, launch, status, UI check, pull.

.DESCRIPTION
    Run through git-sync-hub once the dependencies are in place. Everything it
    learns is written under results/jev-monitor/ inside the clone, so the hub's
    push carries it back to the agent.

    ASCII only.
#>
$ErrorActionPreference = 'Continue'

$Root   = 'E:\0apps\jev-chat-windows'
$VPy    = Join-Path $Root 'venv\Scripts\python.exe'
$DstDir = Join-Path (Get-Location).Path 'results\jev-monitor'
$Stamp  = Get-Date -Format 'yyyyMMdd-HHmmss'
if (-not (Test-Path -LiteralPath $DstDir)) { New-Item -ItemType Directory -Path $DstDir -Force | Out-Null }

$report = New-Object System.Collections.ArrayList
function R([string]$s) { [void]$report.Add($s); Write-Output $s }

R ('# finalize ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
R ('root=' + $Root)
R ('venv_python=' + (Test-Path -LiteralPath $VPy))

if (-not (Test-Path -LiteralPath $VPy)) {
    $report | Set-Content -LiteralPath (Join-Path $DstDir ('finalize-' + $Stamp + '.md')) -Encoding UTF8
    R 'abort: no venv python'
    exit 3
}

# ---- 1. hook -----------------------------------------------------------------
R ''
R '## 1 hook'
$hookOut = (& $VPy (Join-Path $Root 'monitor\patch_main.py') $Root 2>&1) -join ' '
R ('patch_main: ' + $hookOut)
$hookPresent = @(Select-String -LiteralPath (Join-Path $Root 'app\main.py') -Pattern 'jev-monitor:hook' -SimpleMatch -ErrorAction SilentlyContinue).Count -gt 0
R ('hook_in_main=' + $hookPresent)

# ---- 2. imports / engine self-tests -----------------------------------------
R ''
R '## 2 imports'
foreach ($mod in @('numpy', 'rapidocr_onnxruntime', 'PySide6', 'windows_capture', 'openai', 'anthropic', 'google.genai', 'winsdk')) {
    $r = (& $VPy -c "import $mod; print('ok')" 2>&1) -join ' '
    R ('  ' + $mod + ' = ' + ($r -match 'ok'))
}
Push-Location (Join-Path $Root 'app')
R ('  core/engine.py selftest: ' + ((& $VPy 'core\engine.py' 2>&1) -join ' '))
R ('  app/chatapps.py selftest: ' + ((& $VPy 'app\chatapps.py' 2>&1) -join ' '))
Pop-Location

R ''
R '## 3 ocr warm-up'
$ocr = (& $VPy -c "from rapidocr_onnxruntime import RapidOCR; RapidOCR(); print('OCR_OK')" 2>&1) -join ' '
R ('  ' + $ocr)

# ---- 4. tasks ---------------------------------------------------------------
R ''
R '## 4 scheduled tasks (local-only: no background publishing)'
$taskOut = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Root 'tools\install_tasks.ps1') 2>&1
$taskOut | ForEach-Object { R ('  ' + $_) }

# ---- 5. launch --------------------------------------------------------------
R ''
R '## 5 launch'
try { Start-ScheduledTask -TaskName 'jev-chat-monitor'; R '  Start-ScheduledTask jev-chat-monitor: ok' } catch { R ('  launch failed: ' + $_.Exception.Message) }
Start-Sleep -Seconds 12
$procs = @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object {
    $_.CommandLine -and ($_.CommandLine -match 'jev-chat-windows\\app\\main\.py') })
R ('  app_running=' + ($procs.Count -gt 0) + ' pids=' + (($procs | ForEach-Object { $_.ProcessId }) -join ','))
if (Test-Path -LiteralPath (Join-Path $Root 'logs\app_err.log')) {
    R ('  app_err tail: ' + ((Get-Content -LiteralPath (Join-Path $Root 'logs\app_err.log') -Tail 5 -Encoding UTF8) -join ' | '))
}

# ---- 6. status --------------------------------------------------------------
R ''
R '## 6 status'
$st = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Root 'tools\status.ps1') 2>&1
$st | ForEach-Object { R ('  ' + $_) }

# ---- 7. UI check ------------------------------------------------------------
R ''
R '## 7 ui check (needs a chat window)'
$ui = (& $VPy (Join-Path $Root 'monitor\verify_ui.py') 2>&1) -join "`r`n"
R $ui

# ---- 8. pull ----------------------------------------------------------------
R ''
R '## 8 recorder snapshot'
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Root 'tools\pull_events.ps1') -Tail 500 2>&1 | ForEach-Object { R ('  ' + $_) }

$report | Set-Content -LiteralPath (Join-Path $DstDir ('finalize-' + $Stamp + '.md')) -Encoding UTF8
R ''
R ('wrote results/jev-monitor/finalize-' + $Stamp + '.md')
