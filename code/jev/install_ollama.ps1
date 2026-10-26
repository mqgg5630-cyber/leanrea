#Requires -Version 5.1
<#
.SYNOPSIS
    Install Ollama + a small Chinese model so the laptop can analyse chats locally
    (no API key, no cloud, nothing leaves the machine).

.DESCRIPTION
    Hardware on this host: i5-10200H / 16 GB / GTX 1650 4 GB -> qwen2.5:3b (Q4)
    fits entirely in VRAM and answers a chat prompt in a few seconds.

    Runs detached (~1 GB installer + ~2 GB model). Progress: logs\ollama.log,
    state: logs\ollama_status.json. ASCII only.
#>
$ErrorActionPreference = 'Continue'
$ProgressPreference    = 'SilentlyContinue'

$Root   = 'E:\0apps\jev-chat-windows'
$Tools  = 'E:\0apps\tools'
$Logs   = Join-Path $Root 'logs'
$Log    = Join-Path $Logs 'ollama.log'
$Status = Join-Path $Logs 'ollama_status.json'
$Model  = 'qwen2.5:3b'
$Proxy  = $env:HTTPS_PROXY
if (-not $Proxy) { $Proxy = $env:HTTP_PROXY }

foreach ($d in @($Tools, $Logs)) { if (-not (Test-Path -LiteralPath $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null } }

function Log([string]$m) {
    $line = '[{0}] ollama: {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $m
    Write-Host $line
    try { Add-Content -LiteralPath $Log -Value $line -Encoding UTF8 } catch {}
}
function Save-Status([hashtable]$h) {
    $o = [ordered]@{ updated_local = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') }
    foreach ($k in $h.Keys) { $o[$k] = $h[$k] }
    try { ($o | ConvertTo-Json -Depth 5) | Set-Content -LiteralPath $Status -Encoding UTF8 } catch {}
}

Save-Status @{ ok = $false; stage = 'download'; model = $Model }

# ---- 1. locate or fetch ollama ----------------------------------------------
$exe = $null
foreach ($c in @(
    "$env:LOCALAPPDATA\Programs\Ollama\ollama.exe",
    "$env:LOCALAPPDATA\Ollama\ollama.exe",
    'C:\Program Files\Ollama\ollama.exe',
    'E:\Ollama\ollama.exe'
)) { if (Test-Path -LiteralPath $c) { $exe = $c; break } }
if (-not $exe) { $cmd = Get-Command ollama.exe -ErrorAction SilentlyContinue; if ($cmd) { $exe = $cmd.Source } }

if (-not $exe) {
    $setup = Join-Path $Tools 'OllamaSetup.exe'
    if (-not (Test-Path -LiteralPath $setup) -or ((Get-Item $setup).Length -lt 50MB)) {
        Log 'downloading OllamaSetup.exe (~1 GB)'
        $url = 'https://github.com/ollama/ollama/releases/latest/download/OllamaSetup.exe'
        foreach ($withProxy in @($true, $false)) {
            if ((Test-Path -LiteralPath $setup) -and ((Get-Item $setup).Length -gt 50MB)) { break }
            $a = @('-sS', '--http1.1', '-L', '--ssl-no-revoke', '--connect-timeout', '20',
                   '--max-time', '3600', '-o', $setup)
            if ($withProxy -and $Proxy) { $a = @('-x', $Proxy) + $a }
            $a += $url
            Log ('downloading (proxy=' + ($withProxy -and [bool]$Proxy) + ')')
            & curl.exe @a 2>&1 | Select-Object -Last 3 | ForEach-Object { Log ('  curl: ' + $_) }
        }
    }
    if ((Test-Path -LiteralPath $setup) -and ((Get-Item $setup).Length -gt 50MB)) {
        Log ('installer size=' + [math]::Round((Get-Item $setup).Length / 1MB) + ' MB - silent install')
        $p = Start-Process -FilePath $setup -ArgumentList '/VERYSILENT', '/NORESTART', '/SUPPRESSMSGBOXES' -PassThru -Wait
        Log ('installer exit=' + $p.ExitCode)
    } else {
        Log 'FATAL: installer download failed'
        Save-Status @{ ok = $false; stage = 'download'; model = $Model; note = 'installer failed' }
        exit 3
    }
    foreach ($c in @(
        "$env:LOCALAPPDATA\Programs\Ollama\ollama.exe",
        "$env:LOCALAPPDATA\Ollama\ollama.exe",
        'C:\Program Files\Ollama\ollama.exe'
    )) { if (Test-Path -LiteralPath $c) { $exe = $c; break } }
}
if (-not $exe) {
    Log 'FATAL: ollama.exe not found after install'
    Save-Status @{ ok = $false; stage = 'install'; model = $Model }
    exit 3
}
Log ('ollama=' + $exe + ' version=' + ((& $exe --version 2>&1) -join ' '))

# ---- 2. make sure the service is up -----------------------------------------
function Service-Up {
    try {
        $r = Invoke-WebRequest -Uri 'http://127.0.0.1:11434/api/tags' -UseBasicParsing -TimeoutSec 4
        return ($r.StatusCode -eq 200)
    } catch { return $false }
}
if (-not (Service-Up)) {
    Log 'starting the ollama service'
    Start-Process -FilePath $exe -ArgumentList 'serve' -WindowStyle Hidden `
        -RedirectStandardOutput (Join-Path $Logs 'ollama_serve.out') `
        -RedirectStandardError (Join-Path $Logs 'ollama_serve.err')
    for ($i = 0; $i -lt 30; $i++) { Start-Sleep -Seconds 2; if (Service-Up) { break } }
}
Log ('service_up=' + (Service-Up))

# ---- 3. pull the model ------------------------------------------------------
Save-Status @{ ok = $false; stage = 'pull'; model = $Model; exe = $exe }
Log ('pulling model ' + $Model + ' (~2 GB, GPU offload expected)')
$env:OLLAMA_KEEP_ALIVE = '30m'
$out = & $exe pull $Model 2>&1
$out | Select-Object -Last 6 | ForEach-Object { Log ('  ' + $_) }
Log ('pull exit=' + $LASTEXITCODE)

# ---- 4. smoke test ----------------------------------------------------------
$body = @{
    model    = $Model
    stream   = $false
    messages = @(@{ role = 'user'; content = 'reply with this JSON only: {"ok":true,"why":"one short sentence"}' })
} | ConvertTo-Json -Depth 5 -Compress
$reply = ''
try {
    $r = Invoke-RestMethod -Uri 'http://127.0.0.1:11434/api/chat' -Method Post -Body $body `
            -ContentType 'application/json; charset=utf-8' -TimeoutSec 180
    $reply = $r.message.content
} catch { $reply = 'ERROR: ' + $_.Exception.Message }
Log ('smoke=' + ($reply -replace '\s+', ' '))

$ok = ($reply -match '\{') -or (($reply -match 'ok'))
Save-Status @{
    ok    = $ok
    stage = 'done'
    model = $Model
    exe   = $exe
    smoke = ($reply -replace '\s+', ' ')
}
Log ('DONE ok=' + $ok)
