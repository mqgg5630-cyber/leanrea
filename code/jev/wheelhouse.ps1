#Requires -Version 5.1
<#
.SYNOPSIS
    Reliable dependency install for the JevChat venv: curl a verified wheelhouse,
    then let pip install offline.

.DESCRIPTION
    Why: pip's own downloads through the local v2rayN proxy (127.0.0.1:18088) get
    corrupted ("THESE PACKAGES DO NOT MATCH THE HASHES"), while curl through the
    same proxy returns byte-identical files (verified: rapidocr wheel sha256
    971d7d5f... matched). Direct mirror access is clean but 4x slower.

    Steps
      1. pip --dry-run --report -> the exact wheel list + sha256 pip would install
      2. curl each wheel (proxy, 3 attempts, sha256 checked) into wheelhouse\
      3. pip install --no-index --find-links wheelhouse -r requirements.txt
      4. import / OCR warm-up verification -> logs\pip_status.json

    Detached; progress in logs\wheelhouse.log. ASCII only.
#>
param(
    [switch]$NoProxy
)
$ErrorActionPreference = 'Continue'
$ProgressPreference    = 'SilentlyContinue'

$Root   = 'E:\0apps\jev-chat-windows'
$Logs   = Join-Path $Root 'logs'
$Wh     = Join-Path $Root 'wheelhouse'
$Log    = Join-Path $Logs 'wheelhouse.log'
$Status = Join-Path $Logs 'pip_status.json'
$Report = Join-Path $Logs 'wheels.json'
$VPy    = Join-Path $Root 'venv\Scripts\python.exe'
$Req    = Join-Path $Root 'app\requirements.txt'
$Index  = 'https://mirrors.aliyun.com/pypi/simple/'

foreach ($d in @($Logs, $Wh)) { if (-not (Test-Path -LiteralPath $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null } }

function Log([string]$m) {
    $line = '[{0}] wheelhouse: {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $m
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

if (-not (Test-Path -LiteralPath $VPy)) { Log 'FATAL: no venv python'; exit 3 }
if (-not (Test-Path -LiteralPath $Req)) { Log ('FATAL: no ' + $Req); exit 3 }

$env:PIP_DISABLE_PIP_VERSION_CHECK = '1'
$env:PIP_NO_INPUT = '1'
$env:PIP_PROGRESS_BAR = 'off'
Save-Status @{ ok = $false; stage = 'resolve'; note = 'started' }

# ---------------------------------------------------------------- 1. resolve
Log 'resolving the wheel list with pip --dry-run --report'
if (Test-Path -LiteralPath $Report) { Remove-Item -LiteralPath $Report -Force -ErrorAction SilentlyContinue }
$args = @('-m', 'pip', 'install', '--dry-run', '--ignore-installed', '--only-binary=:all:',
          '--report', $Report, '-r', $Req, '-i', $Index, '--trusted-host', ([Uri]$Index).Host)
$out = & $VPy @args 2>&1
$code = $LASTEXITCODE
$out | Select-Object -Last 6 | ForEach-Object { Log ('  ' + $_) }
Log ('resolve exit=' + $code)

$items = @()
if (Test-Path -LiteralPath $Report) {
    try {
        $rep = Get-Content -LiteralPath $Report -Raw -Encoding UTF8 | ConvertFrom-Json
        foreach ($inst in @($rep.install)) {
            $url = $inst.download_info.url
            if (-not $url) { continue }
            $sha = ''
            try { $sha = $inst.download_info.archive_info.hashes.sha256 } catch {}
            $items += [pscustomobject]@{
                name = $inst.metadata.name
                url  = $url
                file = Split-Path -Leaf ([Uri]$url).AbsolutePath
                sha  = ([string]$sha).ToLower()
            }
        }
    } catch { Log ('WARN: report parse failed: ' + $_.Exception.Message) }
}
Log ('wheels_to_fetch=' + $items.Count)
if ($items.Count -eq 0) {
    Log 'FATAL: nothing to fetch (is the resolver reachable?)'
    Save-Status @{ ok = $false; stage = 'resolve'; note = 'empty wheel list' }
    exit 2
}

# ---------------------------------------------------------------- 2. curl
function Fetch([string]$url, [string]$file, [string]$wantSha) {
    $target = Join-Path $Wh $file
    if ((Test-Path -LiteralPath $target) -and $wantSha) {
        $have = (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash.ToLower()
        if ($have -eq $wantSha) { Log ('  cached ' + $file); return $true }
    }
    for ($i = 1; $i -le 3; $i++) {
        if (Test-Path -LiteralPath $target) { Remove-Item -LiteralPath $target -Force -ErrorAction SilentlyContinue }
        $curlArgs = @('-sS', '--http1.1', '-L', '--connect-timeout', '20', '--max-time', '900', '-o', $target)
        if ($proxySaved) { $curlArgs += @('-x', $proxySaved) }
        $curlArgs += $url
        & curl.exe @curlArgs 2>&1 | ForEach-Object { Log ('  curl: ' + $_) }
        if (Test-Path -LiteralPath $target) {
            if (-not $wantSha) { Log ('  got ' + $file); return $true }
            $got = (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash.ToLower()
            if ($got -eq $wantSha) { Log ('  ok ' + $file + ' (' + [int]((Get-Item $target).Length / 1KB) + ' KB)'); return $true }
            Log ('  hash mismatch ' + $file + ' attempt ' + $i)
        }
    }
    return $false
}

$badWheels = @()
foreach ($it in $items) {
    if (-not (Fetch $it.url $it.file $it.sha)) { $badWheels += $it.file }
}
Log ('fetched=' + ($items.Count - $badWheels.Count) + ' failed=' + $badWheels.Count)

# ---------------------------------------------------------------- 3. offline install
Save-Status @{ ok = $false; stage = 'install'; note = ('wheels=' + $items.Count + ' failed=' + $badWheels.Count) }
Log 'pip install --no-index --find-links wheelhouse'
$args2 = @('-m', 'pip', 'install', '--no-input', '--no-index', '--find-links', $Wh, '-r', $Req)
$out = & $VPy @args2 2>&1
$code2 = $LASTEXITCODE
$out | Select-Object -Last 8 | ForEach-Object { Log ('  ' + $_) }
Log ('offline install exit=' + $code2)

# ---------------------------------------------------------------- 4. verify
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

$okAll = ($code2 -eq 0) -and ($badWheels.Count -eq 0) -and ($probe['rapidocr_onnxruntime'] -eq $true) -and ($probe['PySide6'] -eq $true) -and ($ocr -match 'OCR_OK')
Save-Status @{
    ok         = $okAll
    stage      = 'done'
    wheels     = $items.Count
    bad_wheels = $badWheels
    install    = $code2
    imports    = $probe
    ocr        = $ocr
}
Log ('DONE ok=' + $okAll)
