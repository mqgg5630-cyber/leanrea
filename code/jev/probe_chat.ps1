#Requires -Version 5.1
<#
.SYNOPSIS
    Second probe: which chat app is actually installed/running on the host, and where.
    ASCII only, read-only, bounded runtime (< 120 s).
#>
$ErrorActionPreference = 'Continue'
$ProgressPreference    = 'SilentlyContinue'
function Line([string]$k, [string]$v) { Write-Output ("{0}={1}" -f $k, $v) }

Line 'PROBE_CHAT_START' (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

# ---- 1. installed programs from the uninstall registry ------------------------
$pat = 'wechat|weixin|tencent|kakao|telegram|dingtalk|feishu|lark|slack|discord|qq'
$keys = @(
    'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
)
$found = @()
foreach ($k in $keys) {
    try {
        $found += Get-ItemProperty -Path $k -ErrorAction SilentlyContinue |
            Where-Object { $_.DisplayName -and ($_.DisplayName -match $pat) } |
            ForEach-Object { '{0} :: {1}' -f $_.DisplayName, $_.InstallLocation }
    } catch {}
}
$found = @($found | Sort-Object -Unique)
Line 'INSTALLED_APPS' (($found -join ' || ') -replace '^$', 'none')

# ---- 2. running windows ------------------------------------------------------
try {
    $wins = @(Get-Process -ErrorAction SilentlyContinue |
        Where-Object { $_.MainWindowTitle } |
        ForEach-Object { '{0}:{1}' -f $_.ProcessName, $_.MainWindowTitle })
    Line 'WINDOWS' (($wins | Select-Object -First 25) -join ' || ')
} catch { Line 'WINDOWS' 'unreadable' }

# ---- 3. shortcuts on the desktops / start menu -------------------------------
$lnks = @()
foreach ($d in @("$env:USERPROFILE\Desktop", "$env:PUBLIC\Desktop",
                 "$env:APPDATA\Microsoft\Windows\Start Menu\Programs",
                 "$env:ProgramData\Microsoft\Windows\Start Menu\Programs")) {
    if (Test-Path -LiteralPath $d) {
        try {
            $lnks += Get-ChildItem -LiteralPath $d -Filter *.lnk -Recurse -Depth 2 -ErrorAction SilentlyContinue |
                Select-Object -First 200 | ForEach-Object { $_.BaseName }
        } catch {}
    }
}
$hit = @($lnks | Where-Object { $_ -match 'wechat|weixin|weixin|tencent|kakao|qq|chat' } | Sort-Object -Unique)
Line 'SHORTCUTS' (($hit -join ', ') -replace '^$', 'none')

# ---- 4. bounded exe search ---------------------------------------------------
$roots = @('C:\Program Files', 'C:\Program Files (x86)',
           'C:\Users\' + $env:USERNAME + '\AppData\Local\Programs',
           'C:\Users\' + $env:USERNAME + '\AppData\Roaming',
           'D:\Program Files', 'D:\Program Files (x86)', 'D:\Software', 'D:\Apps',
           'E:\Program Files', 'E:\Program Files (x86)', 'E:\Software', 'E:\Apps',
           'E:\hermes')
$exeHits = @()
$names = @('Weixin.exe', 'WeChat.exe', 'KakaoTalk.exe', 'QQ.exe', 'Telegram.exe')
foreach ($r in $roots) {
    if (-not (Test-Path -LiteralPath $r)) { continue }
    foreach ($n in $names) {
        try {
            $exeHits += Get-ChildItem -LiteralPath $r -Filter $n -Recurse -Depth 4 -File -ErrorAction SilentlyContinue |
                Select-Object -First 3 | ForEach-Object { $_.FullName }
        } catch {}
    }
}
Line 'EXE_HITS' (($exeHits | Sort-Object -Unique | Select-Object -First 10) -join ' || ')

# ---- 5. chat data folders ---------------------------------------------------
$dataDirs = @(
    "$env:USERPROFILE\Documents\WeChat Files",
    "$env:USERPROFILE\Documents\xwechat_files",
    "$env:USERPROFILE\Documents\Tencent Files",
    "$env:USERPROFILE\Documents\KakaoTalk",
    "$env:APPDATA\Tencent",
    "$env:LOCALAPPDATA\Tencent"
)
$have = @()
foreach ($d in $dataDirs) { if (Test-Path -LiteralPath $d) { $have += $d } }
Line 'DATA_DIRS' (($have -join ' || ') -replace '^$', 'none')

# ---- 6. desktop path sanity (no non-ASCII literals: resolve at runtime) ------
$deskUser = [Environment]::GetFolderPath('Desktop')
Line 'DESKTOP_CS' $deskUser
try {
    $d = Get-Item -LiteralPath $deskUser -ErrorAction Stop
    Line 'DESKTOP_EXISTS' 'yes'
    Line 'DESKTOP_FULLNAME' $d.FullName
    Line 'DESKTOP_ITEMS' ((@(Get-ChildItem -LiteralPath $d -Force -ErrorAction SilentlyContinue |
        Select-Object -First 8 | ForEach-Object { $_.Name })) -join ', ')
} catch { Line 'DESKTOP_EXISTS' 'no' }

Line 'PROBE_CHAT_DONE' 'True'
