#Requires -Version 5.1
<#
.SYNOPSIS
    Last-resort chunk fixer: re-fetch stubborn ranges as 1 MB sub-ranges.

.DESCRIPTION
    Two 8 MB ranges (67, 119) survive every retry because the proxy drops the
    connection at a fixed point. Cutting them into 1 MB requests, each retried,
    works around it: a truncated sub-range only costs a retry, and the assembled
    file is still checked against the official sha256 by repair_ollama.ps1.

    ASCII only.
#>
$ErrorActionPreference = 'Continue'

$Root   = 'E:\0apps\jev-chat-windows'
$Tools  = 'E:\0apps\tools'
$Chunks = Join-Path $Tools 'ollama_chunks'
$Logs   = Join-Path $Root 'logs'
$Log    = Join-Path $Logs 'ollama.log'
$Px     = $env:HTTPS_PROXY
if (-not $Px) { $Px = $env:HTTP_PROXY }
$Base   = 'https://github.com/ollama/ollama/releases/download/v0.40.11/OllamaSetup.exe'
$Total  = [int64]1661482184
$Chunk  = 8MB
$Sub    = 1MB

function Log([string]$m) {
    $line = '[{0}] subchunk: {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $m
    Write-Host $line
    try { Add-Content -LiteralPath $Log -Value $line -Encoding UTF8 } catch {}
}

# find chunks whose size is wrong
$bad = @()
for ($i = 0; $i -lt [math]::Ceiling($Total / $Chunk); $i++) {
    $s = [int64]$i * $Chunk
    $e = [math]::Min($s + $Chunk - 1, $Total - 1)
    $want = $e - $s + 1
    $f = Join-Path $Chunks ('part_{0:d5}.bin' -f $i)
    if (-not (Test-Path -LiteralPath $f) -or ((Get-Item $f).Length -ne $want)) { $bad += $i }
}
Log ('bad chunks: ' + ($bad -join ','))

foreach ($i in $bad) {
    $start = [int64]$i * $Chunk
    $end = [math]::Min($start + $Chunk - 1, $Total - 1)
    $file = Join-Path $Chunks ('part_{0:d5}.bin' -f $i)
    if (Test-Path -LiteralPath $file) { Remove-Item -LiteralPath $file -Force }
    $okAll = $true
    $pos = $start
    while ($pos -le $end) {
        $subEnd = [math]::Min($pos + $Sub - 1, $end)
        $want = $subEnd - $pos + 1
        $tmp = "$file.sub"
        $got = $false
        for ($try = 1; $try -le 12; $try++) {
            $useProxy = ($try % 2) -eq 1
            $a = @('-sS', '-L', '--http1.1', '--ssl-no-revoke', '-k', '-r', "$pos-$subEnd",
                   '--connect-timeout', '15', '--max-time', '90', '-o', $tmp)
            if ($useProxy -and $Px) { $a = @('-x', $Px) + $a }
            $a += $Base
            & curl.exe @a 2>&1 | Out-Null
            if ((Test-Path -LiteralPath $tmp) -and ((Get-Item $tmp).Length -eq $want)) { $got = $true; break }
        }
        if (-not $got) {
            Log ('  sub-range FAILED chunk ' + $i + ' at ' + $pos)
            $okAll = $false
            break
        }
        $fs = [System.IO.File]::Open($file, [System.IO.FileMode]::Append)
        try {
            $bytes = [System.IO.File]::ReadAllBytes($tmp)
            $fs.Write($bytes, 0, $bytes.Length)
        } finally { $fs.Close() }
        Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
        $pos = $subEnd + 1
    }
    if ($okAll) { Log ('  chunk ' + $i + ' rebuilt (' + (Get-Item $file).Length + ' bytes)') }
}
Log 'sub-chunk pass finished'
