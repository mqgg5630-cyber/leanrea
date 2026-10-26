#Requires -Version 5.1
<#
.SYNOPSIS
    Chunked, parallel, resumable download + install of the local analysis model.

.DESCRIPTION
    The host's proxy kills long TLS transfers after ~10 s ("server closed
    abruptly"), but short range requests run at ~2.5 MB/s. So the 1.6 GB installer
    is fetched as 8 MB ranges, four workers in parallel, each range retried and
    size-checked, then concatenated and verified against sha256sum.txt.

    Then: silent install, service up, model pull (qwen2.5:3b), GGUF fallback from
    hf-mirror if the registry stalls, smoke test.

    Detached. logs\ollama.log + logs\ollama_status.json. ASCII only.
#>
$ErrorActionPreference = 'Continue'
$ProgressPreference    = 'SilentlyContinue'

$Root   = 'E:\0apps\jev-chat-windows'
$Tools  = 'E:\0apps\tools'
$Chunks = Join-Path $Tools 'ollama_chunks'
$Logs   = Join-Path $Root 'logs'
$Log    = Join-Path $Logs 'ollama.log'
$Status = Join-Path $Logs 'ollama_status.json'
$Setup  = Join-Path $Tools 'OllamaSetup.exe'
$Px     = $env:HTTPS_PROXY
if (-not $Px) { $Px = $env:HTTP_PROXY }
$Base   = 'https://github.com/ollama/ollama/releases/download/v0.40.11/OllamaSetup.exe'
$Model  = 'qwen2.5:3b'
$ChunkMB = 8
$Workers = 4

