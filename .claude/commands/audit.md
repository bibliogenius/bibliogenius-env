Audit the current working-tree diff across three axes at once — quality, performance, and security (OWASP). This is a superset of `/review`: same diff scope, but adds a performance pass and a systematic OWASP pass. It reviews **only what changed**, not the whole app.

Follow these steps:

## 1. Collect the diff across every sub-repo

The workspace is a set of **independent git repos** (not submodules): the root, plus each `*/` directory that contains its own `.git`. Audit every one that has changes. Discover them dynamically — do not hardcode the list, repos come and go:

```bash
# The root repo
git diff --stat && git diff --cached --stat
# Every sub-repo with its own .git, in one pass
for d in */; do
  if [ -d "$d.git" ] || [ -f "$d.git" ]; then
    echo "=== $d ==="
    git -C "$d" diff --stat && git -C "$d" diff --cached --stat
  fi
done
```

This covers the code repos that matter for an audit — `bibliogenius/` (Rust), `bibliogenius-app/` (Flutter), `bibliogenius-hub/` (PHP), `librius/` (Rust), `bibliogenius-website/`, `bibliogenius-docker/` — and any new one added later.

For each repo with a diff, read its modified files to understand the change **in context** (not just the hunks). Always label findings with the repo they belong to. Only flag issues on lines the diff actually touched — ignore pre-existing problems on untouched lines.

If no repo has any diff, say so and stop.

## 2. Axis A — Quality & architecture

Check the changes against the architecture rules in `AGENTS.md` / `.agents/instructions/architecture.md`:
- **R1**: No SeaORM in new `api/` handlers
- **R2**: No framework deps in `domain/`
- **R3**: Proper layer chain (Handler → Service/Repo → Infrastructure)
- **R4**: Infra implements domain traits
- **R5**: Model fields frozen
- **F1**: No data access in screens
- **F2**: Repository pattern for new entities
- **A1-A4**: Accessibility (RGAA 4.1 / WCAG 2.1 AA) for any new/modified UI

Also check:
- Code is in **English** (comments, identifiers, logs) — French only in `.po` catalogues
- Missing or inadequate error handling
- Duplication with existing code (reuse before reinventing — DRY on business logic, not just styling)
- Breaking changes to the FFI contract (`frb.rs` structs — flag if a `#[frb]` struct changed)
- Missing or broken tests for the changed behavior

## 3. Axis B — Performance

Static heuristics only (no profiling). Flag, per stack:
- **Rust**: needless `.clone()` / allocations in hot paths, blocking calls inside `async` (`block_on`, sync I/O), N+1 DB queries, missing `LIMIT`/indexes on new queries, unbounded collections, `await` inside loops that could be concurrent
- **Flutter**: rebuilds of expensive subtrees (missing `const`, rebuild scope too wide), sync/heavy work on the UI thread, unbounded `ListView` without builder, images/covers not sized/cached, leaked `StreamSubscription`/`Controller` not disposed
- **Hub (PHP)**: N+1 queries, missing indexes, work that should be queued/async

State clearly that these are static heuristics — runtime profiling is the real measure.

## 4. Axis C — Security (OWASP Top 10)

Evaluate the changes systematically against the [OWASP Top 10](https://owasp.org/www-project-top-ten/). At minimum:
- Input validation & sanitization on all user-provided data
- No SQL injection — parameterized queries only (note: DBAL 4 needs `ParameterType::*`, never raw `\PDO::PARAM_*` ints)
- No XSS — escape all rendered user content
- No SSRF — validate URLs against allowlists
- No secrets in logs, responses, or client-side code
- AuthN/AuthZ checks on every protected endpoint
- For any crypto / E2EE code touched: cross-check against `bibliogenius-docs/docs/technical/SECURITY_GUIDELINES.md` (sign-then-encrypt, ephemeral DH, HKDF, replay-nonce). Read it before flagging.

## 5. Discipline (avoid noise)

Skip likely false positives: pre-existing issues, things a linter/compiler/CI already catches (formatting, imports, type errors), pedantic nitpicks a senior engineer wouldn't raise, and intentional changes related to the broader work. Only surface issues you can justify.

## 6. Output

One consolidated markdown report, grouped by axis (**A. Qualité**, **B. Performance**, **C. Sécurité OWASP**), each finding with severity and a `repo/file:line` citation (so it's clear which sub-repo it belongs to):
- **BLOQUANT**: must fix before merge
- **IMPORTANT**: should fix, creates tech debt if ignored
- **SUGGESTION**: nice to have, non-blocking
- **OK**: brief note on what looks solid

End with a one-line verdict per axis (e.g. "Sécurité : OK, aucun point OWASP touché").
