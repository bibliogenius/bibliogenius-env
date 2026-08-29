# BiblioGenius - Project Policies

These policies apply to ALL agents and contributors working on the project.

---

## Writing Style

> **Do NOT use em dashes (-) in generated text** (code comments, ADRs, commit messages, docs, UI strings, etc.).
> Use regular dashes (-), colons, or rephrase instead. Em dashes are not the project's style.

## Git Policy

> **Agents MUST NEVER create commits automatically.** The user handles all git operations (add, commit, push, merge). Agents may suggest commit messages but must not execute `git commit`, `git push`, or `git merge`.
> **Commit messages MUST NOT include AI attribution lines** (e.g. `Co-Authored-By: <AI name>`).

## Deployment Files Policy

> **Agents MUST NOT modify deployment-related files without explicit user consent.**
> This includes: entitlements (`.entitlements`), provisioning profiles, Xcode project settings (`.pbxproj`), signing configurations, `Info.plist` (iOS/macOS), `AndroidManifest.xml`, Podfile, Gradle files, and any CI/CD pipeline files.
> Always ask before touching these files - deployment was hard-won and regressions are unacceptable.

## Server Access Policy

> **Agents MUST NOT execute commands on production or staging servers** (SSH to the VPS, `gh workflow run` with side effects, manual deploy scripts, container restarts, DB queries against managed PostgreSQL, etc.).
> The user runs all server-side commands. Agents draft the exact commands and present them for the user to copy-paste.
> **Read-only inspection** (`ssh ... 'cat /etc/foo'`, `systemctl status`, log tailing) is permitted **only** when the user explicitly authorizes it for the current task. Default behavior: hand the command to the user.
> Rationale: production access requires human judgment and audit trail; agents should not silently mutate live infrastructure.

## Hub Backup Data Policy

> **Hub database dumps (`_backup/hub-backup/*.sql` and any other production DB export) contain real user data** (profiles, tokens, catalogs, personal identifiers).
> Agents MAY inspect them locally (grep, sqlite/psql on a local copy) when the current task requires it (e.g. diagnosing dashboard errors).
> Agents MUST NOT:
> - persist any backup content in agent memory (auto-memory files, MEMORY.md, session notes) - not even single rows, hashes, or tokens; store only aggregate conclusions (e.g. "3 rows have a NULL node_id");
> - quote backup rows in commits, ADRs, docs, code comments, or tests;
> - copy or move the dump files outside `_backup/`.
> Rationale: memory and repos outlive the diagnosis and may be synced or shared; production data must stay in the backup directory.

## Configuration Source-of-Truth Policy

> **Before modifying any production configuration** (`Caddyfile`, `nginx.conf`, `docker-compose.*.yml`, systemd units, deploy scripts, `.env.*.config` templates, etc.), agents MUST first locate the version-controlled source. **Never edit the live file directly.**
>
> **Procedure (mandatory, in this order):**
> 1. Search the repo tree for matching filenames — not just the live path. Try variants: `Caddyfile`, `Caddyfile.vps`, `Caddyfile.prod`, `*.Caddyfile`, etc.
> 2. Read the header of each candidate: a comment like `# Installed on the host at /etc/X` or `# Deployed to ...` is a strong source-of-truth signal.
> 3. If a source file exists → edit it there, then hand the user the deploy command (per Server Access Policy).
> 4. If **no** source file is found → **ask the user** where the source-of-truth lives before touching anything live. Do not edit the live file as a fallback.
> 5. If the deploy pipeline does **not** auto-sync this file from the repo (drift-by-design), flag it explicitly and propose adding the sync — but do not silently work around it by editing live.
>
> Cost of asking: 30 seconds. Cost of drift: the next legitimate deploy silently overwrites your fix, or the repo lies about live state for weeks until someone gets burned.
>
> **Failure mode this rule prevents:** an agent edits `/etc/caddy/Caddyfile` via SSH to add a vhost; the source file `Caddyfile.vps` in the repo never gets the change; weeks later a teammate edits `Caddyfile.vps` and pushes a new version that wipes the live vhost.

