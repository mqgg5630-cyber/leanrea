#Requires -Version 5.1
<#
.SYNOPSIS
    On-demand pull: copy the local recorder snapshot into this clone so the
    git-sync-hub push carries it back to the agent (local-only mode - nothing is
    uploaded in the background, this runs only when the agent asks for a pull).

.DESCRIPTION
    Writes, relative to the clone root (cwd of a hub task):
      results/jev-monitor/events.jsonl       last N recorder lines
      results/jev-monitor/digest-*.md        the app's own daily digests
      results/jev-monitor/pull-<ts>.md       readable transcript + health snapshot
    ASCII only.
#>
param(
    [int]$Tail = 3000
)
$ErrorActionPreference = 'Continue'

$Src     = 'E:\0apps\jev-chat-windows\logs'
$AppDir  = 'E:\0apps\jev-chat-windows\app'
$Dst     = Join-Path (Get-Location).Path 'results\jev-monitor'
$Stamp   = Get-Date -Format 'yyyyMMdd-HHmmss'

if (-not (Test-Path -LiteralPath $Dst)) { New-Item -ItemType Directory -Path $Dst -Force | Out-Null }

$report = New-Object System.Collections.ArrayList
function Rep([string]$line) { [void]$report.Add($line) }

Rep ('# JevChat monitor snapshot ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
Rep ''
Rep ('host=' + $env:COMPUTERNAME)

# ---- health ------------------------------------------------------------------
$procs = @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object {
    $_.CommandLine -and ($_.CommandLine -match 'jev-chat-windows\\app\\main\.py') })
Rep ('app_running=' + ($procs.Count -gt 0))
$taskState = 'missing'
try { $taskState = (Get-ScheduledTask -TaskName 'jev-chat-monitor' -ErrorAction Stop).State } catch {}
Rep ('task_jev_monitor=' + $taskState)
$keys = @()
foreach ($k in @('JEV_API_KEY', 'LLM_API_KEY')) {
    $keys += ($k + '=' + [string]([bool]([Environment]::GetEnvironmentVariable($k, 'User'))))
}
Rep ('keys=' + ($keys -join ' '))
if (Test-Path -LiteralPath (Join-Path $AppDir '.git')) {
    Rep ('app_head=' + ((& git -C $AppDir rev-parse --short HEAD 2>&1) -join ' '))
}
$hook = @(Select-String -LiteralPath (Join-Path $AppDir 'main.py') -Pattern 'jev-monitor:hook' -SimpleMatch -ErrorAction SilentlyContinue).Count
Rep ('hook_in_main=' + ($hook -gt 0))
Rep ''

# ---- events ------------------------------------------------------------------
$events = Join-Path $Src 'events.jsonl'
if (-not (Test-Path -LiteralPath $events)) {
    Rep 'events.jsonl missing: the app has not run yet, or no new message arrived.'
} else {
    $it = Get-Item -LiteralPath $events
    $lines = @(Get-Content -LiteralPath $events -Tail $Tail -Encoding UTF8 -ErrorAction SilentlyContinue)
    Rep ('events_bytes=' + $it.Length + ' tail_lines=' + $lines.Count)
    Rep ''
    Copy-Item -LiteralPath $events -Destination (Join-Path $Dst 'events.jsonl') -Force

    $records = @()
    foreach ($l in $lines) {
        try { $records += ($l | ConvertFrom-Json) } catch {}
    }
    $msgs = @($records | Where-Object { $_.kind -eq 'msg' })
    $an   = @($records | Where-Object { $_.kind -eq 'analysis' })
    $starts = @($records | Where-Object { $_.kind -eq 'app_start' })
    Rep ('messages=' + $msgs.Count + ' analyses=' + $an.Count + ' app_starts=' + $starts.Count)
    Rep ''
    Rep '## messages'
    Rep ''
    foreach ($m in ($msgs | Select-Object -Last 120)) {
        $who = 'her'
        if ($m.who -eq 'me') { $who = 'me' }
        $name = ''
        if ($m.name) { $name = $m.name + ' ' }
        Rep ('- `' + $m.t + '` [' + $m.chat + '] ' + $name + $who + ': ' + $m.text)
    }
    if ($an.Count -gt 0) {
        Rep ''
        Rep '## app judgement / candidates'
        Rep ''
        foreach ($a in ($an | Select-Object -Last 20)) {
            Rep ('### ' + $a.t)
            $i = 0
            foreach ($c in @($a.candidates)) {
                $mark = ''
                if ($i -eq [int]$a.best_index) { $mark = ' **[best]**' }
                Rep ('- (' + $i + ') ' + $c + $mark)
                $i++
            }
            if ($a.answers) {
                $pairs = @()
                foreach ($p in $a.answers.PSObject.Properties) {
                    $v = $p.Value
                    $txt = ''
                    if ($v.choice) { $txt = [string]$v.choice }
                    elseif ($v.score -ne $null) { $txt = 'score=' + [string]$v.score }
                    elseif ($v.noul -ne $null) { $txt = 'p=' + [string]$v.noul }
                    $pairs += ($p.Name + '=' + $txt)
                }
                Rep ('- judgement: ' + ($pairs -join '; '))
            }
            Rep ''
        }
    }
}

# ---- the app's own digests ---------------------------------------------------
$digests = @(Get-ChildItem -LiteralPath $Src -Filter 'digest-*.md' -ErrorAction SilentlyContinue |
             Sort-Object LastWriteTime -Descending | Select-Object -First 5)
foreach ($d in $digests) { Copy-Item -LiteralPath $d.FullName -Destination (Join-Path $Dst $d.Name) -Force }
Rep ''
Rep ('digests_copied=' + $digests.Count)

$outFile = Join-Path $Dst ('pull-' + $Stamp + '.md')
($report -join "`r`n") | Set-Content -LiteralPath $outFile -Encoding UTF8
Write-Output ('wrote ' + $outFile + ' (' + $report.Count + ' lines)')
