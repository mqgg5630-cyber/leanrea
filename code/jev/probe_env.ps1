#Requires -Version 5.1
<#
.SYNOPSIS
    Read-only environment probe for the jev-chat-windows deployment.
    ASCII only (the repo gate requires it). Prints one "KEY=VALUE" line per fact
    so the agent side can parse the hub receipt.
#>
$ErrorActionPreference = 'Continue'
$ProgressPreference    = 'SilentlyContinue'

function Line([string]$k, [string]$v) { Write-Output ("{0}={1}" -f $k, $v) }

Line 'COMPUTER'   $env:COMPUTERNAME
Line 'USER'       $env:USERNAME
try {
    $os = Get-CimInstance Win32_OperatingSystem
    Line 'OS'      ($os.Caption + ' build ' + $os.BuildNumber)
    Line 'OS_ARCH' $os.OSArchitecture
} catch { Line 'OS' 'unknown' }
Line 'PS'         $PSVersionTable.PSVersion.ToString()
Line 'NOW_LOCAL'  (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

# ---- python candidates -------------------------------------------------------
$cands = @(
    'E:\spider\python.exe',
    'E:\miniconda3\python.exe',
    'C:\Python313\python.exe',
    'C:\Python312\python.exe',
    'C:\Python311\python.exe',
    'C:\Python310\python.exe'
)
foreach ($c in $cands) {
    if (Test-Path -LiteralPath $c) {
        $v = (& $c -c "import sys,platform;print(sys.version.split()[0],platform.architecture()[0])" 2>&1) -join ' '
        Line ('PY ' + $c) ($v.Trim())
    }
}
foreach ($name in @('python.exe', 'python3.exe', 'py.exe')) {
    $cmd = Get-Command $name -ErrorAction SilentlyContinue
    if ($cmd) { Line ('PATH ' + $name) $cmd.Source }
}

# ---- git / node --------------------------------------------------------------
$git = Get-Command git.exe -ErrorAction SilentlyContinue
if ($git) { Line 'GIT' ((& $git.Source --version 2>&1) -join ' ') } else { Line 'GIT' 'missing' }
$node = Get-Command node.exe -ErrorAction SilentlyContinue
if ($node) { Line 'NODE' ((& $node.Source --version 2>&1) -join ' ') } else { Line 'NODE' 'missing' }

# ---- disk --------------------------------------------------------------------
try {
    Get-PSDrive -PSProvider FileSystem -ErrorAction SilentlyContinue | ForEach-Object {
        if ($_.Free -ne $null) {
            Line ('DISK ' + $_.Name + ':') ([string]([math]::Round($_.Free / 1GB, 1)) + ' GB free')
        }
    }
} catch {}

# ---- pypi reachability / mirror ---------------------------------------------
try {
    $r = Invoke-WebRequest -Uri 'https://pypi.org/simple/' -UseBasicParsing -TimeoutSec 12 -Method Head
    Line 'PYPI' ('ok ' + $r.StatusCode)
} catch { Line 'PYPI' ('fail ' + $_.Exception.Message.Substring(0, [Math]::Min(60, $_.Exception.Message.Length))) }
try {
    $m = Invoke-WebRequest -Uri 'https://pypi.tuna.tsinghua.edu.cn/simple/' -UseBasicParsing -TimeoutSec 12 -Method Head
    Line 'MIRROR_TUNA' ('ok ' + $m.StatusCode)
} catch { Line 'MIRROR_TUNA' 'fail' }

# ---- chat apps ---------------------------------------------------------------
$procs = @(Get-Process -ErrorAction SilentlyContinue | Where-Object {
    $_.ProcessName -match '^(wechat|weixin|wechatappex|kakaotalk)$' } | ForEach-Object {
        '{0}(pid {1})' -f $_.ProcessName, $_.Id })
Line 'CHAT_PROCS' (($procs -join ', ') -replace '^$', 'none')
$inst = @()
foreach ($p in @(
    'C:\Program Files\Tencent\WeChat\WeChat.exe',
    'C:\Program Files (x86)\Tencent\WeChat\WeChat.exe',
    'C:\Program Files\Tencent\Weixin\Weixin.exe',
    'C:\Program Files (x86)\Tencent\Weixin\Weixin.exe',
    "$env:LOCALAPPDATA\Programs\WeChat\WeChat.exe",
    "$env:APPDATA\..\Local\Programs\Weixin\Weixin.exe",
    'C:\Program Files (x86)\Kakao\KakaoTalk\KakaoTalk.exe',
    'C:\Program Files\Kakao\KakaoTalk\KakaoTalk.exe'
)) {
    if (Test-Path -LiteralPath $p) { $inst += $p }
}
Line 'CHAT_INSTALLED' (($inst -join ' | ') -replace '^$', 'none')

# ---- existing layout ---------------------------------------------------------
foreach ($d in @('E:\0github', 'E:\0github\apps', 'E:\0github\results', [Environment]::GetFolderPath('Desktop'), 'E:\spider')) {
    if (Test-Path -LiteralPath $d) { Line ('HAS ' + $d) 'yes' } else { Line ('HAS ' + $d) 'no' }
}
try {
    $top = @(Get-ChildItem -LiteralPath 'E:\0github' -Force -ErrorAction SilentlyContinue |
             Select-Object -First 20 | ForEach-Object { $_.Name })
    Line 'E0GITHUB_TOP' ($top -join ', ')
} catch { Line 'E0GITHUB_TOP' 'unreadable' }

# ---- scheduled tasks ---------------------------------------------------------
try {
    $t = @(Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object {
        $_.TaskName -match 'git-sync|jev' } | ForEach-Object { $_.TaskName + ':' + $_.State })
    Line 'TASKS' (($t -join ', ') -replace '^$', 'none')
} catch { Line 'TASKS' 'unknown' }

# ---- existing keys (names only, never values) --------------------------------
foreach ($k in @('JEV_API_KEY', 'LLM_API_KEY')) {
    $has = [bool]([Environment]::GetEnvironmentVariable($k, 'User'))
    Line ('KEY ' + $k) ($(if ($has) { 'set' } else { 'missing' }))
}

# ---- hub state ---------------------------------------------------------------
$hubState = Join-Path $env:USERPROFILE '.git-sync-hub\hub-state.json'
if (Test-Path -LiteralPath $hubState) { Line 'HUB_STATE' 'present' } else { Line 'HUB_STATE' 'missing' }
$seen = Join-Path $env:USERPROFILE '.git-sync-hub\seen-heads.json'
if (Test-Path -LiteralPath $seen) {
    try { Line 'SEEN_KEYS' ((Get-Content -LiteralPath $seen -Raw -Encoding UTF8 | ConvertFrom-Json).PSObject.Properties.Name -join ', ') } catch {}
}

Line 'PROBE_DONE' 'True'