## Operation Log Policy

> **NEVER log sensitive or personal data in operation_log payloads.**
> Forbidden in payloads: emails, phone numbers, addresses, passwords, API keys, crypto keys, tokens, notes (free text from users).
> Allowed: entity IDs, foreign key references (book_id, copy_id), enum status values (e.g. "available", "loaned").
> Prefer `None` payload when the entity type + ID is sufficient for sync.
>
> **Log rotation**: `sync.rs` auto-prunes oldest non-pinned entries when count exceeds `MAX_LOG_ENTRIES` (default 500).
> Configurable at runtime via `set_max_operation_log_entries()`.
>
> **Milestone pinning**: Entries with `pinned = 1` survive log rotation. Auto-pinned: first INSERT per entity type
> (first book, first contact, first loan, etc.). Use `log_milestone(db, event_name, payload)` for app lifecycle
> events (version changes, first launch, configuration milestones). Pinned entries are capped at `MAX_PINNED_ENTRIES`
> (default 100) - oldest pinned entries are pruned if exceeded.
>
> **Before adding any new log_operation call**, verify:
> 1. No sensitive data in the payload (see forbidden list above)
> 2. The payload is minimal (prefer `None`)
> 3. The operation is meaningful for sync or audit

## Performance and Scalability Policy

> **BiblioGenius MUST run well on constrained devices and networks.**
> Target environments include: low-end Android phones, older tablets, rural areas with limited/intermittent
> connectivity, and regions with less modern infrastructure. Every feature must be designed with these constraints in mind.
>
> **Rules**:
> - **Storage**: Minimize SQLite database size. Use bounded data structures (capped logs, pruned caches).
>   Never allow unbounded growth of any table or in-memory collection.
> - **Network**: Assume intermittent connectivity. All sync operations must be resilient to disconnection.
>   Prefer small payloads. Batch operations where possible to reduce round-trips.
> - **CPU/Memory**: Avoid heavy computation on the main thread. Use `compute()` for CPU-intensive work in Flutter.
>   Keep in-memory caches bounded. Prefer lazy loading over eager fetching.
> - **Startup time**: Minimize cold start. Defer non-essential initialization. The app must be usable quickly
>   even on slow devices.
> - **Offline-first**: Core features (browsing library, viewing books) must work fully offline.
>   Network-dependent features must degrade gracefully with clear user feedback.
> - **Image handling**: Always use `CachedNetworkImage`. Prefer compressed/thumbnail versions.
>   Never load full-resolution images in list views.
> - **Pagination**: All list endpoints and UI lists must be paginated. Never load unbounded result sets.

## Hub URL Policy

> **The hub URL (`hub.bibliogenius.org`) MUST NEVER be hardcoded** outside of `ApiService.hubUrl`.
> `ApiService.hubUrl` is the single source of truth: it reads from `HUB_URL` env var, with a production fallback via `kReleaseMode`.
> All code needing the hub URL MUST use `ApiService.hubUrl` (Flutter) or `std::env::var("HUB_URL")` (Rust).
> In `invite_payload.dart`, callers pass `hubBaseUrl` explicitly - the utility file has no hardcoded URL.

## Version Bump - Non-Regression Testing Policy

When incrementing the version in `pubspec.yaml`, run the appropriate level of non-regression tests from `QA_NON_REGRESSION.md`:

| Version Change | Example | Required Tests |
|----------------|---------|----------------|
| **Patch** (`x.y.Z`) | 0.7.0 -> 0.7.1 | Pre-release checklist (cargo fmt/clippy/test, flutter analyze/build) + P0 tests only + tests related to the specific fix |
| **Minor** (`x.Y.0`) | 0.7.x -> 0.8.0 | Full TNR Part A (all priorities, all platforms) |
| **Major** (`X.0.0`) | 0.x -> 1.0.0 | Full TNR Part A + all Part B detailed scenarios (data integrity, security, resilience, performance) |

The pre-release checklist (backend `cargo fmt`/`cargo clippy`/`cargo test`, frontend `flutter analyze`/builds) runs on **every** version bump.
