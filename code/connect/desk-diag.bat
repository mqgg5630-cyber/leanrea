@echo off
REM Collect a one-shot diagnosis on the DESKTOP PC.
REM Run it there (double-click), it writes desk-diag.txt next to this file and opens it.
REM Send that txt back. ASCII-only on purpose so cmd never shows mojibake.
setlocal
set OUT=%~dp0desk-diag.txt
set TS=C:\Program Files\Tailscale\tailscale.exe
if not exist "%TS%" set TS=C:\Program Files (x86)\Tailscale\tailscale.exe

(
echo ================ WHEN ================
date /t
time /t
echo(
echo ================ HOST ================
hostname
whoami
ver
echo(
echo ================ IP CONFIG ================
ipconfig /all
echo(
echo ================ GATEWAY / INTERNET ================
ipconfig | findstr /i "Gateway"
ping -n 2 192.168.1.1
ping -n 2 223.5.5.5
ping -n 3 www.baidu.com
echo(
echo ================ DNS ================
nslookup www.baidu.com
echo(
echo ================ PROXY SETTINGS ================
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyServer
set | findstr /i proxy
echo(
echo ================ VPN / TUN PROCS ================
tasklist | findstr /i "v2ray xray sing-box clash wireguard openvpn easyconnect sangfor"
echo(
echo ================ SERVICES ================
sc query Tailscale
sc query SunloginService
sc query SunloginRemoteService
echo(
echo ================ TAILSCALE STATUS ================
if exist "%TS%" "%TS%" status
if exist "%TS%" "%TS%" netcheck
echo(
echo ================ WINDOWS UPTIME / LAST BOOT ================
systeminfo | findstr /i "Boot Time System Boot Time"
echo(
echo ================ POWER ================
powercfg /a
) > "%OUT%" 2>&1

echo.
echo Diag written to: %OUT%
echo Open it, then send the file back.
notepad "%OUT%"
endlocal
