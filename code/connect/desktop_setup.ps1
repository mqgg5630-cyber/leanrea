#Requires -Version 5.1
<#
.SYNOPSIS
    One-shot setup for the DESKTOP PC: git clone this repo, bring Tailscale back
    online, enable OpenSSH Server, trust the laptop's keys, stop it from sleeping.

.DESCRIPTION
    Run this ON THE DESKTOP, in an elevated PowerShell. It is idempotent - safe to
    run twice. Everything it touches:
      * git       : installs via winget only if missing, then clones the public repo
      * Tailscale : starts the service, runs `tailscale up` if logged out
      * sshd      : adds the OpenSSH.Server capability, service auto-start, firewall
      * keys      : installs the laptop's two public keys for passwordless login
      * power     : disables sleep/hibernate on AC so the machine stays reachable
    A report is written to the Desktop as desktop-setup-report.txt.
    ASCII only (the repo gate requires it).

.PARAMETER RepoRoot
    Where to put the repo. Default F:\0wsh\leanrea

.PARAMETER Branch
    Branch to check out. Default arena/4d729933-leanrea
#>
[CmdletBinding()]
param(
    [string]$RepoRoot = 'F:\0wsh\leanrea',
    [string]$Branch = 'arena/4d729933-leanrea',
    [string]$HostName = 'desktop-ieudgs5'
)

$ErrorActionPreference = 'Continue'
$ProgressPreference = 'SilentlyContinue'
$log = New-Object System.Collections.Generic.List[string]
function Say([string]$m) {
    Write-Host $m
    $script:log.Add(('{0} {1}' -f (Get-Date -Format 'HH:mm:ss'), $m))
}

# ---- 0. elevation ---------------------------------------------------------
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
           ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
Say '=============================================='
Say '  DESKTOP SETUP - laptop <-> desktop bridge'
Say '=============================================='
Say ('host     = ' + $env:COMPUTERNAME)
Say ('user     = ' + $env:USERNAME)
Say ('admin    = ' + $isAdmin)
Say ('target   = ' + $RepoRoot + ' @ ' + $Branch)
if (-not $isAdmin) {
    Say 'NOT elevated - relaunching as Administrator...'
    try {
        $args = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-NoExit', '-File', ('"' + $PSCommandPath + '"'),
                  '-RepoRoot', ('"' + $RepoRoot + '"'), '-Branch', ('"' + $Branch + '"'))
        Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList $args
    } catch { Say ('elevation failed: ' + $_.Exception.Message) }
    exit 1
}

# ---- 1. git ---------------------------------------------------------------
$git = Get-Command git.exe -ErrorAction SilentlyContinue
if (-not $git) {
    Say '[1/6] git missing - installing via winget (2-3 min)...'
    & winget.exe install --id Git.Git -e --silent --accept-package-agreements --accept-source-agreements 2>&1 |
        ForEach-Object { Say ('      ' + $_) }
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
                [Environment]::GetEnvironmentVariable('Path', 'User')
    $git = Get-Command git.exe -ErrorAction SilentlyContinue
}
if ($git) { Say ('[1/6] git ok: ' + (& git.exe --version)) } else { Say '[1/6] git STILL MISSING - install manually, rest continues' }

