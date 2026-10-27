#Requires -Version 5.1
<#
.SYNOPSIS
    Run the WSL probe script in every installed distro and collect the output
    into results\jev-monitor\wsl-<distro>.txt. ASCII only.
#>
$ErrorActionPreference = 'Continue'
$src = 'E:\0apps\jev-chat-windows\tools\wsl_probe.sh'
$repo = (Get-Location).Path
$outDir = Join-Path $repo 'results\jev-monitor'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

if (-not (Test-Path -LiteralPath $src)) { Write-Output 'MISSING_SCRIPT'; exit 2 }
# hub checkout may have CRLF; WSL bash needs LF
$txt = [IO.File]::ReadAllText($src).Replace("`r", "")
[IO.File]::WriteAllText($src, $txt)

$mnt = '/mnt/' + $repo.Substring(0, 1).ToLower() + (($repo.Substring(2)) -replace '\\', '/')

foreach ($d in @('Ubuntu-26.04', 'Ubuntu-24.04')) {
    $dest = '/mnt/e/wsl-' + $d + '.txt'
    $winDest = 'E:\wsl-' + $d + '.txt'
    Remove-Item -LiteralPath $winDest -Force -ErrorAction SilentlyContinue
    $p = Start-Process -FilePath 'wsl.exe' -ArgumentList @('-d', $d, '-e', 'bash', $mnt + '/tools/wsl_probe.sh', $dest) `
            -WindowStyle Hidden -Wait -PassThru
    $len = 0
    if (Test-Path -LiteralPath $winDest) { $len = (Get-Item $winDest).Length }
    Write-Output ('DISTRO ' + $d + ' exit=' + $p.ExitCode + ' bytes=' + $len)
    if ($len -gt 0) { Copy-Item -LiteralPath $winDest -Destination (Join-Path $outDir ('wsl-' + $d + '.txt')) -Force }
}

Write-Output 'RUNNER_DONE'
