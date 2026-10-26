#Requires -Version 5.1
<#
.SYNOPSIS
    Detached dependency installer for the JevChat venv (hybrid network strategy).

.DESCRIPTION
    The host reaches the internet through a local v2rayN proxy (127.0.0.1:18088):
    fast for bulk (~2 MB/s) but it intermittently corrupts large wheels, which pip
    reports as "THESE PACKAGES DO NOT MATCH THE HASHES". Domestic mirrors without
    the proxy are reliable but slow (~80 KB/s).

    So: for every package, try the proxy first (2 attempts, mirror list), then fall
    back to a direct mirror download with the proxy cleared. Cache stays ON so a
    good download is never repeated. Everything lands in logs\pip.log; state in
    logs\pip_status.json. Runs detached because no hub step may exceed 120 s.
    ASCII only.
#>
param(
    [switch]$NoProxy
)
$ErrorActionPreference = 'Continue'
$ProgressPreference    = 'SilentlyContinue'

$Root   = 'E:\0apps\jev-chat-windows'
$Logs   = Join-Path $Root 'logs'
$Log    = Join-Path $Logs 'pip.log'
$Status = Join-Path $Logs 'pip_status.json'
$VPy    = Join-Path $Root 'venv\Scripts\python.exe'

if (-not (Test-Path -LiteralPath $Logs)) { New-Item -ItemType Directory -Path $Logs -Force | Out-Null }

function Log([string]$m) {
    $line = '[{0}] pip_worker: {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $m
    Write-Host $line   # host stream only: Log() must never leak into $x = Pip-Try ...
    try { Add-Content -LiteralPath $Log -Value $line -Encoding UTF8 } catch {}
}
function Save-Status([hashtable]$h) {
    $o = [ordered]@{ updated_local = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') }
    foreach ($k in $h.Keys) { $o[$k] = $h[$k] }
    try { ($o | ConvertTo-Json -Depth 5) | Set-Content -LiteralPath $Status -Encoding UTF8 } catch {}
}

if (-not (Test-Path -LiteralPath $VPy)) {
    Log 'FATAL: venv python missing'
    Save-Status @{ ok = $false; stage = 'venv'; note = 'missing venv python' }
    exit 3
}

$proxySaved = $env:HTTPS_PROXY
if (-not $proxySaved) { $proxySaved = $env:HTTP_PROXY }
$env:PIP_DISABLE_PIP_VERSION_CHECK = '1'
$env:PIP_NO_INPUT = '1'
$env:PIP_PROGRESS_BAR = 'off'
if ($NoProxy) { $proxySaved = '' }

function Use-Proxy {
    if ($proxySaved) {
        $env:HTTP_PROXY  = $proxySaved
        $env:HTTPS_PROXY = $proxySaved
        $env:NO_PROXY    = ''
    }
}
function Use-Direct {
    $env:HTTP_PROXY  = ''
    $env:HTTPS_PROXY = ''
    $env:ALL_PROXY   = ''
    $env:NO_PROXY    = '*'
}

if ($NoProxy) { Use-Direct; Log 'started in direct mode (proxy disabled)' }
else { Use-Proxy; Log ('started, proxy=' + $proxySaved) }

$Indexes = @(
    'https://mirrors.aliyun.com/pypi/simple/',
    'https://pypi.tuna.tsinghua.edu.cn/simple',
    'https://mirrors.ustc.edu.cn/pypi/simple'
)

function Pip-Try([string]$pkg, [string]$idx, [int]$attempt) {
    $host_ = ([Uri]$idx).Host
    Log ('install ' + $pkg + ' via ' + $host_ + ' attempt ' + $attempt + ' proxy=' + [bool]$env:HTTPS_PROXY)
    $a = @('-m', 'pip', 'install', '--no-input', '--timeout', '45', '--retries', '1',
           '-i', $idx, '--trusted-host', $host_, $pkg)
    $out = & $VPy @a 2>&1
    $code = $LASTEXITCODE
    $out | Select-Object -Last 4 | ForEach-Object { Log ('  ' + $_) }
    Log ('  exit=' + $code)
    return ($code -eq 0)
}

$Packages = @(
    'numpy',
    'rapidocr-onnxruntime>=1.4,<2',
    'windows-capture',
    'pillow',
    'PySide6-Fluent-Widgets',
    'openai',
    'typesafe-sdk',
    'anthropic',
    'google-genai',
    'winsdk'
)

Save-Status @{ ok = $false; stage = 'running'; note = 'started' }
$failed = @()

foreach ($pkg in $Packages) {
    $done = $false

    # 1) proxy, two passes over the mirror list
    if (-not $NoProxy) {
        Use-Proxy
        foreach ($attempt in 1, 2) {
            if ($done) { break }
            foreach ($idx in $Indexes) {
                if ($done) { break }
                $done = Pip-Try $pkg $idx $attempt
            }
        }
    }

    # 2) direct mirror, slower but clean
    if (-not $done) {
        Use-Direct
        foreach ($idx in $Indexes) {
            if ($done) { break }
            $done = Pip-Try $pkg $idx 1
        }
    }

    if (-not $done) { $failed += $pkg; Log ('FAILED: ' + $pkg) }
    else { Log ('OK: ' + $pkg) }
}

Use-Proxy
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

$okAll = ($failed.Count -eq 0) -and ($probe['rapidocr_onnxruntime'] -eq $true) -and ($probe['PySide6'] -eq $true) -and ($ocr -match 'OCR_OK')
Save-Status @{
    ok      = $okAll
    stage   = 'done'
    failed  = $failed
    imports = $probe
    ocr     = $ocr
}
Log ('DONE ok=' + $okAll + ' failed=' + ($failed -join ','))
