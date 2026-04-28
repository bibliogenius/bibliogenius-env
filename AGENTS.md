# BiblioGenius - Agent Instructions

All AI coding agents working on this project MUST read and follow these instructions.

---

## Development Principles (MANDATORY)

These principles apply to ALL development work, without exception. Read them before writing any code.

### 1. Write clean, readable code
Follow established conventions (see instruction files below). Favor clarity over cleverness. Keep functions short, names descriptive, and responsibilities well-separated.

### 2. When in doubt, ask
If a requirement is ambiguous, an architecture decision is unclear, or you are unsure about the impact of a change, **stop and ask the user before proceeding**. A clarifying question is always cheaper than a wrong implementation.

### 3. Prevent regressions - test first
Before implementing a feature or fixing a bug, **write or update the relevant automated tests first** (unit, integration, or both). This ensures:
- The bug is reproducible or the expected behavior is defined before code is written
- Existing functionality is protected from unintended side effects
- Tests serve as living documentation of the intended behavior

After development, run the full post-development checks (see Quick Reference below). All tests must pass.

### 4. Security (OWASP) - systematic
Every code change must be evaluated against the [OWASP Top 10](https://owasp.org/www-project-top-ten/). In particular, always verify:
- Input validation and sanitization on all user-provided data
- No SQL injection (use parameterized queries only)
- No XSS (escape all rendered user content)
- No SSRF (validate URLs against allowlists)
- No secrets in logs, responses, or client-side code
- Authentication and authorization checks on all protected endpoints
- For crypto/E2EE code: read `SECURITY_GUIDELINES.md` first (see Security section below)

### 5. Accessibility - non-negotiable
Every new or modified UI element must comply with RGAA 4.1 / WCAG 2.1 AA (see Rules A1-A4 in [Architecture](.agents/instructions/architecture.md)). Screen reader support, color contrast, text scaling, and translated labels are not optional extras - they are requirements.

### 6. Reuse before reinventing
Before proposing a new schema column, helper function, abstraction, or migration, exhaustively rule out an existing mechanism that already solves the problem. The ratio "ADRs already shipped" : "what feels new" in this codebase is high - assume the wheel exists until proven otherwise.

Concrete checks before drafting any new mechanism:

1. **Read the relevant Entity/Model file end to end** (`src/models/<entity>.rs`, `src/Entity/<Entity>.php`). The field, flag, or method you are about to add is often already there with a slightly different name.
2. **Grep for ADR markers in the area**: `rg "ADR-\d+" src/ services/ <relevant_dir>/` and cross-check `bibliogenius-docs/docs/technical/adr/`. ADRs that ship rarely advertise themselves in the file you are editing.
3. **Search semantically, not just by current vocabulary**: if you are adding "404 retry counter", grep for `invalid|stale|gate|expired|flagged|short-circuit|backoff` too - past designers may have used a different word.
4. **Skim existing tests in the same module**: behaviors not visible in production code paths often surface in `mod tests` blocks at the bottom of source files.

Only propose a new column, helper, or ADR after these four checks return nothing relevant. When in doubt, ask the user **before** drafting code: "I am about to add X - is there a pre-existing mechanism (ADR, model field, helper) I should be aware of?" The question costs 30 seconds; reinventing costs hours and creates duplicate state.

Failure mode this rule prevents: suggesting a `relay_404_count` column with migration when `relay_write_token_invalid_at` from ADR-032 already exists and is wired in 6 sites.

---

## Instruction Files

Read the relevant files before making any changes:

| File | Scope | When to read |
|------|-------|--------------|
| [Policies](.agents/instructions/policies.md) | Git, deployment, logging, performance, URLs | **Always** |
| [Architecture](.agents/instructions/architecture.md) | Layer rules, stack, project structure, ADRs | **Always** |
| [Rust Backend](.agents/instructions/rust-backend.md) | Rust/Axum/SeaORM conventions | When modifying `bibliogenius/` |
| [Flutter Frontend](.agents/instructions/flutter-frontend.md) | Flutter/Dart/Provider conventions | When modifying `bibliogenius-app/` |
| [Documentation](.agents/instructions/docs.md) | Confluence sync policy | When modifying `bibliogenius-docs/` |

---

## Security

Before modifying ANY code handling secrets, keys, tokens, or crypto:

**READ** `bibliogenius-docs/docs/technical/SECURITY_GUIDELINES.md` first.

This includes files in: `src/crypto/`, `services/crypto_service.rs`, `services/relay_service.rs`, `api/e2ee.rs`.

---

## Skills

Specialized agent skills in `.agents/skills/`:

| Skill | Purpose |
|-------|---------|
| `coding-guidelines` | Rust code style (50 core rules) |
| `rust-async-patterns` | Async Rust with Tokio patterns |
| `flutter-expert` | Flutter 3.x / Dart expertise |
| `frontend-design` | Production-grade UI design |
| `seo-audit` | SEO analysis and optimization |
| `web-design-guidelines` | Web UI code review |
| `find-skills` | Discover and install more skills |

---

## Quick Reference - Post-Development Checks

```bash
# Rust
cd bibliogenius && cargo fmt && cargo clippy -- -D warnings && cargo test

# Flutter
cd bibliogenius-app && flutter analyze lib/
```

---

## Project Overview

BiblioGenius is a personal library management app.

- **Backend**: Rust (Axum) with SQLite (SeaORM)
- **Frontend**: Flutter (Provider, GoRouter)
- **Communication**: FFI for native, HTTP for web/peers
- **Architecture**: Clean Architecture (domain/infrastructure/services layers)

See [Architecture](.agents/instructions/architecture.md) for the full stack diagram and enforcement rules.
