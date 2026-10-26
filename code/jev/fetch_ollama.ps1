#Requires -Version 5.1
<#
.SYNOPSIS
    Robust, resumable installer for the local analysis model (no API key).

.DESCRIPTION
    The host reaches GitHub through a flaky local proxy: long downloads die with
    "server closed abruptly (missing close_notify)". So: curl with --ssl-no-revoke,
    -C - resume, --retry-all-errors, in a loop until the byte count matches.
    Model: registry pull first (qwen2.5:3b); if that stalls, fall back to a GGUF
    from hf-mirror.com and `ollama create`.

    Detached. Progress logs\ollama.log, state logs\ollama_status.json. ASCII only.
#>
$ErrorActionPreference = 'Continue'
$ProgressPreference    = 'SilentlyContinue'

$Root   = 'E:\0apps\jev-chat-windows'
$Tools  = 'E:\0apps\tools'
$Logs   = Join-Path $Root 'logs'
$Log    = Join-Path $Logs 'ollama.log'
$Status = Join-Path $Logs 'ollama_status.json'
$Setup  = Join-Path $Tools 'OllamaSetup.exe'
$Url    = 'https://github.com/ollama/ollama/releases/latest/download/OllamaSetup.exe'
$Model  = 'qwen2.5:3b'
$Proxy  = $env:HTTPS_PROXY
if (-not $Proxy) { $Proxy = $env:HTTP_PROXY }

