---
name: arena-desk-session-records
description: Register user task metadata for the local Arena Desk panel and archive verified summaries through the authorized Notion connector.
---

# Stable base, replaceable sessions

1. Reuse git-sync; do not install another permanent hub, change its branch, or disable it.
2. Work on the session's assigned branch. Add `results/status/session_manifest.json`:
   `{"title":"User-facing task title","user_prompt":"User-authorized task, constraints and acceptance criteria"}`.
3. Never include credentials, system/developer instructions, private chat histories, or guesses about old prompts.
4. Normal hub receipts expose step exit codes and result timestamps. Completed receipts are historical, not live task state.
5. The panel discovers result directories on the local machine automatically. Without a receipt, status is unverified.
6. For Notion, load the connector in the current turn; read the target data-source schema; query the stable sync key; create only if missing; read back and verify. IDs are recorded in `code/panel/notion-links.json` and must be validated with get calls.
7. Notion is a snapshot archive, not a background command bus. Do not promise ongoing cloud synchronization without deploying one explicitly.
8. Optional desktop tasks may be controlled only through the panel allowlist. The permanent hub is protected even if a browser request attempts its name.
9. Prefer evidence-driven progress, persist concise lessons, and keep task execution separate from user-facing summaries, following the useful architectural patterns of Hermes Agent.
