for ($i=0; $i -lt 30; $i++) {
    $t=Get-ScheduledTask -TaskName 'arena-dsh-web' -TaskPath '\' -ErrorAction SilentlyContinue
    if (-not $t -or [string]$t.State -eq 'Disabled') { exit 0 }
    try {
        $r=Invoke-WebRequest 'http://127.0.0.1:3080/' -UseBasicParsing -TimeoutSec 2
        if ($r.StatusCode -eq 200) { Start-Process 'http://127.0.0.1:3080'; exit 0 }
    } catch {}
    Start-Sleep -Seconds 2
}
