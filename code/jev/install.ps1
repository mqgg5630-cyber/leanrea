#Requires -Version 5.1
<#
.SYNOPSIS
    Deploy jev-chat-windows next to a headless monitor, on this Windows host.

.DESCRIPTION
    Runs DETACHED (started by the agent through git-sync-hub) because pip pulls a
    few hundred MB. Everything is appended to logs\install.log and summarised in
    logs\install_status.json so the agent can poll progress over git.

    Layout (Root = E:\0github\apps\jev-chat-windows):
      app\      upstream clone (github.com/jev-chat/jev-chat-windows)
      venv\     python 3.11 virtualenv holding the OCR / Qt / model SDKs
      monitor\  recorder hook + start / sync scripts
      logs\     events.jsonl, digest-*.md, install.log, app_err.log
      sync\     sparse clone of the leanrea branch used to publish results
      tools\    copies of the scripts in this folder

    ASCII only (repo gate). No secrets are written anywhere.
#>
$ErrorActionPreference = 'Continue'
$ProgressPreference    = 'SilentlyContinue'

$Root    = 'E:\0github\apps\jev-chat-windows'
$AppDir  = Join-Path $Root 'app'
$Venv    = Join-Path $Root 'venv'
$Logs    = Join-Path $Root 'logs'
$Tools   = Join-Path $Root 'tools'
$Monitor = Join-Path $Root 'monitor'
$LogFile = Join-Path $Logs 'install.log'
$Status  = Join-Path $Logs 'install_status.json'
$Mirror  = 'https://pypi.tuna.tsinghua.edu.cn/simple'

