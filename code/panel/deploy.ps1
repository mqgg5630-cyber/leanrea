# Only owns arena-desk-* and optional arena-dsh/desktop-pet tasks. NEVER edits git-sync-hub.
$ErrorActionPreference='Stop'
$root='E:\0apps\ArenaDesk'
New-Item -ItemType Directory -Force "$root\data" | Out-Null
$old=Get-ScheduledTask -TaskName 'arena-desk-panel' -TaskPath '\' -ErrorAction SilentlyContinue
if ($old) { Stop-ScheduledTask -TaskName 'arena-desk-panel' -TaskPath '\' }
foreach ($name in @('server.py','index.html','style.css','app.js','control.ps1','launch_panel.ps1','launch_dsh.ps1','launch_pet.ps1','open_dsh.ps1','notion-links.json','README.md')) {
    Copy-Item (Join-Path $PSScriptRoot $name) (Join-Path $root $name) -Force
}
# Syntax check on real Windows before registration.
Get-ChildItem $root -Filter '*.ps1' | ForEach-Object {
    $tokens=$null; $errors=$null
    [void][System.Management.Automation.Language.Parser]::ParseFile($_.FullName,[ref]$tokens,[ref]$errors)
    if ($errors.Count -gt 0) { throw ($errors | Out-String) }
}
$user=[Security.Principal.WindowsIdentity]::GetCurrent().Name
$principal=New-ScheduledTaskPrincipal -UserId $user -LogonType Interactive -RunLevel Limited
$settings=New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Hours 0) -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1) -MultipleInstances IgnoreNew
$trigger=New-ScheduledTaskTrigger -AtLogOn -User $user
$ps=Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
function Install-Task([string]$n,[string]$exe,[string]$arguments,[bool]$start=$false) {
    $a=New-ScheduledTaskAction -Execute $exe -Argument $arguments -WorkingDirectory $root
    Register-ScheduledTask -TaskName $n -TaskPath '\' -Action $a -Trigger $trigger -Principal $principal -Settings $settings -Force | Out-Null
    if ($start) { Start-ScheduledTask -TaskName $n -TaskPath '\' }
}
Install-Task 'arena-desk-panel' 'E:\spider\pythonw.exe' ('"'+$root+'\server.py"') $true
$launchArgs='-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "'+$root+'\launch_panel.ps1"'
Install-Task 'arena-desk-open' $ps $launchArgs
$desktop=[Environment]::GetFolderPath('Desktop')
$w=New-Object -ComObject WScript.Shell
$link=$w.CreateShortcut((Join-Path $desktop 'Arena Desk.lnk'))
$link.TargetPath=$ps; $link.Arguments=$launchArgs; $link.WorkingDirectory=$root; $link.WindowStyle=7; $link.Description='Local control panel - permanent hub protected'; $link.Save()
Set-Content -LiteralPath (Join-Path $desktop 'Notion Console.url') -Value "[InternetShortcut]`r`nURL=https://app.notion.com/p/407186af12d381cf97eeebf4ec37f0c9" -Encoding ASCII
# Optional extras are registered only when the installer reports completion.
$stateFile=Join-Path $root 'data\install-state.json'
$rows=@(); if (Test-Path $stateFile) { $rows=@(Get-Content $stateFile -Raw | ConvertFrom-Json) }
$finished=@($rows | Where-Object {$_.name -eq 'installer' -and $_.status -eq 'finished'}).Count -gt 0
if ($finished) {
    $dsh=@($rows | Where-Object {$_.name -eq 'dsh-host'}) | Select-Object -Last 1
    if ($dsh.status -eq 'installed') {
        Install-Task 'arena-dsh-web' $ps ('-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "'+$root+'\launch_dsh.ps1"') $true
        Install-Task 'arena-dsh-open' $ps ('-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "'+$root+'\open_dsh.ps1"')
    }
    $pet=@($rows | Where-Object {$_.name -eq 'desktop-pet'}) | Select-Object -Last 1
    if ($pet.status -eq 'installed' -and (Test-Path $pet.exe)) {
        Install-Task 'arena-desktop-pet' $ps ('-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "'+$root+'\launch_pet.ps1"') $true
    }
}
Start-Sleep -Seconds 3
$r=Invoke-RestMethod 'http://127.0.0.1:18765/api/state' -TimeoutSec 10
@{panel_http_ok=$true;session_count=@($r.sessions).Count;tasks=$r.tasks;install_state=$rows;desktop=$desktop;hub=(Get-ScheduledTask -TaskName 'git-sync-hub' -TaskPath '\' | Select-Object TaskName,State)} | ConvertTo-Json -Depth 6
Start-Process $ps -ArgumentList $launchArgs -WindowStyle Hidden
