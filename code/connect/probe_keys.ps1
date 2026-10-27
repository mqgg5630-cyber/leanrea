#Requires -Version 5.1
<#
.SYNOPSIS
    Try every plausible key against each target, and check whether the keys are
    passphrase-protected / whether an ssh-agent holds anything. No passwords are
    ever prompted for (BatchMode stays on). ASCII only.
#>
$ErrorActionPreference = 'Continue'
function Line([string]$k, [string]$v) { Write-Output ('{0}={1}' -f $k, $v) }

$sshDir = Join-Path $env:USERPROFILE '.ssh'
$agent = & ssh-add.exe -l 2>&1
Line 'SSH_AGENT_KEYS' (($agent -join ' ; ') -replace '\s+', ' ')

foreach ($k in @('id_ed25519', 'id_rsa', 'id_ed25519_shaohua', 'id_ed25519_mqgg', 'vs1_dk', 'zz_key', 'id_ed25519_light_skills')) {
    $p = Join-Path $sshDir $k
    if (-not (Test-Path -LiteralPath $p)) { continue }
    $first = (Get-Content -LiteralPath $p -TotalCount 3 -ErrorAction SilentlyContinue) -join ' '
    $enc = 'no'
    if ($first -match 'ENCRYPTED|Proc-Type: 4,ENCRYPTED') { $enc = 'yes' }
    $pub = Join-Path $sshDir ($k + '.pub')
    $fp = ''
    if (Test-Path -LiteralPath $pub) {
        $fp = ((& ssh-keygen.exe -l -f $pub 2>&1) -join ' ')
        if ($fp.Length -gt 90) { $fp = $fp.Substring(0, 90) }
    }
    Line ('KEY ' + $k) ('encrypted=' + $enc + ' :: ' + ($fp -replace '\s+', ' '))
}

$cases = @(
    @{ name = 'desktop_lan'; host = '192.168.1.109'; port = 22; user = 'BNI'; keys = @('id_rsa', 'id_ed25519') },
    @{ name = 'hpc_paratera'; host = 'wheshell.hpccube.com'; port = 65032; user = 'scnlizwblw'; keys = @('vs1_dk', 'id_ed25519', 'id_rsa') },
    @{ name = 'hpc_scnet'; host = 'zzeshell.scnet.cn'; port = 65032; user = 'sdldyh'; keys = @('zz_key', 'id_ed25519', 'id_rsa') }
)

foreach ($c in $cases) {
    foreach ($k in $c.keys) {
        $keyPath = Join-Path $sshDir $k
        if (-not (Test-Path -LiteralPath $keyPath)) { continue }
        $out = & ssh.exe -o BatchMode=yes -o StrictHostKeyChecking=accept-new -o ConnectTimeout=8 `
                 -o IdentitiesOnly=yes -i $keyPath -p $c.port ($c.user + '@' + $c.host) `
                 'echo AUTH_OK; hostname; whoami' 2>&1
        $code = $LASTEXITCODE
        $joined = (($out -join ' | ') -replace '\s+', ' ')
        if ($joined.Length -gt 160) { $joined = $joined.Substring(0, 160) }
        Line ('TRY ' + $c.name + ' key=' + $k) ('exit=' + $code + ' :: ' + $joined)
        if ($code -eq 0) { break }
    }
}
Line 'KEYPROBE_DONE' 'True'