# ---- 2. clone the repo (public, no credentials needed) --------------------
Say ('[2/6] repo -> ' + $RepoRoot)
New-Item -ItemType Directory -Force -Path $RepoRoot | Out-Null
$candidates = @(
    'https://github.com/mqgg5630-cyber/leanrea.git',
    'https://gh-proxy.com/https://github.com/mqgg5630-cyber/leanrea.git',
    'https://ghfast.top/https://github.com/mqgg5630-cyber/leanrea.git'
)
if (Test-Path (Join-Path $RepoRoot '.git')) {
    Say '      already cloned, fetching'
    Push-Location $RepoRoot
    & git.exe fetch --all --prune 2>&1 | ForEach-Object { Say ('      ' + $_) }
    & git.exe checkout $Branch 2>&1 | ForEach-Object { Say ('      ' + $_) }
    & git.exe pull --ff-only 2>&1 | ForEach-Object { Say ('      ' + $_) }
    Pop-Location
} else {
    $ok = $false
    foreach ($url in $candidates) {
        Say ('      trying ' + $url)
        & git.exe clone --branch $Branch --depth 1 $url $RepoRoot 2>&1 | ForEach-Object { Say ('      ' + $_) }
        if ($LASTEXITCODE -eq 0 -and (Test-Path (Join-Path $RepoRoot '.git'))) { $ok = $true; Say '      clone OK'; break }
        if (Test-Path $RepoRoot) { Remove-Item $RepoRoot -Recurse -Force -ErrorAction SilentlyContinue }
    }
    if (-not $ok) { Say '      CLONE FAILED on every mirror - check network, then rerun this script' }
}

# ---- 3. Tailscale --------------------------------------------------------
Say '[3/6] Tailscale'
$ts = @('C:\Program Files\Tailscale\tailscale.exe', 'C:\Program Files (x86)\Tailscale\tailscale.exe',
        'E:\Tailscale\tailscale.exe') | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
if (-not $ts) {
    Say '      not installed - installing via winget...'
    & winget.exe install --id Tailscale.Tailscale -e --silent --accept-package-agreements --accept-source-agreements 2>&1 |
        ForEach-Object { Say ('      ' + $_) }
    $ts = @('C:\Program Files\Tailscale\tailscale.exe', 'C:\Program Files (x86)\Tailscale\tailscale.exe') |
          Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
}
if (-not $ts) {
    Say '      tailscale.exe NOT FOUND - install from https://tailscale.com/download/windows and rerun'
} else {
    Say ('      exe = ' + $ts)
    $svc = Get-Service -Name 'Tailscale' -ErrorAction SilentlyContinue
    if ($svc) {
        Say ('      service = ' + $svc.Status)
        if ($svc.Status -ne 'Running') { Start-Service -Name 'Tailscale' -ErrorAction SilentlyContinue; Start-Sleep 3 }
        Set-Service -Name 'Tailscale' -StartupType Automatic -ErrorAction SilentlyContinue
    } else { Say '      service missing (unusual) - try rebooting after this script' }
    $st = (& $ts status 2>&1) -join ' ; '
    Say ('      status = ' + (($st -replace '\s+', ' ') -replace '[^\x20-\x7E]', ''))
    if ($st -match 'Logged out|NeedsLogin|not logged in|stopped') {
        Say '      bringing it up (a browser window will ask you to log in)'
        & $ts up --hostname=$HostName --accept-routes 2>&1 | ForEach-Object { Say ('      ' + $_) }
        Start-Sleep 5
        $st2 = (& $ts status 2>&1) -join ' ; '
        Say ('      status after up = ' + (($st2 -replace '\s+', ' ') -replace '[^\x20-\x7E]', ''))
    }
    $ip = (& $ts ip -4 2>&1) -join ''
    Say ('      tailscale ip = ' + ($ip -replace '\s+', ''))
}

# ---- 4. OpenSSH Server ---------------------------------------------------
Say '[4/6] OpenSSH Server'
$cap = Get-WindowsCapability -Online -Name 'OpenSSH.Server~~~~0.0.1.0' -ErrorAction SilentlyContinue
Say ('      capability = ' + $(if ($cap) { $cap.State } else { 'unknown' }))
if ($cap -and $cap.State -ne 'Installed') {
    Say '      installing capability (1-3 min)...'
    Add-WindowsCapability -Online -Name 'OpenSSH.Server~~~~0.0.1.0' -ErrorAction SilentlyContinue |
        ForEach-Object { Say ('      ' + $_) }
}
Set-Service -Name sshd -StartupType Automatic -ErrorAction SilentlyContinue
Start-Service -Name sshd -ErrorAction SilentlyContinue
Start-Sleep 2
$sshd = Get-Service -Name sshd -ErrorAction SilentlyContinue
Say ('      sshd = ' + $(if ($sshd) { $sshd.Status } else { 'MISSING' }))
$rule = Get-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -ErrorAction SilentlyContinue
if (-not $rule) {
    New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' -Enabled True `
        -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 -ErrorAction SilentlyContinue | Out-Null
    Say '      firewall rule added'
} else { Say '      firewall rule already present' }
# make sshd bind on all profiles, default shell stays cmd (harmless)
Set-Service -Name sshd -StartupType Automatic -ErrorAction SilentlyContinue

