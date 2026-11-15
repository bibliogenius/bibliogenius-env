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

### Optional base ref: `/audit <ref>`

Base ref given: `$ARGUMENTS`. If it is empty, use the working-tree diff above and skip this subsection.

When a ref is given (e.g. `/audit main`, `/audit upstream/main`), audit everything the current branch adds on top of it: commits already made on the branch, plus staged and unstaged changes. This is what a pull request will show, which the plain working-tree diff misses once the work is committed. In each repo, diff against the merge base, so that commits landed on the base in the meantime are not counted:

```bash
BASE="$ARGUMENTS"
for d in . */; do
  if [ "$d" = . ] || [ -d "$d.git" ] || [ -f "$d.git" ]; then
    echo "=== $d ==="
    if git -C "$d" rev-parse --verify --quiet "$BASE^{commit}" >/dev/null; then
      git -C "$d" diff --stat "$(git -C "$d" merge-base "$BASE" HEAD)"
    else
      echo "(no ref $BASE here, working-tree diff instead)"
      git -C "$d" diff --stat && git -C "$d" diff --cached --stat
    fi
  fi
done
```

Each repo has its own branches, so the ref may exist in some repos and not in others. Say in the report, per repo, which scope was audited (branch since `<ref>`, or working tree). In the rest of this command, "the diff" means that scope.

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
- For any crypto / E2EE code touched: cross-check against `bibliogenius-adr/SECURITY_GUIDELINES.md` (sign-then-encrypt, ephemeral DH, HKDF, replay-nonce). Read it before flagging.

### Code that fetches third-party sites

Only when the diff touches code that fetches pages the user did not open themselves (today `bibliogenius/src/modules/integrations/publisher_sites/` and `bibliogenius/tools/`), or the layer that code is built on (`bibliogenius/src/utils/public_fetch.rs`, `bibliogenius/src/modules/integrations/web_cover.rs`). Such code runs against thousands of sites nobody reviews, so also check:
- **robots.txt** is read and honoured on every request, redirect hops included, for pages and images alike. No request goes around the polite fetcher (a raw `reqwest` client, a `curl` in a script).
- **Pacing**: one request at a time per host, a minimum pause, `Crawl-delay` honoured; no concurrency that grows with the input.
- **Identity**: the honest User-Agent (`API_USER_AGENT`), never a browser's, and never personal data (an e-mail address) in a header or a URL.
- **Bounds**: body size caps, timeouts, redirect limit, number of pages or site-map files read per site. Input cut at a cap must not pass for complete (a site map truncated at 2 MB silently loses its last books).
- **Failure classes**: a site that refuses us (403, 429, firewall page), a site that is down, and one address that fails (a timeout once the site has answered) are three different outcomes. Mixing them up either keeps hitting a site that refused us or drops a working one.
- **Evidence**: a page is taken for the book's only on proof read on the page itself (its ISBN). Anything that can attach a wrong cover to a book is **BLOQUANT**.
- **Choosing the image**: a change to how a cover is picked on a page (`web_cover.rs`, `publisher_sites/lookup.rs`) is not proven by its tests. Ask for a contact sheet (`publisher_sites measure --books FILE`) checked by eye before merge, and say so in the report. In the November 2026 measure every wrong cover came from the image picked, never from the page found: a close button, a site logo, a related title's cover, a share card.
- **Untrusted content**: fetched HTML, XML and JSON-LD are parsed defensively, and anything rendered from them (a generated report page) is escaped.

The Web button (`web_cover::fetch_cover_from_page` and `fetch_cover_image`) is not a crawler: the user opened that page and asked for its cover, as a browser would, so **robots.txt** and **Pacing** do not apply to it. Its two files are listed because the crawling code depends on them: `public_fetch` hands back each redirect unfollowed so `publisher_sites` can check robots.txt and pause at every hop, and `web_cover::cover_candidates` picks the image for both. Review a change there against the other points, and for whether it takes a decision away from the polite caller (a redirect followed on its behalf skips a robots.txt check; a new request it does not know about skips the pause).

Generated data that ships with the app (`bibliogenius/data/publisher_sites/table.json`) is not read line by line: run the maintenance tool's own checks (`publisher_sites lint`, and `publisher_sites diff` for what changed) and report what they flag.

## 5. Discipline (avoid noise)

Skip likely false positives: pre-existing issues, things a linter/compiler/CI already catches (formatting, imports, type errors), pedantic nitpicks a senior engineer wouldn't raise, and intentional changes related to the broader work. Only surface issues you can justify.

## 6. Output

One consolidated markdown report, grouped by axis (**A. Qualité**, **B. Performance**, **C. Sécurité OWASP**), each finding with severity and a `repo/file:line` citation (so it's clear which sub-repo it belongs to):
- **BLOQUANT**: must fix before merge
- **IMPORTANT**: should fix, creates tech debt if ignored
- **SUGGESTION**: nice to have, non-blocking
- **OK**: brief note on what looks solid

End with a one-line verdict per axis (e.g. "Sécurité : OK, aucun point OWASP touché").
