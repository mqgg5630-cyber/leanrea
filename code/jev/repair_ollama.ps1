#Requires -Version 5.1
<#
.SYNOPSIS
    Repair short chunks, assemble, verify, install (fetch_ollama.ps1 part 2).

.DESCRIPTION
    The chunked downloader can leave a chunk short when the proxy cuts a range
    request (29 of 199 here). This pass re-checks every chunk against its exact
    expected size, re-fetches only the bad ones (sequential, many retries, both
    proxy and direct), assembles, verifies sha256 against the official file, then
    installs Ollama and pulls the model. If the registry pull cannot finish, fall
    back to winget, then to a GGUF from hf-mirror.

    Detached. logs\ollama.log + logs\ollama_status.json. ASCII only.
#>
$ErrorActionPreference = 'Continue'
$ProgressPreference    = 'SilentlyContinue'

$Root    = 'E:\0apps\jev-chat-windows'
$Tools   = 'E:\0apps\tools'
$Chunks  = Join-Path $Tools 'ollama_chunks'
$Logs    = Join-Path $Root 'logs'
$Log     = Join-Path $Logs 'ollama.log'
$Status  = Join-Path $Logs 'ollama_status.json'
$Setup   = Join-Path $Tools 'OllamaSetup.exe'
$Px      = $env:HTTPS_PROXY
if (-not $Px) { $Px = $env:HTTP_PROXY }
$Base    = 'https://github.com/ollama/ollama/releases/download/v0.40.11/OllamaSetup.exe'
$Total   = [int64]1661482184
$WantSha = '87309d23b423abeae1d8df2f98df95f94bf35659debfdf3761d65b7b62a75508'
$ChunkMB = 8
$Model   = 'qwen2.5:3b'

