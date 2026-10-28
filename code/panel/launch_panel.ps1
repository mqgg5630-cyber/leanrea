$ErrorActionPreference='Stop'
$t=Get-ScheduledTask -TaskName 'arena-desk-panel' -TaskPath '\'
if ([string]$t.State -ne 'Running') { Start-ScheduledTask -TaskName 'arena-desk-panel' -TaskPath '\' }
for ($i=0; $i -lt 15; $i++) {
    try {
        $r=Invoke-WebRequest 'http://127.0.0.1:18765/api/bootstrap' -UseBasicParsing -TimeoutSec 2
        if ($r.StatusCode -eq 200) { Start-Process 'http://127.0.0.1:18765'; exit 0 }
    } catch {}
    Start-Sleep -Seconds 1
}
throw 'Panel service did not become ready; permanent hub was not modified.'
