#Requires -Version 5.1
<#
.SYNOPSIS
    Detached dependency installer for the JevChat venv.

.DESCRIPTION
    Started in the background by install.ps1 (or by hand) because a full install
    pulls a few hundred MB and no hub step may run longer than 120 s.
    Strategy: two package groups x four indexes x two attempts, proxy bypassed for
    domestic mirrors (the local v2rayN proxy was corrupting wheel downloads),
    everything appended to logs\pip.log, state in logs\pip_status.json.
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
    Write-Output $line
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

if ($NoProxy) {
    $env:HTTP_PROXY = ''
    $env:HTTPS_PROXY = ''
    $env:ALL_PROXY = ''
    $env:NO_PROXY = '*'
    Log 'proxy environment cleared for this process'
} else {
    Log ('proxy in use: HTTP_PROXY=' + $env:HTTP_PROXY)
}
$env:PIP_DISABLE_PIP_VERSION_CHECK = '1'
$env:PIP_NO_INPUT = '1'

$Indexes = @(
    'https://mirrors.aliyun.com/pypi/simple/',
    'https://pypi.tuna.tsinghua.edu.cn/simple',
    'https://mirrors.ustc.edu.cn/pypi/simple',
    'https://pypi.org/simple'
)
$Groups = [ordered]@{
    core = @('numpy', 'rapidocr-onnxruntime>=1.4,<2', 'windows-capture', 'PySide6-Fluent-Widgets', 'pillow')
    sdk  = @('openai', 'typesafe-sdk', 'anthropic', 'google-genai', 'winsdk')
}

Save-Status @{ ok = $false; stage = 'running'; note = 'started' }
$failed = [ordered]@{}

foreach ($gname in $Groups.Keys) {
    $pkgs = $Groups[$gname]
    $done = $false
    foreach ($idx in $Indexes) {
        if ($done) { break }
        $host_ = ([Uri]$idx).Host
        for ($attempt = 1; $attempt -le 2; $attempt++) {
            if ($done) { break }
            Log ('group=' + $gname + ' index=' + $host_ + ' attempt=' + $attempt + ' pkgs=' + ($pkgs -join ','))
            $pipArgs = @('-m', 'pip', 'install', '--no-input', '--no-cache-dir',
                         '--timeout', '60', '--retries', '2', '-i', $idx, '--trusted-host', $host_) + $pkgs
            $out = & $VPy @pipArgs 2>&1
            $code = $LASTEXITCODE
            $out | Select-Object -Last 6 | ForEach-Object { Log ('  ' + $_) }
            Log ('  exit=' + $code)
            if ($code -eq 0) { $done = $true }
            else { Start-Sleep -Seconds 3 }
        }
    }
    if (-not $done) { $failed[$gname] = $pkgs }
}

# ---- verification: what actually imports now --------------------------------
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

$okAll = ($failed.Count -eq 0) -and ($probe['rapidocr_onnxruntime'] -eq $true) -and ($probe['PySide6'] -eq $true)
Save-Status @{
    ok      = $okAll
    stage   = 'done'
    failed  = $failed
    imports = $probe
    ocr     = $ocr
}
Log ('DONE ok=' + $okAll)