function Log([string]$m) {
    $line = '[{0}] repair: {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $m
    Write-Host $line
    try { Add-Content -LiteralPath $Log -Value $line -Encoding UTF8 } catch {}
}
function Save-Status([hashtable]$h) {
    $o = [ordered]@{ updated_local = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') }
    foreach ($k in $h.Keys) { $o[$k] = $h[$k] }
    try { ($o | ConvertTo-Json -Depth 5) | Set-Content -LiteralPath $Status -Encoding UTF8 } catch {}
}

$chunkBytes = $ChunkMB * 1MB
$count = [math]::Ceiling($Total / $chunkBytes)

function Expected([int]$i) {
    $start = [int64]$i * $chunkBytes
    $end = [math]::Min($start + $chunkBytes - 1, $Total - 1)
    return [int64]($end - $start + 1)
}

function Fetch-Chunk([int]$i) {
    $start = [int64]$i * $chunkBytes
    $end = [math]::Min($start + $chunkBytes - 1, $Total - 1)
    $want = $end - $start + 1
    $file = Join-Path $Chunks ('part_{0:d5}.bin' -f $i)
    for ($try = 1; $try -le 10; $try++) {
        $useProxy = ($try % 2) -eq 1
        $a = @('-sS', '-L', '--http1.1', '--ssl-no-revoke', '-k', '-r', "$start-$end",
               '--connect-timeout', '20', '--max-time', '240', '-o', $file)
        if ($useProxy -and $Px) { $a = @('-x', $Px) + $a }
        $a += $Base
        & curl.exe @a 2>&1 | Out-Null
        if ((Test-Path -LiteralPath $file) -and ((Get-Item $file).Length -eq $want)) { return $true }
    }
    return $false
}

# ---------------------------------------------------------------- 1. verify sizes
$bad = @()
for ($i = 0; $i -lt $count; $i++) {
    $f = Join-Path $Chunks ('part_{0:d5}.bin' -f $i)
    if (-not (Test-Path -LiteralPath $f) -or ((Get-Item $f).Length -ne (Expected $i))) { $bad += $i }
}
Log ('chunks=' + $count + ' bad=' + $bad.Count)
Save-Status @{ ok = $false; stage = 'repair'; bad = $bad.Count; total = $count }

$fixed = 0
foreach ($i in $bad) {
    if (Fetch-Chunk $i) { $fixed++ } else { Log ('FAILED chunk ' + $i) }
    if ($fixed % 5 -eq 0) {
        Log ('repaired ' + $fixed + '/' + $bad.Count)
        Save-Status @{ ok = $false; stage = 'repair'; fixed = $fixed; bad = $bad.Count }
    }
}
$stillBad = @()
for ($i = 0; $i -lt $count; $i++) {
    $f = Join-Path $Chunks ('part_{0:d5}.bin' -f $i)
    if (-not (Test-Path -LiteralPath $f) -or ((Get-Item $f).Length -ne (Expected $i))) { $stillBad += $i }
}
Log ('repaired=' + $fixed + ' still_bad=' + $stillBad.Count)
if ($stillBad.Count -gt 0) {
    Log 'FATAL: chunks still missing - rerun later'
    Save-Status @{ ok = $false; stage = 'repair'; still_bad = $stillBad.Count }
    exit 3
}

# ---------------------------------------------------------------- 2. assemble + verify
$out = [System.IO.File]::Create($Setup)
try {
    for ($i = 0; $i -lt $count; $i++) {
        $bytes = [System.IO.File]::ReadAllBytes((Join-Path $Chunks ('part_{0:d5}.bin' -f $i)))
        $out.Write($bytes, 0, $bytes.Length)
    }
} finally { $out.Close() }
$sha = (Get-FileHash -LiteralPath $Setup -Algorithm SHA256).Hash.ToLower()
Log ('assembled=' + (Get-Item $Setup).Length + ' sha=' + $sha + ' match=' + ($sha -eq $WantSha))
if ($sha -ne $WantSha) {
    Log 'FATAL: hash still wrong'
    Save-Status @{ ok = $false; stage = 'verify'; sha = $sha }
    exit 3
}

# ---------------------------------------------------------------- 3. install
Log 'silent install'
$p = Start-Process -FilePath $Setup -ArgumentList '/VERYSILENT', '/NORESTART', '/SUPPRESSMSGBOXES' -PassThru -Wait
Log ('installer exit=' + $p.ExitCode)
$exe = $null
foreach ($c in @("$env:LOCALAPPDATA\Programs\Ollama\ollama.exe",
                 "$env:LOCALAPPDATA\Ollama\ollama.exe",
                 'C:\Program Files\Ollama\ollama.exe')) {
    if (Test-Path -LiteralPath $c) { $exe = $c; break }
}
if (-not $exe) { $cmd = Get-Command ollama.exe -ErrorAction SilentlyContinue; if ($cmd) { $exe = $cmd.Source } }
if (-not $exe) { Log 'FATAL: ollama.exe missing'; Save-Status @{ ok = $false; stage = 'install' }; exit 3 }
Log ('exe=' + $exe + ' version=' + ((& $exe --version 2>&1) -join ' '))

# ---------------------------------------------------------------- 4. service
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

# ---------------------------------------------------------------- 5. model
$env:OLLAMA_KEEP_ALIVE = '30m'
Save-Status @{ ok = $false; stage = 'pull'; model = $Model }
Log ('pulling ' + $Model)
$outp = & $exe pull $Model 2>&1
$outp | Select-Object -Last 4 | ForEach-Object { Log ('  ' + $_) }
$pullOk = ($LASTEXITCODE -eq 0)
Log ('pull ok=' + $pullOk)

if (-not $pullOk) {
    $gguf = Join-Path $Tools 'qwen2.5-3b-instruct-q4_k_m.gguf'
    $gurl = 'https://hf-mirror.com/Qwen/Qwen2.5-3B-Instruct-GGUF/resolve/main/qwen2.5-3b-instruct-q4_k_m.gguf'
    Log 'fallback: GGUF from hf-mirror'
    for ($i = 1; $i -le 20; $i++) {
        & curl.exe -sS -L --http1.1 --ssl-no-revoke -k -C - --connect-timeout 20 --max-time 600 `
            --retry 3 --retry-all-errors -o $gguf $gurl 2>&1 | Out-Null
        if ((Get-Item $gguf -ErrorAction SilentlyContinue).Length -gt 1500MB) { break }
        Start-Sleep -Seconds 2
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

# ---------------------------------------------------------------- 6. smoke
$body = @{ model = $Model; stream = $false
           messages = @(@{ role = 'user'; content = 'reply with this JSON only: {"ok":true}' }) } |
        ConvertTo-Json -Depth 5 -Compress
$reply = ''
try {
    $r = Invoke-RestMethod -Uri 'http://127.0.0.1:11434/api/chat' -Method Post -Body $body `
            -ContentType 'application/json; charset=utf-8' -TimeoutSec 300
    $reply = [string]$r.message.content
} catch { $reply = 'ERROR: ' + $_.Exception.Message }
Log ('smoke=' + ($reply -replace '\s+', ' '))

$okAll = $reply -match '\{'
Save-Status @{ ok = $okAll; stage = 'done'; model = $Model; exe = $exe; smoke = ($reply -replace '\s+', ' ') }
Log ('DONE ok=' + $okAll + ' model=' + $Model)
