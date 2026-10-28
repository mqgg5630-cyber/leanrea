# Arena Desk delivery — 2026-10-28

## Live Windows deployment

- Host: LAPTOP-R77M5D6M (not the separate desktop PC).
- App: `E:\0apps\ArenaDesk`, loopback HTTP `127.0.0.1:18765`.
- Desktop: `Arena Desk.lnk`, `Notion Console.url`, `Toggle Desktop Pet.lnk` (Ctrl+Alt+H).
- Tasks: arena-desk-panel + arena-desk-open; optional arena-dsh-web/open + arena-desktop-pet.
- Existing permanent git-sync-hub kept running, not reconfigured; no stop endpoint.
- Existing JevChat tasks exposed through exact allowlist; not toggled during this delivery.
- 63 result directories discovered. This is not a claim that all historical prompts are available or that all sessions were archived into Notion.
- Current session user-task summary registered in `results/status/session_manifest.json` and Notion.

## Verified

- 8 Python unit/HTTP tests pass; Node JS syntax check and repository gate pass.
- Real Windows PowerShell parser check passed at deployment.
- Edge headless DOM check: table cells, task names, session count 63; exit 0.
- Local control API: no Origin/CSRF -> 403; protected hub stop with valid CSRF -> 400.
- Task sampler returns Running for hub, panel, DSH and pet; JevChat monitor Ready, analyzer Running.
- DSH authenticated HTTP session with cookie jar -> 200. Bare unauthenticated request -> 401 (expected).
- An early diagnostic accidentally included a local DSH bootstrap URL in a receipt. Current receipts were redacted and the DSH process restarted; bootstrap token fingerprint changed. Never print runtime logs containing tokens again. Old token is no longer the active bootstrap credential.
- Pet download was truncated; execution was refused. Validated HTTP range downloads assembled full 348968895 bytes.
- Pet SHA256: fa049e31f1b0d184f77639a749f239b55b48c64b2ba14b59d08b3897168b55aa (GitHub release digest).
- Pet runs from `E:\0apps\DSHPet\dsh-pet-standalone-webm.exe`; process-specific APPDATA/LOCALAPPDATA point to E drive.
- Actual pet show/hide/show succeeded; left visible. A PS JSON-array enumeration bug was fixed before final delivery.

## DSH extras

Installed: @deepseek-ai/dsh 0.2.1-rc.2, dsh-video-skin 0.1.5, dsh-whale-widget 0.4.2, standalone pet v4.4.0 (non-chat).
Not installed: standalone boot-animation (video-skin already has boot overlay; avoid overlapping overlays); wallpaper-engine (npm unpublished; source installer compatibility review outstanding).
No AI keys configured. No paid software purchased. No Windows pre-login boot-screen modifications.
Login startup tasks registered; an actual reboot/physical hotkey/visual animation acceptance was not performed.

## Notion (primary archive for instances)

Home: https://app.notion.com/p/407186af12d381cf97eeebf4ec37f0c9
Database/data source IDs in code/panel/notion-links.json.
Current session: 407186af-12d3-8115-bf8e-ec0ecb643868
Fixed hub snapshot: 407186af-12d3-81a3-b951-c06068fb4d07
Panel software: 407186af-12d3-81b6-9302-d7dfa9318e59
DSH software: 407186af-12d3-8111-87f8-ce3829b7f187
Pet software: 407186af-12d3-8133-8062-f312ed5f8c6a

Notion is on-demand, not a deployed continuous synchronization daemon. Prompt text defaults to local storage until explicitly archived.
Local real-time Windows scheduler state is separate from historical hub receipts and from Notion snapshots.

## Remaining boundaries

- Full source installation of wallpaper-engine and alternative boot-animation still outstanding.
- No new HPC job stream integrated; remote job running state is not inferred from old receipts.
- Local scheduled tasks can stay up while the computer is on and the user is logged in, subject to crashes/sleep/network availability. No claim of unlimited Arena chat monitoring or a fixed maximum idle duration.
- Local data/executables/caches necessarily stay outside Notion; Notion stores the user-facing records, not the OS execution engine.
