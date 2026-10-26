#Requires -Version 5.1
<#
.SYNOPSIS
    Publish the local chat recorder logs to the leanrea branch, and pull the
    agent's analysis back next to the results folder on this machine.

.DESCRIPTION
    Runs every 5 minutes from the scheduled task jev-chat-sync.
      local  logs\events.jsonl              -> <branch>\results\jev-monitor\events.jsonl   (tail)
      local  logs\digest-YYYY-MM-DD.md      -> <branch>\results\jev-monitor\digest-*.md
      remote results\jev-monitor\analysis-* -> E:\0github\results\leanrea-4d729933-leanrea\jev-monitor

    Push conflicts are expected now and then (git-sync-hub pushes the same branch);
    pull --rebase --autostash handles them, and a failed cycle is simply retried.
    ASCII only.
#>
$ErrorActionPreference = 'Continue'

$Root    = 'E:\0github\apps\jev-chat-windows'
$Logs    = Join-Path $Root 'logs'
$Sync    = Join-Path $Root 'sync'
$Branch  = 'arena/4d729933-leanrea'
$Repo    = 'https://github.com/mqgg5630-cyber/leanrea.git'
$Note    = Join-Path $Logs 'monitor.log'
$Mirror  = 'E:\0github\results\leanrea-4d729933-leanrea\jev-monitor'
$TailMax = 4000

if (-not (Test-Path -LiteralPath $Logs)) { New-Item -ItemType Directory -Path $Logs -Force | Out-Null }

function Note([string]$m) {
    try { Add-Content -LiteralPath $Note -Value ('[{0}] sync: {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $m) -Encoding UTF8 } catch {}
}

$gitCmd = Get-Command git.exe -ErrorAction SilentlyContinue
if (-not $gitCmd) { Note 'git.exe missing'; exit 3 }
$git = $gitCmd.Source
$env:GIT_TERMINAL_PROMPT = '0'
$env:GCM_INTERACTIVE     = 'never'

if (-not (Test-Path -LiteralPath (Join-Path $Sync '.git'))) {
    Note 'creating sparse clone'
    $out = & $git clone --quiet --filter=blob:none --sparse --branch $Branch $Repo $Sync 2>&1
    $out | ForEach-Object { Note ('  ' + $_) }
    [void](& $git -C $Sync sparse-checkout set results 2>&1)
}
if (-not (Test-Path -LiteralPath (Join-Path $Sync '.git'))) { Note 'clone failed - abort'; exit 3 }

$dst = Join-Path $Sync 'results\jev-monitor'
if (-not (Test-Path -LiteralPath $dst)) { New-Item -ItemType Directory -Path $dst -Force | Out-Null }

# ---- 1. local -> repo --------------------------------------------------------
$events = Join-Path $Logs 'events.jsonl'
$changed = $false
if (Test-Path -LiteralPath $events) {
    $lines = Get-Content -LiteralPath $events -Tail $TailMax -Encoding UTF8 -ErrorAction SilentlyContinue
    $target = Join-Path $dst 'events.jsonl'
    $old = ''
    if (Test-Path -LiteralPath $target) { $old = (Get-Content -LiteralPath $target -Raw -Encoding UTF8) }
    $new = (($lines | Out-String).TrimEnd() + "`n")
    if ($lines -and ($new.Trim() -ne $old.Trim())) {
        $new | Set-Content -LiteralPath $target -Encoding UTF8 -NoNewline
        $changed = $true
        Note ('events: ' + @($lines).Count + ' lines published')
    }
}

$digests = @(Get-ChildItem -LiteralPath $Logs -Filter 'digest-*.md' -ErrorAction SilentlyContinue |
             Sort-Object LastWriteTime -Descending | Select-Object -First 10)
foreach ($d in $digests) {
    $tgt = Join-Path $dst $d.Name
    $srcHash = (Get-FileHash -LiteralPath $d.FullName -Algorithm MD5).Hash
    $dstHash = ''
    if (Test-Path -LiteralPath $tgt) { $dstHash = (Get-FileHash -LiteralPath $tgt -Algorithm MD5).Hash }
    if ($srcHash -ne $dstHash) {
        Copy-Item -LiteralPath $d.FullName -Destination $tgt -Force
        $changed = $true
    }
}

if ($changed) {
    [void](& $git -C $Sync add -A 'results/jev-monitor' 2>&1)
    $msg = 'monitor: chat records ' + (Get-Date -Format 'yyyy-MM-dd HH:mm')
    $out = & $git -C $Sync -c user.name='jev-monitor' -c user.email='jev-monitor@local' commit -m $msg 2>&1
    $out | ForEach-Object { Note ('  ' + $_) }
    [void](& $git -C $Sync pull --rebase --autostash --quiet 2>&1)
    $out = & $git -C $Sync push --quiet origin $Branch 2>&1
    if ($LASTEXITCODE -ne 0) {
        Note ('push failed (will retry next cycle): ' + ($out -join ' '))
        [void](& $git -C $Sync pull --rebase --autostash --quiet 2>&1)
        $out = & $git -C $Sync push --quiet origin $Branch 2>&1
        if ($LASTEXITCODE -ne 0) { Note ('push retry failed: ' + ($out -join ' ')); exit 2 }
    }
    Note 'published to branch'
} else {
    [void](& $git -C $Sync pull --rebase --autostash --quiet 2>&1)
}

# ---- 2. repo -> local results (agent analysis back to this machine) ---------
if (-not (Test-Path -LiteralPath $Mirror)) { New-Item -ItemType Directory -Path $Mirror -Force | Out-Null }
$analyses = @(Get-ChildItem -LiteralPath $dst -Filter 'analysis-*' -ErrorAction SilentlyContinue)
foreach ($a in $analyses) {
    Copy-Item -LiteralPath $a.FullName -Destination (Join-Path $Mirror $a.Name) -Force
}
if ($analyses.Count -gt 0) { Note ('agent analysis files: ' + $analyses.Count + ' -> ' + $Mirror) }

Write-Output 'sync done'
exit 0
