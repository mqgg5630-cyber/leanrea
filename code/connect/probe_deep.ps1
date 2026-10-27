#Requires -Version 5.1
<#
.SYNOPSIS
    Second-hop recon: WSL (previous HPC access route), PuTTY tools, saved secrets,
    and a verbose handshake against 192.168.1.109. ASCII only.
#>
$ErrorActionPreference = 'Continue'
function Line([string]$k, [string]$v) { Write-Output ('{0}={1}' -f $k, $v) }

# ---- WSL -------------------------------------------------------------------
$wsl = Get-Command wsl.exe -ErrorAction SilentlyContinue
Line 'WSL_CMD' ([string]([bool]$wsl))
if ($wsl) {
    $d = (& wsl.exe -l -v 2>&1) -join ' ; '
    Line 'WSL_DISTROS' (($d -replace '\s+', ' ') -replace '[^\x20-\x7E]', '')
    $t = (& wsl.exe -e bash -lc 'echo USER=$USER; hostname; ls -1 ~/.hpc_pass 2>/dev/null; command -v sshpass ssh rsync; grep -c . ~/.ssh/authorized_keys 2>/dev/null; ls ~/.ssh 2>/dev/null | head' 2>&1) -join ' ; '
    Line 'WSL_PROBE' (($t -replace '\s+', ' ').Substring(0, [Math]::Min(400, ($t -replace '\s+', ' ').Length)))
    $h = (& wsl.exe -e bash -lc 'cat ~/.ssh/config 2>/dev/null | head -40' 2>&1) -join ' | '
    Line 'WSL_SSH_CONFIG' (($h -replace '\s+', ' ').Substring(0, [Math]::Min(400, ($h -replace '\s+', ' ').Length)))
}

# ---- PuTTY / other clients ------------------------------------------------
foreach ($c in @('plink.exe', 'pscp.exe', 'sshpass.exe', 'rsync.exe', 'wt.exe')) {
    $cmd = Get-Command $c -ErrorAction SilentlyContinue
    Line ('CMD ' + $c) ($(if ($cmd) { $cmd.Source } else { 'missing' }))
}

# ---- saved secrets on this host -------------------------------------------
$cand = @("$env:USERPROFILE\.hpc_pass", "$env:USERPROFILE\.ssh\.hpc_pass", 'D:\.hpc_pass', 'E:\.hpc_pass')
foreach ($p in $cand) { if (Test-Path -LiteralPath $p) { Line ('PASSFILE ' + $p) ('bytes=' + (Get-Item $p).Length) } }
$cred = @(& cmdkey.exe /list 2>&1 | Where-Object { $_ -match 'Target|目标' } | Select-Object -First 12)
Line 'CMDLIST' ((($cred -join ' ; ') -replace '\s+', ' ') -replace '[^\x20-\x7E]', '')

# ---- verbose handshake: 192.168.1.109 -------------------------------------
$v = & ssh.exe -vv -o BatchMode=yes -o StrictHostKeyChecking=accept-new -o ConnectTimeout=8 `
        -o IdentitiesOnly=yes -i "$env:USERPROFILE\.ssh\id_ed25519" BNI@192.168.1.109 'echo OK' 2>&1
$keep = @($v | Where-Object { $_ -match 'Remote protocol|remote software|kex:|Authentications that can continue|Authenticated|Permission denied|banner|Connection closed|debug1: Connecting|Server host key' } | Select-Object -First 12)
Line 'SSH_VV_192_168_1_109' ((($keep -join ' ;; ') -replace '\s+', ' ').Substring(0, [Math]::Min(700, ($keep -join ' ;; ').Length)))

# ---- route to campus HPC --------------------------------------------------
$r = (& tracert.exe -h 6 -w 800 10.10.5.210 2>&1) -join ' ; '
Line 'TRACERT_10_10_5_210' ((($r -replace '\s+', ' ') -replace '[^\x20-\x7E]', '').Substring(0, [Math]::Min(500, ($r -replace '\s+', ' ').Length)))
Line 'ROUTE_10' ((& route.exe print -4 2>&1 | Select-String -Pattern '^\s+10\.|10\.10' | Select-Object -First 5) -join ' ;; ')

# ---- VPN clients present --------------------------------------------------
$vpnclients = @()
foreach ($p in @('C:\Program Files (x86)\Sangfor', 'C:\Program Files\Sangfor', 'C:\Program Files (x86)\EasyConnect',
                 'C:\Program Files\OpenVPN', 'C:\Program Files (x86)\OpenVPN', 'C:\Program Files\Fortinet')) {
    if (Test-Path -LiteralPath $p) { $vpnclients += $p }
}
Line 'VPN_CLIENTS' (($vpnclients -join ' | ') -replace '^$', 'none')
Line 'SECOND_RECON_DONE' 'True'