# ---- 5. trust the laptop's keys -----------------------------------------
Say '[5/6] authorized keys'
$keys = @(
    'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOs0Nm0C4YKZ/L57uAbv9XBZDy8pqAM0P7jCMt0EEEGg laptop-wsl',
    'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEcvrvBvxgT71o7C+poN8QOXuOLgq+qiqtcWXowoAY4C laptop-win'
)
$adminKeyFile = 'C:\ProgramData\ssh\administrators_authorized_keys'
$userKeyFile = Join-Path $env:USERPROFILE '.ssh\authorized_keys'
New-Item -ItemType Directory -Force -Path (Split-Path $userKeyFile) | Out-Null
$existing = @()
foreach ($f in @($adminKeyFile, $userKeyFile)) { if (Test-Path $f) { $existing += Get-Content -LiteralPath $f } }
foreach ($k in $keys) {
    $tag = ($k -split ' ')[-1]
    if ($existing -match [regex]::Escape($tag)) { Say ('      already trusted: ' + $tag); continue }
    Add-Content -LiteralPath $adminKeyFile -Value $k -Encoding ASCII
    Add-Content -LiteralPath $userKeyFile -Value $k -Encoding ASCII
    Say ('      added: ' + $tag)
}
if (Test-Path $adminKeyFile) {
    & icacls.exe $adminKeyFile /inheritance:r /grant 'Administrators:F' /grant 'SYSTEM:F' 2>&1 | Out-Null
    Say '      acl fixed on administrators_authorized_keys'
}
Restart-Service -Name sshd -ErrorAction SilentlyContinue
Restart-Service -Name Tailscale -ErrorAction SilentlyContinue

# ---- 6. keep it awake ----------------------------------------------------
Say '[6/6] power settings'
& powercfg.exe /change standby-timeout-ac 0 2>&1 | Out-Null
& powercfg.exe /change hibernate-timeout-ac 0 2>&1 | Out-Null
& powercfg.exe /change disk-timeout-ac 0 2>&1 | Out-Null
& powercfg.exe /change monitor-timeout-ac 15 2>&1 | Out-Null
& powercfg.exe /hibernate off 2>&1 | Out-Null
Say '      sleep/hibernate disabled on AC, monitor off after 15 min'

# ---- report -------------------------------------------------------------
$rep = Join-Path ([Environment]::GetFolderPath('Desktop')) 'desktop-setup-report.txt'
$summary = @(
    'DESKTOP SETUP REPORT',
    ('time     : ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')),
    ('host     : ' + $env:COMPUTERNAME),
    ('user     : ' + $env:USERNAME),
    ('repo     : ' + $RepoRoot),
    ('git      : ' + $(try { (& git.exe --version 2>&1) -join '' } catch { 'n/a' })),
    ('ts exe   : ' + $ts),
    ('ts ip    : ' + $(try { (& $ts ip -4 2>&1) -join '' } catch { 'n/a' })),
    ('sshd     : ' + $(try { (Get-Service sshd).Status } catch { 'n/a' })),
    ('tailscale: ' + $(try { (Get-Service Tailscale).Status } catch { 'n/a' })),
    '',
    '--- log ---'
) + $log
$summary | Set-Content -LiteralPath $rep -Encoding UTF8
Say ''
Say ('report written: ' + $rep)
Say ''
Say 'NEXT: go back to the laptop and tell the agent the desktop setup finished.'
Say 'The laptop will then reach this machine at its tailscale ip on port 22.'
