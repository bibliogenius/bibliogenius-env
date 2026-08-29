Session is closing. Decide what — if anything — should be recorded in the project docs (`bibliogenius-docs/`) and auto-memory. Bias toward the minimal high-value note, NOT documentation for its own sake (respect the no-governance-overhead and YAGNI preferences).

Follow these steps:

1. **Find what changed this session.** Run `git diff --stat` (and `git diff --cached --stat`) in every repo touched: `bibliogenius/`, `bibliogenius-app/`, `bibliogenius-hub/`, `bibliogenius-docs/`. Note: the top-level repo ignores everything by default; sub-repos (`bibliogenius-hub/`, etc.) have their own git. If nothing changed and nothing notable was learned, say so and stop.

2. **For each notable change or learning, pick the right target — or none:**
   - **New ADR** (`bibliogenius-docs/docs/technical/adr/`): ONLY if it is a genuine architecture decision — new service, protocol/wire-format change, security change, or DB schema for a new concept. A bugfix, hardening, or refactor of an existing design is NOT an ADR. Grep `adr/README.md` for the next free number before assuming one (memory stales).
   - **Amend an existing ADR/doc**: when the change makes an existing statement misleading or incomplete (e.g. a documented "mitigation" that actually had a failure mode now closed). Prefer a tight 1-3 line addendum + a Status/Updated bump over a new file.
   - **Auto-memory** (`~/.claude/projects/.../memory/` + `MEMORY.md` index): for a non-obvious gotcha, diagnostic recipe, or decision rationale that is NOT derivable from the code/git history and would save a future session real time. One fact per file. Skip anything the repo already records.
   - **Nothing**: the honest default for mechanical edits, dep bumps, and routine bugfixes whose intent is obvious from the diff/commit message.

3. **Apply the cost/benefit lens before recommending anything.** For each candidate note, state in one line why a future reader genuinely needs it. If you cannot, drop it.

4. **Confluence sync policy — never auto-sync.** Per `.agents/instructions/docs.md`, NEVER run a full sync and NEVER call `sync_docs.py` without a specific file argument. If a doc edit should land in Confluence, FLAG it and let the user run the targeted `sync_file()` call themselves.

5. **Present, then act on approval.** Output a short list of recommendations grouped by target (New ADR / Amend doc / Memory / Nothing), each with the why and the exact proposed text. Do NOT write to `bibliogenius-docs/` until the user approves. You MAY write auto-memory entries directly (they are the user's private store), but mention what you wrote.

6. Do NOT commit, push, or sync anything unless explicitly asked.
