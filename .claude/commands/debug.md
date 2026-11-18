Read the following bug report and evaluate whether the bug actually exists. If it exists in fact, fix it.

Bug report:

$ARGUMENTS

## Steps

1. **Read the report.** Restate in one or two sentences what is claimed: the symptom, where it happens (platform, screen, endpoint, sync lane), and the expected behaviour. If the report is empty or too vague to locate any code, stop and ask for the missing detail.

2. **Evaluate whether the bug is real.** Do not take the report at face value.
   - Locate the code involved and trace the actual execution path, from the entry point (screen, FFI call, HTTP handler) down to storage.
   - Check every factual claim against the code: function names, field names, conditions, data flow. Note which claims hold and which do not.
   - Check whether it is already fixed: `git log -S`/`git log --grep` on the relevant symbols, and whether the fix is in the last release tag or only on `main`.
   - Where cheap and safe, reproduce it: an existing test, a new failing test, or a read-only query. No network probes, no server commands, no access to secrets.

3. **Give a verdict** before changing anything:
   - **CONFIRMED**: the bug exists; explain the root cause with `file:line` references.
   - **NOT REPRODUCED / INVALID**: the report is wrong or outdated; explain which claim fails and why, with `file:line` references. Stop here.
   - **PARTIAL / UNCERTAIN**: part of the claim holds, or the outcome depends on runtime state you cannot check; say what is confirmed, what is not, and what would settle it. Ask before fixing.

4. **If CONFIRMED, fix it.**
   - Read `AGENTS.md` and the relevant files in `.agents/instructions/` first.
   - Fix the root cause, not the symptom. Keep the change minimal: no refactor, no scope creep beyond this bug.
   - Add or update a test that fails without the fix and passes with it, when the layer allows it.
   - Run only the tests that cover the touched code, not the full suite.
   - Follow the post-dev checklist in `AGENTS.md` (format, analyze, i18n in every exposed locale if strings change).

5. **Report**: verdict, root cause, files changed, tests run with their result, and anything that still needs a manual check on a device. Do not commit or push; propose a commit message in English and wait for approval.
