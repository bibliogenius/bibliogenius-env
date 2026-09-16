Apply the findings of the most recent `/audit` (or `/review`) report in this conversation. If no such report exists in the conversation, run `/audit` first, show the report, then continue with this command.

## 1. Triage

Go through every finding of the report and sort it:

- **BLOQUANT** and **IMPORTANT**: apply, always.
- **SUGGESTION**: apply only when quality, cost and regression risk are all clearly favourable at once:
  - a real, nameable gain (correctness, robustness, readability a reviewer would notice), not a matter of taste;
  - a small, local change (a few lines, one or two files, no new dependency, no config or schema change);
  - no behavioural change a test or a manual check could not confirm in a minute.
  Skip a refactor for its own sake, anything touching shared code outside the diff, and anything whose benefit is speculative. This project prefers hardening over refactoring, and YAGNI over preventive generality: a missing branch is better left missing with a loud guard than written for a case that does not exist yet.
- **OK** notes: nothing to do.

Before editing, print the triage as a short list: each finding, its repo, its verdict (apply / skip) and, for a skip, the one-line reason.

## 2. Ownership check, before any edit

The workspace hosts **parallel sessions, one owner per file**. Run `git status --porcelain` in the repo concerned and compare with what *this* conversation changed:

- A file this conversation modified: yours, edit freely.
- A file already dirty in the working tree that this conversation never touched: **another session owns it**. Do not edit it. Report the finding as unapplied and say why.
- A clean file: editable, but only if the finding genuinely lands on it.

## 3. Apply

Edit the code for every "apply" item, respecting the conventions that hold for any other change in this repo. `AGENTS.md` and the relevant file under `.agents/instructions/` (`architecture.md`, `rust-backend.md`, `flutter-frontend.md`, `policies.md`) are the source of truth:

- Code, identifiers, comments and logs in **English**. French lives in `.po` catalogues only.
- No em dash anywhere, no ticket references, no personal names in code.
- Comment only where a hidden constraint needs one, not to narrate the change.
- Do not widen the scope: no unrelated cleanup, no new feature, no drive-by refactor of code the finding did not name.

Two traps specific to this codebase:

- **`#[frb]` struct changed?** The FFI contract broke. A hot restart lies about it; only a full rebuild proves anything, so say so rather than claiming the fix is verified.
- **Schema touched?** `bibliogenius/migrations/*.sql` is dead legacy that stops at 030 and contradicts the live schema. The truth is `bibliogenius/src/infrastructure/db.rs` plus the SeaORM entity in `src/models/`, and `make check-migration` replays the chain on a copy of a real library. The hub has its own, genuinely dual migration system: do not conflate the two.

## 4. Verify

Run the checks of the stacks you actually touched, scoped to the touched paths, and **capture the output once** rather than re-running to re-read it. Do not start, stop or deploy any server.

| Repo | Check |
|---|---|
| `bibliogenius/`, `librius/` (Rust) | `make check-rust`, or `cd <repo> && cargo clippy -- -D warnings && cargo test <filter>` to scope |
| `bibliogenius-app/` (Flutter) | `flutter analyze <paths> && flutter test <test paths>`. **Never `dart format`**, it reformats unrelated regions |
| `bibliogenius-hub/` (Symfony) | `cd bibliogenius-hub && make phpunit ARGS=<path>`; if the dev stack is down, a disposable `php:8.3-cli` container |
| `bibliogenius-website/` | `cd bibliogenius-website && python3 _build/build.py`; never edit built HTML, only templates and `_i18n/` |

Then prove the fix, do not argue it:

- A behavioural fix (validation, data transformation, authorisation, decoding) needs a test or a concrete probe that fails before and passes after.
- A fix that **adds a guard** (a new test, an assertion, a log on an impossible branch) is worthless until it has been seen to fire. Break the invariant on purpose, confirm the guard fails, restore the file, confirm the diff on it is empty.
- What no test can reach, say plainly instead of implying it was checked.

## 5. Report

One short markdown section: what was applied, with `repo/file:line`; what was skipped and why, including anything blocked by another session's ownership; what the verification showed, failures included.

**Never commit and never push.** Commits happen only through `/local:save`, and pushes only by the user.
