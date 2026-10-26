#Requires -Version 5.1
<#
.SYNOPSIS
    Fast, verified dependency install using uv (parallel downloads) instead of pip.

.DESCRIPTION
    pip on this host is single-connection (~200 KB/s through the local proxy, and
    the proxy corrupts large wheels so pip has to go direct) which makes PySide6 a
    30+ minute job. uv fetches in parallel, so we install uv with pip once
    (--user, separate environment, no race with the app venv), then let uv install
    the requirements with 16 connections.

    Detached; progress in logs\uv.log; state in logs\pip_status.json. ASCII only.
#>
param(
    [switch]$NoProxy
)
$ErrorActionPreference = 'Continue'
$ProgressPreference    = 'SilentlyContinue'

$Root   = 'E:\0apps\jev-chat-windows'
$Logs   = Join-Path $Root 'logs'
$Log    = Join-Path $Logs 'uv.log'
$Status = Join-Path $Logs 'pip_status.json'
$VPy    = Join-Path $Root 'venv\Scripts\python.exe'
$Req    = Join-Path $Root 'app\requirements.txt'
$SysPy  = 'E:\spider\python.exe'
$Index  = 'https://mirrors.aliyun.com/pypi/simple/'

if (-not (Test-Path -LiteralPath $Logs)) { New-Item -ItemType Directory -Path $Logs -Force | Out-Null }

function Log([string]$m) {
    $line = '[{0}] uv_install: {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $m
    Write-Host $line
    try { Add-Content -LiteralPath $Log -Value $line -Encoding UTF8 } catch {}
}
function Save-Status([hashtable]$h) {
    $o = [ordered]@{ updated_local = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') }
    foreach ($k in $h.Keys) { $o[$k] = $h[$k] }
    try { ($o | ConvertTo-Json -Depth 5) | Set-Content -LiteralPath $Status -Encoding UTF8 } catch {}
}

$proxySaved = $env:HTTPS_PROXY
if (-not $proxySaved) { $proxySaved = $env:HTTP_PROXY }
if ($NoProxy) { $proxySaved = '' }
$env:HTTP_PROXY  = ''
$env:HTTPS_PROXY = ''
$env:ALL_PROXY   = ''
$env:NO_PROXY    = '*'
$env:UV_HTTP_TIMEOUT = '60'
$env:PIP_DISABLE_PIP_VERSION_CHECK = '1'

Save-Status @{ ok = $false; stage = 'uv'; note = 'started' }

# ---- 1. stop the slow pip run ------------------------------------------------
Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object {
    $_.CommandLine -and ($_.CommandLine -like '*-m pip*jev-chat-windows*' -or $_.CommandLine -like '*pip_worker*')
} | ForEach-Object { Log ('stopping slow pip pid ' + $_.ProcessId); Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
Start-Sleep -Seconds 2

# ---- 2. get uv --------------------------------------------------------------
$uv = $null
foreach ($c in @(
    "$env:APPDATA\Python\Python311\Scripts\uv.exe",
    "$env:USERPROFILE\.local\bin\uv.exe",
    "$env:LOCALAPPDATA\Programs\uv\uv.exe"
)) { if (Test-Path -LiteralPath $c) { $uv = $c; break } }
if (-not $uv) {
    $cmd = Get-Command uv.exe -ErrorAction SilentlyContinue
    if ($cmd) { $uv = $cmd.Source }
}

if (-not $uv) {
    Log 'installing uv with pip --user (single ~15 MB wheel)'
    $out = & $SysPy -m pip install --user --no-input --no-cache-dir --timeout 60 --retries 3 `
             -i $Index --trusted-host ([Uri]$Index).Host uv 2>&1
    $out | Select-Object -Last 5 | ForEach-Object { Log ('  ' + $_) }
    foreach ($c in @("$env:APPDATA\Python\Python311\Scripts\uv.exe", "$env:USERPROFILE\.local\bin\uv.exe")) {
        if (Test-Path -LiteralPath $c) { $uv = $c; break }
    }
    if (-not $uv) {
        $cmd = Get-Command uv.exe -ErrorAction SilentlyContinue
        if ($cmd) { $uv = $cmd.Source }
    }
}
if (-not $uv) {
    Log 'FATAL: uv not available'
    Save-Status @{ ok = $false; stage = 'uv'; note = 'uv install failed' }
    exit 3
}
Log ('uv=' + $uv + ' version=' + ((& $uv --version 2>&1) -join ' '))

# ---- 3. install the requirements with uv -----------------------------------
Log 'uv pip install -r requirements.txt (16 connections, direct mirror)'
$uvArgs = @('pip', 'install', '--python', $VPy, '-r', $Req,
            '--index-url', $Index, '--index-strategy', 'unsafe-best-match',
            '--no-cache')
$out = & $uv @uvArgs 2>&1
$code = $LASTEXITCODE
$out | Select-Object -Last 15 | ForEach-Object { Log ('  ' + $_) }
Log ('uv exit=' + $code)

# ---- 4. verify --------------------------------------------------------------
$probe = [ordered]@{}
foreach ($mod in @('numpy', 'rapidocr_onnxruntime', 'PySide6', 'windows_capture', 'openai',
                   'anthropic', 'google.genai', 'winsdk')) {
    $r = & $VPy -c "import $mod; print('ok')" 2>&1
    $probe[$mod] = ((($r -join ' ') -match 'ok'))
}
Log ('imports: ' + (($probe.Keys | ForEach-Object { $_ + '=' + $probe[$_] }) -join ' '))
$ocr = ''
try { $ocr = (& $VPy -c "from rapidocr_onnxruntime import RapidOCR; RapidOCR(); print('OCR_OK')" 2>&1) -join ' ' } catch {}
Log ('ocr_warmup: ' + $ocr)

$okAll = ($probe['rapidocr_onnxruntime'] -eq $true) -and ($probe['PySide6'] -eq $true) -and ($ocr -match 'OCR_OK')
Save-Status @{ ok = $okAll; stage = 'done'; uv_exit = $code; imports = $probe; ocr = $ocr }
Log ('DONE ok=' + $okAll)
