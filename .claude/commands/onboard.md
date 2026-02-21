Generate onboarding configuration for a new team member on BiblioGenius.

The argument $ARGUMENTS should be the profile type: `no-code`, `junior`, or `senior`.

## Steps

1. Read the project's CLAUDE.md and the Rust/Flutter sub-CLAUDE.md files to understand the full architecture rules.
2. Based on the profile, generate a configuration bundle:

### For all profiles, generate AI tool configuration files:

**Generate rules files for whichever AI tools the contributor uses:**
- `.cursorrules` — for Cursor users
- `.windsurfrules` — for Windsurf users
- Note: Claude Code users are auto-configured via `CLAUDE.md` (no extra file needed)

**Each rules file should contain:**
- Project description (edtech app, Rust backend + Flutter frontend + SQLite)
- Architecture layer rules (R1-R5, F1-F4) from CLAUDE.md, rewritten in clear language appropriate to the profile
- The team context (who reviews PRs, who to ask for what)
- Post-dev checklist (cargo fmt, clippy, test for Rust; flutter analyze for Flutter)

### Profile-specific adaptations:

**No-code profile (`no-code`)** — Product Owner, PM, designer, or any non-technical contributor:
- Tone: pedagogical, no technical jargon, explain every concept in simple French. Use analogies (e.g., "a branch is like a draft copy of a document"). Never assume knowledge of programming.
- Scope — ALLOWED files ONLY:
  - `bibliogenius-app/assets/i18n/*.po` (translations)
  - `bibliogenius-app/assets/curated_lists/**/*.yml` (curated book lists)
  - `bibliogenius-app/lib/themes/` (theme colors/styles)
  - `bibliogenius-app/lib/theme/app_design.dart` (design tokens — numeric values and colors only)
  - `bibliogenius-app/lib/widgets/` (simple widgets < 300 lines, with step-by-step guidance)
  - `bibliogenius-app/lib/screens/help_screen.dart`, `feedback_screen.dart`, `splash_screen.dart`
  - `bibliogenius-app/assets/images/` (image replacements)
- Scope — FORBIDDEN (hard block):
  - ALL Rust code (`bibliogenius/`)
  - `lib/models/`, `lib/services/`, `lib/providers/`, `lib/data/`, `lib/src/rust/`
  - `lib/config/`, `lib/utils/`
  - `pubspec.yaml`, `Cargo.toml`, CI files, migrations
  - `.claude/hooks/` (no self-modification of guards)
- Workflow rules:
  - ALWAYS run `flutter analyze` after any modification
  - ALWAYS work on a branch (`contrib/description`), NEVER commit to main directly
  - ALWAYS create a PR for review, NEVER merge without developer approval
  - Max 3 files per PR
- Learning loop (MANDATORY after each task):
  - Ask the contributor to summarize in 1-2 sentences: what was changed and why
  - If the summary is incorrect, gently correct and explain
  - Suggest a related "next step" mission to build confidence
- The `.cursorrules` for no-code must include:
  - Project description in simple non-technical language
  - The 4 safe zones with typical modification examples
  - Clear list of forbidden zones with explanations of why
  - Step-by-step PR workflow
  - Checklist before submitting a PR
- Reference `NO_CODE_ONBOARDING.md` and `/contrib-check` in the generated output
- Recommend activating `guard-no-code.sh` hook (instructions in NO_CODE_ONBOARDING.md)

**Junior dev profile (`junior`)**:
- Tone: technical but educational, explain design patterns when used
- Restrictions: FORBIDDEN to modify `src/crypto/`, security config, production deployment files without review
- Scope: full codebase access but must use plan mode (Opus) for any change touching >3 files
- Add UVAL learning loop: Understand the existing code → Verify the plan makes sense → Apply the change → Learn by summarizing what was done
- Require tests for any new function

**Senior dev profile (`senior`)**:
- Tone: concise, factual, no hand-holding
- No scope restrictions
- Full architecture rules as-is from CLAUDE.md
- Emphasis on: ADR requirement, security guidelines reference, FFI contract preservation

3. Ask the contributor which AI tool(s) they use (Claude Code, Cursor, Windsurf, other).
4. Generate the appropriate config files:
   - **Claude Code**: Already configured via `CLAUDE.md`. Just confirm setup is complete.
   - **Cursor**: Output `.cursorrules` content in a code block, ready to copy-paste.
   - **Windsurf**: Output `.windsurfrules` content (same format as `.cursorrules`).
   - **Other**: Output a generic rules file the contributor can adapt.
5. Also output a suggested list of hooks (as JSON for `.claude/settings.json` or Cursor equivalent) appropriate to the profile's restriction level.