foreach ($d in @($Root, $Logs, $Tools)) {
    if (-not (Test-Path -LiteralPath $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}

function Log([string]$m) {
    $line = '[{0}] {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $m
    Write-Output $line
    try { Add-Content -LiteralPath $LogFile -Value $line -Encoding UTF8 } catch {}
}

function Save-Status([hashtable]$extra) {
    $o = [ordered]@{
        updated_local = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
        host          = $env:COMPUTERNAME
        root          = $Root
    }
    foreach ($k in $extra.Keys) { $o[$k] = $extra[$k] }
    try { ($o | ConvertTo-Json -Depth 6) | Set-Content -LiteralPath $Status -Encoding UTF8 } catch {}
}

# ---------------------------------------------------------------- 1. git + app
Log '== stage 1: upstream clone / update'
$git = (Get-Command git.exe -ErrorAction SilentlyContinue)
if (-not $git) {
    Log 'FATAL: git.exe missing'
    Save-Status @{ ok = $false; stage = 'git'; error = 'git missing' }
    exit 3
}
if (-not (Test-Path -LiteralPath (Join-Path $AppDir '.git'))) {
    Log ('clone -> ' + $AppDir)
    $out = & $git.Source clone --depth 1 https://github.com/jev-chat/jev-chat-windows.git $AppDir 2>&1
    $out | ForEach-Object { Log ('  ' + $_) }
    if (-not (Test-Path -LiteralPath (Join-Path $AppDir 'main.py'))) {
        Log 'FATAL: clone failed'
        Save-Status @{ ok = $false; stage = 'clone'; error = ($out -join ' ') }
        exit 3
    }
} else {
    Log 'app clone already present - refreshing to origin/main'
    $out = & $git.Source -C $AppDir fetch --depth 1 origin main 2>&1
    $out | ForEach-Object { Log ('  ' + $_) }
    $out = & $git.Source -C $AppDir reset --hard FETCH_HEAD 2>&1
    $out | ForEach-Object { Log ('  ' + $_) }
}
$head = (& $git.Source -C $AppDir rev-parse --short HEAD 2>&1) -join ' '
Log ('app_head=' + $head)

# ---------------------------------------------------------------- 2. venv
Log '== stage 2: python 3.11 virtualenv'
$basePy = $null
foreach ($c in @('E:\spider\python.exe', 'C:\Python311\python.exe', 'C:\Python310\python.exe')) {
    if (Test-Path -LiteralPath $c) { $basePy = $c; break }
}
if (-not $basePy) {
    $cmd = Get-Command python.exe -ErrorAction SilentlyContinue
    if ($cmd) { $basePy = $cmd.Source }
}
if (-not $basePy) {
    Log 'FATAL: no python found'
    Save-Status @{ ok = $false; stage = 'python'; error = 'no python' }
    exit 3
}
$pyVer = (& $basePy -c "import sys;print('%d.%d.%d' % sys.version_info[:3])" 2>&1) -join ''
Log ('base_python=' + $basePy + ' version=' + $pyVer)
if ($pyVer -match '^3\.(1[3-9]|[2-9][0-9])') {
    Log 'WARN: rapidocr-onnxruntime needs python < 3.13; falling back to py -3.11 if available'
}

$VPy = Join-Path $Venv 'Scripts\python.exe'
if (-not (Test-Path -LiteralPath $VPy)) {
    Log 'creating venv'
    $out = & $basePy -m venv $Venv 2>&1
    $out | ForEach-Object { Log ('  ' + $_) }
}
if (-not (Test-Path -LiteralPath $VPy)) {
    Log 'FATAL: venv creation failed'
    Save-Status @{ ok = $false; stage = 'venv'; error = 'venv failed' }
    exit 3
}
Log ('venv_python=' + ((& $VPy -c "import sys;print(sys.version.split()[0])" 2>&1) -join ''))

# ---------------------------------------------------------------- 3. deps
Log '== stage 3: pip install (this is the slow one, few hundred MB)'
$env:PIP_DISABLE_PIP_VERSION_CHECK = '1'
$env:PIP_NO_INPUT = '1'
$req = Join-Path $AppDir 'requirements.txt'
$pipArgs = @('-m', 'pip', 'install', '--no-input', '-r', $req)
Log 'pip install -r requirements.txt (mirror: tuna)'
$out = & $VPy @pipArgs -i $Mirror 2>&1
$code = $LASTEXITCODE
$out | ForEach-Object { Log ('  ' + $_) }
if ($code -ne 0) {
    Log ('mirror install failed (exit ' + $code + ') - retrying against pypi.org')
    $out = & $VPy @pipArgs 2>&1
    $code = $LASTEXITCODE
    $out | ForEach-Object { Log ('  ' + $_) }
}
Log ('pip_exit=' + $code)

# ---------------------------------------------------------------- 4. monitor hook
Log '== stage 4: install the monitor hook into app/main.py'
if (Test-Path -LiteralPath (Join-Path $Monitor 'patch_main.py')) {
    $out = & $VPy (Join-Path $Monitor 'patch_main.py') $Root 2>&1
    $out | ForEach-Object { Log ('  ' + $_) }
} else {
    Log 'WARN: monitor\patch_main.py missing - the app will run without recording'
}

# ---------------------------------------------------------------- 5. import test
Log '== stage 5: import / engine self-tests'
$imports = [ordered]@{}
foreach ($mod in @('numpy', 'rapidocr_onnxruntime', 'PySide6', 'windows_capture', 'openai',
                   'anthropic', 'google.genai', 'winsdk')) {
    $r = & $VPy -c "import $mod; print('ok')" 2>&1
    $ok = (($r -join ' ') -match 'ok')
    $imports[$mod] = $ok
    Log ('  import ' + $mod + ' = ' + $ok)
}
Push-Location $AppDir
$engineTest = (& $VPy 'core\engine.py' 2>&1) -join ' '
$chatappTest = (& $VPy 'app\chatapps.py' 2>&1) -join ' '
Pop-Location
Log ('  core/engine.py self-test: ' + $engineTest)
Log ('  app/chatapps.py self-test: ' + $chatappTest)

# ---------------------------------------------------------------- 6. OCR warm-up
Log '== stage 6: rapidocr model warm-up (first run may download models)'
$ocr = (& $VPy -c "from rapidocr_onnxruntime import RapidOCR; e=RapidOCR(); print('OCR_OK')" 2>&1) -join ' '
Log ('  ' + $ocr)

$okAll = ($code -eq 0) -and ($imports['rapidocr_onnxruntime'] -eq $true) -and ($imports['PySide6'] -eq $true) -and ($ocr -match 'OCR_OK')
Save-Status @{
    ok          = $okAll
    stage       = 'done'
    app_head    = $head
    base_python = $basePy
    venv_python = $VPy
    pip_exit    = $code
    imports     = $imports
    ocr         = $ocr
    engine_test = $engineTest
}

# ---------------------------------------------------------------- 7. scheduled tasks
Log '== stage 7: scheduled tasks (autostart + 5-minute publish)'
$taskScript = Join-Path $Tools 'install_tasks.ps1'
if (Test-Path -LiteralPath $taskScript) {
    $out = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $taskScript 2>&1
    $out | ForEach-Object { Log ('  ' + $_) }
} else {
    Log 'WARN: tools\install_tasks.ps1 missing'
}

Log ('== DONE ok=' + $okAll)
