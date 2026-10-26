#Requires -Version 5.1
<#
.SYNOPSIS
    Start the Ollama service, pull the analysis model, smoke-test it.

.DESCRIPTION
    Ollama itself is installed (winget: Ollama.Ollama 0.40.11). This pulls
    qwen2.5:3b (~2 GB, fits the GTX 1650), verifies a JSON answer, and records the
    result in logs\ollama_status.json so the analyser task can pick it up.

    ASCII only.
#>
$ErrorActionPreference = 'Continue'
$ProgressPreference    = 'SilentlyContinue'

$Root   = 'E:\0apps\jev-chat-windows'
$Logs   = Join-Path $Root 'logs'
$Log    = Join-Path $Logs 'ollama.log'
$Status = Join-Path $Logs 'ollama_status.json'
$Model  = 'qwen2.5:3b'

function Log([string]$m) {
    $line = '[{0}] model: {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $m
    Write-Host $line
    try { Add-Content -LiteralPath $Log -Value $line -Encoding UTF8 } catch {}
}
function Save-Status([hashtable]$h) {
    $o = [ordered]@{ updated_local = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') }
    foreach ($k in $h.Keys) { $o[$k] = $h[$k] }
    try { ($o | ConvertTo-Json -Depth 5) | Set-Content -LiteralPath $Status -Encoding UTF8 } catch {}
}

$exe = $null
foreach ($c in @("$env:LOCALAPPDATA\Programs\Ollama\ollama.exe",
                 "$env:LOCALAPPDATA\Ollama\ollama.exe",
                 'C:\Program Files\Ollama\ollama.exe')) {
    if (Test-Path -LiteralPath $c) { $exe = $c; break }
}
if (-not $exe) { $cmd = Get-Command ollama.exe -ErrorAction SilentlyContinue; if ($cmd) { $exe = $cmd.Source } }
if (-not $exe) { Log 'FATAL: ollama.exe missing'; Save-Status @{ ok = $false; stage = 'missing' }; exit 3 }
Log ('exe=' + $exe)

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
    for ($i = 0; $i -lt 40; $i++) { Start-Sleep -Seconds 2; if (Service-Up) { break } }
}
$up = Service-Up
Log ('service_up=' + $up)
if (-not $up) { Save-Status @{ ok = $false; stage = 'service' }; exit 3 }

$env:OLLAMA_KEEP_ALIVE = '30m'
Save-Status @{ ok = $false; stage = 'pull'; model = $Model; exe = $exe }
Log ('pulling ' + $Model)
$out = & $exe pull $Model 2>&1
$out | Select-Object -Last 5 | ForEach-Object { Log ('  ' + $_) }
Log ('pull exit=' + $LASTEXITCODE)

$list = (& $exe list 2>&1) -join "`n"
Log ('installed models: ' + (($list -split "`n") -join ' | '))

$body = @{ model = $Model; stream = $false; keep_alive = '30m'
           messages = @(@{ role = 'user'; content = 'reply with this JSON only: {"ok":true,"lang":"zh"}' }) } |
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
Log ('DONE ok=' + $ok)
