#Requires -Version 5.1
<#
.SYNOPSIS
    Pull the model with the proxy bypassed, then fall back to a GGUF from hf-mirror.

.DESCRIPTION
    The v2rayN proxy intercepts ollama's Cloudflare R2 URLs and presents a Google
    certificate, so `ollama pull` dies at 4%. Ollama reads HTTPS_PROXY from the
    environment of the `ollama serve` process - so restart the server with the
    proxy cleared and retry.

    Fallback: download Qwen2.5-3B-Instruct Q4_K_M from hf-mirror (Chinese mirror,
    no proxy needed) and `ollama create jev-cn -f Modelfile`.

    ASCII only.
#>
$ErrorActionPreference = 'Continue'
$ProgressPreference    = 'SilentlyContinue'

$Root   = 'E:\0apps\jev-chat-windows'
$Tools  = 'E:\0apps\tools'
$Logs   = Join-Path $Root 'logs'
$Log    = Join-Path $Logs 'ollama.log'
$Status = Join-Path $Logs 'ollama_status.json'
$Model  = 'qwen2.5:3b'
$Gguf   = Join-Path $Tools 'qwen2.5-3b-instruct-q4_k_m.gguf'

function Log([string]$m) {
    $line = '[{0}] direct: {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $m
    Write-Host $line
    try { Add-Content -LiteralPath $Log -Value $line -Encoding UTF8 } catch {}
}
function Save-Status([hashtable]$h) {
    $o = [ordered]@{ updated_local = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') }
    foreach ($k in $h.Keys) { $o[$k] = $h[$k] }
    try { ($o | ConvertTo-Json -Depth 5) | Set-Content -LiteralPath $Status -Encoding UTF8 } catch {}
}

$exe = "$env:LOCALAPPDATA\Programs\Ollama\ollama.exe"
if (-not (Test-Path -LiteralPath $exe)) { Log 'FATAL: ollama.exe missing'; exit 3 }

# ---------------------------------------------------------------- 1. proxy-free server
Get-Process ollama,'ollama app' -ErrorAction SilentlyContinue | ForEach-Object {
    Log ('stopping ' + $_.ProcessName + ' pid ' + $_.Id)
    Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
}
Start-Sleep -Seconds 3
$env:HTTP_PROXY = ''
$env:HTTPS_PROXY = ''
$env:ALL_PROXY = ''
$env:NO_PROXY = '*'
$env:OLLAMA_KEEP_ALIVE = '30m'
Start-Process -FilePath $exe -ArgumentList 'serve' -WindowStyle Hidden `
    -RedirectStandardOutput (Join-Path $Logs 'ollama_serve.out') `
    -RedirectStandardError (Join-Path $Logs 'ollama_serve.err')
for ($i = 0; $i -lt 40; $i++) {
    Start-Sleep -Seconds 2
    try { if ((Invoke-WebRequest -Uri 'http://127.0.0.1:11434/api/tags' -UseBasicParsing -TimeoutSec 3).StatusCode -eq 200) { break } } catch {}
}
Log 'server restarted with proxy cleared'
Save-Status @{ ok = $false; stage = 'pull-direct'; model = $Model }

# ---------------------------------------------------------------- 2. pull
$out = & $exe pull $Model 2>&1
$out | Select-Object -Last 4 | ForEach-Object { Log ('  ' + $_) }
$pullOk = ($LASTEXITCODE -eq 0)
Log ('pull-direct ok=' + $pullOk)

# ---------------------------------------------------------------- 3. GGUF fallback
if (-not $pullOk) {
    $url = 'https://hf-mirror.com/Qwen/Qwen2.5-3B-Instruct-GGUF/resolve/main/qwen2.5-3b-instruct-q4_k_m.gguf'
    Log 'fallback: GFW-friendly mirror download (resumable)'
    for ($i = 1; $i -le 40; $i++) {
        $have = (Get-Item $Gguf -ErrorAction SilentlyContinue).Length
        if ($have -gt 1800MB) { break }
        & curl.exe -sS -L --ssl-no-revoke -k -C - --connect-timeout 20 --max-time 300 `
            --retry 2 --retry-all-errors -o $Gguf $url 2>&1 | Out-Null
        $now = (Get-Item $Gguf -ErrorAction SilentlyContinue).Length
        Log ('  gguf mb=' + [math]::Round($now / 1MB) + ' (round ' + $i + ')')
        if ($now -eq $have) { Start-Sleep -Seconds 5 }
    }
    $size = (Get-Item $Gguf -ErrorAction SilentlyContinue).Length
    Log ('gguf size=' + [math]::Round($size / 1MB) + ' MB')
    if ($size -gt 1800MB) {
        $mf = Join-Path $Tools 'Modelfile.qwen'
        "FROM `"$Gguf`"`nPARAMETER temperature 0.4`nPARAMETER num_predict 700" |
            Set-Content -LiteralPath $mf -Encoding UTF8
        $outc = & $exe create jev-cn -f $mf 2>&1
        $outc | Select-Object -Last 3 | ForEach-Object { Log ('  ' + $_) }
        if ($LASTEXITCODE -eq 0) { $Model = 'jev-cn'; Log 'model jev-cn created from GGUF' }
    }
}

# ---------------------------------------------------------------- 4. smoke
$body = @{ model = $Model; stream = $false; keep_alive = '30m'
           messages = @(@{ role = 'user'; content = 'reply with this JSON only: {"ok":true}' }) } |
        ConvertTo-Json -Depth 5 -Compress
$reply = ''
$sw = [Diagnostics.Stopwatch]::StartNew()
try {
    $r = Invoke-RestMethod -Uri 'http://127.0.0.1:11434/api/chat' -Method Post -Body $body `
            -ContentType 'application/json; charset=utf-8' -TimeoutSec 300
    $reply = [string]$r.message.content
} catch { $reply = 'ERROR: ' + $_.Exception.Message }
$sw.Stop()
Log ('smoke (' + [int]$sw.Elapsed.TotalSeconds + 's) = ' + ($reply -replace '\s+', ' '))

$ok = $reply -match '\{'
Save-Status @{ ok = $ok; stage = 'done'; model = $Model; exe = $exe
               smoke = ($reply -replace '\s+', ' '); smoke_ms = [int]$sw.Elapsed.TotalMilliseconds }
Log ('DONE ok=' + $ok + ' model=' + $Model)
