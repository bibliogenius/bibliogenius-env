# BiblioGenius - Agent Instructions

All AI coding agents working on this project MUST read and follow these instructions.

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
