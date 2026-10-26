#Requires -Version 5.1
<#
.SYNOPSIS
    Register the two per-user scheduled tasks that keep the deployment alive:
      jev-chat-monitor  - at logon: start the app with the recorder hook (single instance)
      jev-chat-sync     - every 5 minutes: publish recorder logs, pull analysis back
    Runs as the current user (no admin needed, GUI lands in the user's session).
    ASCII only.
#>
param([switch]$WithSync)
$ErrorActionPreference = 'Continue'

$Root    = 'E:\0apps\jev-chat-windows'
$Start   = Join-Path $Root 'monitor\start_monitor.ps1'
$Sync    = Join-Path $Root 'monitor\sync.ps1'
$LogFile = Join-Path $Root 'logs\install.log'

function Log([string]$m) {
    $line = '[{0}] tasks: {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $m
    Write-Output $line
    try { Add-Content -LiteralPath $LogFile -Value $line -Encoding UTF8 } catch {}
}

$ps = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
if (-not (Test-Path -LiteralPath $ps)) { $ps = 'powershell.exe' }
$user = $env:USERNAME

$principal = New-ScheduledTaskPrincipal -UserId $user -LogonType Interactive -RunLevel Limited -ErrorAction Stop
$settings  = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries `
                -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Hours 0) `
                -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1) `
                -MultipleInstances IgnoreNew -ErrorAction Stop

# ---------------------------------------------------------------- monitor task
try {
    $action  = New-ScheduledTaskAction -Execute $ps `
                -Argument ('-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "' + $Start + '"')
    $trigger = New-ScheduledTaskTrigger -AtLogOn -User $user
    Register-ScheduledTask -TaskName 'jev-chat-monitor' -Action $action -Trigger $trigger `
        -Principal $principal -Settings $settings -Force `
        -Description 'JevChat + recorder hook (autostart, single instance)' | Out-Null
    Log 'registered jev-chat-monitor (AtLogOn)'
} catch {
    Log ('register jev-chat-monitor failed: ' + $_.Exception.Message)
}

# ---------------------------------------------------------------- sync task (opt-in)
if (-not $WithSync) {
    # Default is LOCAL ONLY: recorder logs stay on this machine. Nothing is
    # pushed to GitHub in the background; the agent pulls a snapshot on demand
    # through a git-sync-hub task instead.
    try {
        Unregister-ScheduledTask -TaskName 'jev-chat-sync' -Confirm:$false -ErrorAction SilentlyContinue
        Log 'jev-chat-sync not registered (local-only mode; pass -WithSync to enable publishing)'
    } catch {}
} else {
try {
    $action2 = New-ScheduledTaskAction -Execute $ps `
                -Argument ('-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "' + $Sync + '"')
    $trigger2 = New-ScheduledTaskTrigger -Once -At ((Get-Date).AddMinutes(1)) `
                  -RepetitionInterval (New-TimeSpan -Minutes 5) `
                  -RepetitionDuration (New-TimeSpan -Days 3650)
    Register-ScheduledTask -TaskName 'jev-chat-sync' -Action $action2 -Trigger $trigger2 `
        -Principal $principal -Settings $settings -Force `
        -Description 'Publish JevChat recorder logs to the leanrea branch every 5 min' | Out-Null
    Log 'registered jev-chat-sync (every 5 min)'
} catch {
    Log ('register jev-chat-sync failed: ' + $_.Exception.Message)
}
}

# ---------------------------------------------------------------- report + kick
foreach ($n in @('jev-chat-monitor', 'jev-chat-sync')) {
    try {
        $t = Get-ScheduledTask -TaskName $n -ErrorAction Stop
        Log ('task ' + $n + ' state=' + $t.State)
    } catch { Log ('task ' + $n + ' missing') }
}
if ($WithSync) {
    try {
        Start-ScheduledTask -TaskName 'jev-chat-sync'
        Log 'triggered one sync run now'
    } catch { Log ('start jev-chat-sync failed: ' + $_.Exception.Message) }
}

Write-Output 'tasks done'