foreach ($d in @($Tools, $Logs, $Chunks)) { if (-not (Test-Path -LiteralPath $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null } }

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

# ---------------------------------------------------------------- 0. stop old downloaders
Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object {
    $_.CommandLine -and ($_.CommandLine -like '*fetch_ollama*' -or $_.CommandLine -like '*install_ollama*') -and
    ($_.ProcessId -ne $PID)
} | ForEach-Object { Log ('stopping old downloader pid ' + $_.ProcessId); Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }

# ---------------------------------------------------------------- 1. size + hash
$total = 0
try {
    $h = (& curl.exe -sS -I -L --http1.1 --ssl-no-revoke -k -x $Px --connect-timeout 20 --max-time 60 $Base 2>&1) -join "`n"
    $m = [regex]::Match($h, '(?im)^content-length:\s*(\d+)')
    if ($m.Success) { $total = [int64]$m.Groups[1].Value }
} catch {}
if ($total -le 0) { $total = 1661482184 }
Log ('installer bytes=' + $total + ' (' + [math]::Round($total / 1MB) + ' MB)')

$wantSha = ''
try {
    $sums = (& curl.exe -sS -L --http1.1 --ssl-no-revoke -k -x $Px --connect-timeout 20 --max-time 120 `
             'https://github.com/ollama/ollama/releases/download/v0.40.11/sha256sum.txt' 2>&1) -join "`n"
    $line = ($sums -split "`n" | Where-Object { $_ -match 'OllamaSetup\.exe' } | Select-Object -First 1)
    if ($line -match '^([0-9a-fA-F]{64})') { $wantSha = $Matches[1].ToLower() }
    Log ('expected sha256=' + $wantSha)
} catch { Log 'sha256sum.txt unavailable - skipping hash check' }

# ---------------------------------------------------------------- 2. chunked download
$chunkBytes = $ChunkMB * 1MB
$count = [math]::Ceiling($total / $chunkBytes)
Log ('chunks=' + $count + ' x ' + $ChunkMB + ' MB, workers=' + $Workers)

function Get-Chunk([int]$idx) {
    $start = [int64]$idx * $chunkBytes
    $end = [math]::Min($start + $chunkBytes - 1, $total - 1)
    $want = $end - $start + 1
    $file = Join-Path $Chunks ('part_{0:d5}.bin' -f $idx)
    if ((Test-Path -LiteralPath $file) -and ((Get-Item $file).Length -eq $want)) { return $true }
    for ($try = 1; $try -le 6; $try++) {
        $a = @('-sS', '-L', '--http1.1', '--ssl-no-revoke', '-k', '-r', "$start-$end",
               '--connect-timeout', '20', '--max-time', '180', '-o', $file)
        if ($Px) { $a = @('-x', $Px) + $a }
        $a += $Base
        & curl.exe @a 2>&1 | Out-Null
        if ((Test-Path -LiteralPath $file) -and ((Get-Item $file).Length -eq $want)) { return $true }
        Start-Sleep -Milliseconds 800
    }
    return $false
}

$jobs = @()
$queue = [System.Collections.Queue]::new()
for ($i = 0; $i -lt $count; $i++) { $queue.Enqueue($i) }
$failed = 0
$workers = @()
for ($w = 0; $w -lt $Workers; $w++) {
    $ps = [PowerShell]::Create()
    [void]$ps.AddScript({
        param($queueRef, $fn, $chunkDir)
        while ($true) {
            $idx = $null
            [System.Threading.Monitor]::Enter($queueRef)
            try {
                if ($queueRef.Count -gt 0) { $idx = $queueRef.Dequeue() }
            } finally { [System.Threading.Monitor]::Exit($queueRef) }
            if ($null -eq $idx) { break }
            $ok = Get-Chunk $idx
            if (-not $ok) { Add-Content -LiteralPath (Join-Path $chunkDir 'failed.txt') -Value $idx }
        }
    }).AddArgument($queue).AddArgument($null).AddArgument($Chunks)
    $workers += $ps
    [void]$ps.BeginInvoke()
}
Log 'workers started - this takes a few minutes'

# progress loop
$lastReport = 0
while ($workers | Where-Object { $_.InvocationStateInfo.State -eq 'Running' }) {
    Start-Sleep -Seconds 15
    $have = @(Get-ChildItem -LiteralPath $Chunks -Filter 'part_*.bin' -ErrorAction SilentlyContinue)
    $mb = [math]::Round((($have | Measure-Object -Property Length -Sum).Sum) / 1MB, 0)
    if ([int](Get-Date -Format 'HHmm') -ne $lastReport) {
        $lastReport = [int](Get-Date -Format 'HHmm')
        Log ('downloaded ' + $mb + ' / ' + [math]::Round($total / 1MB) + ' MB')
        Save-Status @{ ok = $false; stage = 'download'; mb = $mb; total_mb = [math]::Round($total / 1MB) }
    }
}

# ---------------------------------------------------------------- 3. assemble
$have = @(Get-ChildItem -LiteralPath $Chunks -Filter 'part_*.bin' -ErrorAction SilentlyContinue)
Log ('chunks on disk=' + $have.Count + ' of ' + $count)
if ($have.Count -lt $count) {
    Log 'FATAL: missing chunks'
    Save-Status @{ ok = $false; stage = 'download'; chunks = $have.Count; need = $count }
    exit 3
}
$out = [System.IO.File]::Create($Setup)
try {
    for ($i = 0; $i -lt $count; $i++) {
        $f = Join-Path $Chunks ('part_{0:d5}.bin' -f $i)
        $bytes = [System.IO.File]::ReadAllBytes($f)
        $out.Write($bytes, 0, $bytes.Length)
    }
} finally { $out.Close() }
$got = (Get-Item $Setup).Length
Log ('assembled bytes=' + $got)
if ($wantSha) {
    $sha = (Get-FileHash -LiteralPath $Setup -Algorithm SHA256).Hash.ToLower()
    Log ('sha256=' + $sha + ' expected=' + $wantSha + ' match=' + ($sha -eq $wantSha))
    if ($sha -ne $wantSha) {
        Log 'FATAL: hash mismatch - removing the file'
        Remove-Item -LiteralPath $Setup -Force -ErrorAction SilentlyContinue
        Save-Status @{ ok = $false; stage = 'verify'; note = 'hash mismatch' }
        exit 3
    }
}

# ---------------------------------------------------------------- 4. install
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

# ---------------------------------------------------------------- 5. service
function Service-Up {
    try {
        $r = Invoke-WebRequest -Uri 'http://127.0.0.1:11434/api/tags' -UseBasicParsing -TimeoutSec 4
        return ($r.StatusCode -eq 200)
    } catch { return $false }
}
if (-not (Service-Up)) {
    Start-Process -FilePath $exe -ArgumentList 'serve' -WindowStyle Hidden `
        -RedirectStandardOutput (Join-Path $Logs 'ollama_serve.out') `
        -RedirectStandardError (Join-Path $Logs 'ollama_serve.err')
    for ($i = 0; $i -lt 30; $i++) { Start-Sleep -Seconds 2; if (Service-Up) { break } }
}
Log ('service_up=' + (Service-Up))

# ---------------------------------------------------------------- 6. model
Save-Status @{ ok = $false; stage = 'pull'; model = $Model }
$env:OLLAMA_KEEP_ALIVE = '30m'
Log ('pulling ' + $Model)
$outp = & $exe pull $Model 2>&1
$outp | Select-Object -Last 4 | ForEach-Object { Log ('  ' + $_) }
$pullOk = ($LASTEXITCODE -eq 0)
Log ('pull ok=' + $pullOk)

if (-not $pullOk) {
    $gguf = Join-Path $Tools 'qwen2.5-3b-instruct-q4_k_m.gguf'
    $gurl = 'https://hf-mirror.com/Qwen/Qwen2.5-3B-Instruct-GGUF/resolve/main/qwen2.5-3b-instruct-q4_k_m.gguf'
    Log 'fallback: GGUF from hf-mirror (chunked)'
    for ($i = 1; $i -le 12; $i++) {
        & curl.exe -sS -L --http1.1 --ssl-no-revoke -k -C - --connect-timeout 20 --max-time 600 `
            --retry 3 --retry-all-errors -o $gguf $gurl 2>&1 | Out-Null
        if ((Get-Item $gguf -ErrorAction SilentlyContinue).Length -gt 1500MB) { break }
        Start-Sleep -Seconds 3
    }
    if ((Test-Path -LiteralPath $gguf) -and ((Get-Item $gguf).Length -gt 1500MB)) {
        $mf = Join-Path $Tools 'Modelfile.qwen'
        "FROM `"$gguf`"`nPARAMETER temperature 0.4`nPARAMETER num_predict 700" |
            Set-Content -LiteralPath $mf -Encoding UTF8
        $outc = & $exe create jev-cn -f $mf 2>&1
        $outc | Select-Object -Last 3 | ForEach-Object { Log ('  ' + $_) }
        if ($LASTEXITCODE -eq 0) { $Model = 'jev-cn' }
    }
}

# ---------------------------------------------------------------- 7. smoke
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
Save-Status @{ ok = $okAll; stage = 'done'; model = $Model; exe = $exe; smoke = ($reply -replace '\s+', ' ') }
if ($okAll) { Remove-Item -LiteralPath $Chunks -Recurse -Force -ErrorAction SilentlyContinue }
Log ('DONE ok=' + $okAll + ' model=' + $Model)
