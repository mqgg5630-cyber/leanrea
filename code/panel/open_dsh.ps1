# Read the locally generated launch URL. Never print or sync its bootstrap token.
$ErrorActionPreference='Stop'
$log='E:\0apps\ArenaDesk\data\dsh-runtime.log'
for ($i=0; $i -lt 20; $i++) {
    $t=Get-ScheduledTask -TaskName 'arena-dsh-web' -TaskPath '\' -ErrorAction SilentlyContinue
    if (-not $t -or [string]$t.State -eq 'Disabled') { exit 0 }
    if (Test-Path $log) {
        $text=Get-Content $log -Raw
        $m=[regex]::Match($text,'http://127\.0\.0\.1:3080/\?token=[A-Za-z0-9_-]+')
        if ($m.Success) {
            try {
                $r=Invoke-WebRequest $m.Value -UseBasicParsing -TimeoutSec 3
                if ($r.StatusCode -eq 200) { Start-Process $m.Value; exit 0 }
            } catch {}
        }
    }
    Start-Sleep -Seconds 1
}
throw 'DSH is not ready; enable its optional task first.'