foreach ($d in @($Tools, $Logs)) { if (-not (Test-Path -LiteralPath $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null } }

function Log([string]$m) {
    $line = '[{0}] fetch_ollama: {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $m
    Write-Host $line
    try { Add-Content -LiteralPath $Log -Value $line -Encoding UTF8 } catch {}
}
function Save-Status([hashtable]$h) {
    $o = [ordered]@{ updated_local = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') }
    foreach ($k in $h.Keys) { $o[$k] = $h[$k] }
    try { ($o | ConvertTo-Json -Depth 5) | Set-Content -LiteralPath $Status -Encoding UTF8 } catch {}
}

# ---------------------------------------------------------------- 1. download
$want = 1585MB
$ok = $false
if ((Test-Path -LiteralPath $Setup) -and ((Get-Item $Setup).Length -gt ($want - 20MB))) {
    Log 'installer already complete'
    $ok = $true
}
$attempt = 0
while (-not $ok -and $attempt -lt 60) {
    $attempt++
    Save-Status @{ ok = $false; stage = 'download'; attempt = $attempt
                   mb = [math]::Round((Get-Item $Setup -ErrorAction SilentlyContinue).Length / 1MB, 1) }
    $a = @('-sS', '-L', '--http1.1', '--ssl-no-revoke', '-k', '-C', '-',
           '--connect-timeout', '20', '--max-time', '600', '--retry', '3', '--retry-all-errors',
           '-o', $Setup)
    if ($Proxy) { $a = @('-x', $Proxy) + $a }
    $a += $Url
    & curl.exe @a 2>&1 | Select-Object -Last 2 | ForEach-Object { Log ('  ' + $_) }
    $size = (Get-Item $Setup -ErrorAction SilentlyContinue).Length
    Log ('attempt ' + $attempt + ' size=' + [math]::Round($size / 1MB, 1) + ' MB')
    if ($size -gt ($want - 20MB)) { $ok = $true }
    else { Start-Sleep -Seconds 3 }
}
if (-not $ok) {
    Log 'FATAL: could not download the installer'
    Save-Status @{ ok = $false; stage = 'download'; note = 'download failed' }
    exit 3
}

# ---------------------------------------------------------------- 2. install
Log 'silent install'
$p = Start-Process -FilePath $Setup -ArgumentList '/VERYSILENT', '/NORESTART', '/SUPPRESSMSGBOXES' -PassThru -Wait
Log ('installer exit=' + $p.ExitCode)

$exe = $null
foreach ($c in @("$env:LOCALAPPDATA\Programs\Ollama\ollama.exe",
                 "$env:LOCALAPPDATA\Ollama\ollama.exe",
                 'C:\Program Files\Ollama\ollama.exe')) {
    if (Test-Path -LiteralPath $c) { $exe = $c; break }
}
if (-not $exe) { Log 'FATAL: ollama.exe missing'; Save-Status @{ ok = $false; stage = 'install' }; exit 3 }
Log ('exe=' + $exe)

# ---------------------------------------------------------------- 3. service
function Service-Up {
    try {
        $r = Invoke-WebRequest -Uri 'http://127.0.0.1:11434/api/tags' -UseBasicParsing -TimeoutSec 4
        return ($r.StatusCode -eq 200)
    } catch { return $false }
}
if (-not (Service-Up)) {
    Log 'starting service'
    Start-Process -FilePath $exe -ArgumentList 'serve' -WindowStyle Hidden `
        -RedirectStandardOutput (Join-Path $Logs 'ollama_serve.out') `
        -RedirectStandardError (Join-Path $Logs 'ollama_serve.err')
    for ($i = 0; $i -lt 30; $i++) { Start-Sleep -Seconds 2; if (Service-Up) { break } }
}
Log ('service_up=' + (Service-Up))

# ---------------------------------------------------------------- 4. model
Save-Status @{ ok = $false; stage = 'pull'; model = $Model }
Log ('pulling ' + $Model)
$env:OLLAMA_KEEP_ALIVE = '30m'
$out = & $exe pull $Model 2>&1
$out | Select-Object -Last 5 | ForEach-Object { Log ('  ' + $_) }
$pullOk = ($LASTEXITCODE -eq 0)
Log ('pull ok=' + $pullOk)

if (-not $pullOk) {
    # GGUF fallback from the Chinese HuggingFace mirror (fast, no proxy needed)
    $gguf = Join-Path $Tools 'qwen2.5-3b-instruct-q4_k_m.gguf'
    $gurl = 'https://hf-mirror.com/Qwen/Qwen2.5-3B-Instruct-GGUF/resolve/main/qwen2.5-3b-instruct-q4_k_m.gguf'
    Log 'fallback: GGUF from hf-mirror'
    for ($i = 1; $i -le 10; $i++) {
        & curl.exe -sS -L --ssl-no-revoke -k -C - --connect-timeout 20 --max-time 1800 --retry 3 --retry-all-errors -o $gguf $gurl 2>&1 |
            Select-Object -Last 1 | ForEach-Object { Log ('  ' + $_) }
        if ((Get-Item $gguf -ErrorAction SilentlyContinue).Length -gt 1500MB) { break }
    }
    if ((Test-Path -LiteralPath $gguf) -and ((Get-Item $gguf).Length -gt 1500MB)) {
        $mf = Join-Path $Tools 'Modelfile.qwen'
        "FROM `"$gguf`"`nPARAMETER temperature 0.4`nPARAMETER num_predict 700" |
            Set-Content -LiteralPath $mf -Encoding UTF8
        Log 'creating ollama model jev-cn from GGUF'
        $out = & $exe create jev-cn -f $mf 2>&1
        $out | Select-Object -Last 4 | ForEach-Object { Log ('  ' + $_) }
        if ($LASTEXITCODE -eq 0) { $Model = 'jev-cn'; Log 'model jev-cn created' }
    } else {
        Log 'FATAL: neither the registry pull nor the GGUF fallback worked'
        Save-Status @{ ok = $false; stage = 'pull'; note = 'no model' }
        exit 3
    }
}

# ---------------------------------------------------------------- 5. smoke
$body = @{ model = $Model; stream = $false
           messages = @(@{ role = 'user'; content = 'reply with this JSON only: {"ok":true}' }) } |
        ConvertTo-Json -Depth 5 -Compress
$reply = ''
try {
    $r = Invoke-RestMethod -Uri 'http://127.0.0.1:11434/api/chat' -Method Post -Body $body `
            -ContentType 'application/json; charset=utf-8' -TimeoutSec 240
    $reply = [string]$r.message.content
} catch { $reply = 'ERROR: ' + $_.Exception.Message }
Log ('smoke=' + ($reply -replace '\s+', ' '))

$okAll = $reply -match '\{'
Save-Status @{ ok = $okAll; stage = 'done'; model = $Model; exe = $exe
               smoke = ($reply -replace '\s+', ' ') }
Log ('DONE ok=' + $okAll + ' model=' + $Model)
