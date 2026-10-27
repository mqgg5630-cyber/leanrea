# Notion connector workflow

Use the authorized Arena connector, not a local token-based uploader.
No scheduled synchronization has been deployed.

## Established objects (2026-10-27)
- Hub page: `406186af-12d3-812e-ae09-f4d653163b04`
- Papers database: `b5eabb93-859c-4ab8-9105-3c15c6a79919`
- Papers data source: `e7694ecc-6884-435a-a5a8-1836feaa07cf`
- Experiments database: `9ee51510-6f8d-44cd-9341-c91a8c19aa81`
- Experiments data source: `f2066ec0-a64d-4393-b3c4-8b1c779663e0`
- SSH record: `406186af-12d3-816e-948c-f1efaddafa69`
- Paper index: `406186af-12d3-8133-b122-c8854b845d6f`

## Every on-demand synchronization
1. Load the Notion connector for the current reply.
2. Retrieve the target data source schema; never assume cached field names/types.
3. Extract only user-authorized summaries from actual execution evidence.
4. Query the exact `同步键` property before creating an experiment record.
5. Existing key: report the record, do not duplicate or overwrite silently.
6. New key: create a page under the data source, then read it back and verify.
7. An ambiguous timeout is not permission to retry creation; query first.

The SSH record key is `infra:laptop-desktop:ssh:2026-10-27`.
Do not claim atomic deduplication under concurrent writers; serialize requests.
Never upload secrets, private chat histories, raw datasets, or PDFs by default.
See `deliverable/notion/` for the three user guides.
