# BiblioGenius Docs - Agent Instructions

## Jira Tickets (KAN-*)

When the user names a Jira ticket with the `KAN-` prefix (e.g. "KAN-193", "kan-42"), the
ticket's local copy lives in `bibliogenius-docs/docs/jira/`, one file per ticket, lowercase:
`docs/jira/kan-<number>.md`. Look there first; do not search the rest of the repo or ask
where the ticket is. Companion analysis files may sit next to it (e.g. `kan-193-analyse.md`).

## Confluence Sync Policy

> **Agents MUST NEVER run a full sync to Confluence.** The Confluence space BIB has a curated sidebar structure. Running `sync_docs.py` on all files (or walking the full `docs/` directory) creates unwanted folder pages and breaks the sidebar hierarchy.
>
> **Only sync specific, explicitly requested files** using targeted `sync_file()` calls.
> Never call `sync_docs.py` without arguments. Never iterate over directories to sync in bulk.
> When pushing a new page, verify the parent page exists and is correct BEFORE syncing.

## Confluence Sync - How To

Agents CAN push individual documents to Confluence using the `sync_docs.py` script.

**Usage** (single file only):

```python
cd /Users/federico/Sites/bibliotech/bibliogenius-docs && python3 -c "
from scripts.sync_docs import sync_file
from pathlib import Path

filepath = Path('/Users/federico/Sites/bibliotech/bibliogenius-docs/docs/<path_to_file>.md')
sync_file(filepath)
"
```

**Directory-to-parent-page mapping** (from `sync_docs.py`):

| Directory | Confluence Parent Page |
|-----------|----------------------|
| `docs/` | BiblioGenius |
| `technical/` | Technical |
| `business/` | Business |
| `research/` | Research & Development |
| `modules/` | Modules |
| `qa/` | Quality Assurance |
| `security/` | Security |
| `user-guides/` | User Guides |

**Requirements**: Environment variables `CONFLUENCE_BASE_URL`, `CONFLUENCE_USERNAME`, `CONFLUENCE_PASSWORD` must be set (loaded from `.env`).
