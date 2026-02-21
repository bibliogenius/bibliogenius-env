# BiblioGenius Architecture

## Git Policy

> **Claude MUST NEVER create commits automatically.** The user handles all git operations (add, commit, push, merge) themselves. Claude may suggest commit messages but must not execute `git commit`, `git push`, or `git merge`.

## Stack Overview

- **Backend**: Rust (Axum framework)
- **Database**: SQLite (via SeaORM)
- **Frontend**: Flutter
- **Communication**: FFI (Flutter Foreign Function Interface) for direct Rust calls
- **Caching**: Flutter-side cache layer

> **Detailed conventions are in dedicated CLAUDE.md files:**
> - Rust backend: `bibliogenius/CLAUDE.md`
> - Flutter frontend: `bibliogenius-app/CLAUDE.md`
> - **Security & E2EE**: `bibliogenius-docs/docs/technical/SECURITY_GUIDELINES.md`

### Security Guidelines (MANDATORY)

> **Before modifying ANY code in `src/crypto/`, `services/crypto_service.rs`, `services/relay_service.rs`, `api/e2ee.rs`, or any code handling secrets (keys, tokens, passwords), you MUST read `bibliogenius-docs/docs/technical/SECURITY_GUIDELINES.md`.**
> This file contains the binding security audit results (14 findings, Feb 2026) and the corrected crypto pipeline.

---

## ARCHITECTURE ENFORCEMENT (MANDATORY)

> **THIS SECTION IS THE SINGLE SOURCE OF TRUTH for the current architecture.**
> Every code change — feature, bugfix, refactor — MUST comply with these rules.
> If the architecture evolves, update THIS section first. All enforcement follows from here.

### Current Architecture Stack

| Layer | Technology | Location |
|-------|-----------|----------|
| Frontend UI | Flutter (Provider, GoRouter) | `bibliogenius-app/lib/` |
| Frontend Data | Repository pattern (abstract + impl) | `bibliogenius-app/lib/data/` |
| Communication | FFI (primary) / HTTP (debug/web) | `bibliogenius-app/lib/src/rust/` |
| API | Axum handlers (thin delegation) | `bibliogenius/src/api/` |
| Domain | Pure traits + errors (NO deps) | `bibliogenius/src/domain/` |
| Services | Business logic orchestration | `bibliogenius/src/services/` |
| Infrastructure | SeaORM repo impls, config, auth | `bibliogenius/src/infrastructure/` |
| Database | SQLite via SeaORM | Single file, managed by infrastructure |
| Caching | Flutter-side (SearchCache, etc.) | `bibliogenius-app/lib/services/` |

### Rust Layer Rules (MUST follow)

#### Rule R1: API handlers MUST NOT import SeaORM

```
FORBIDDEN in src/api/*.rs (except legacy files pending migration):
  use sea_orm::*;
  use sea_orm::{...};
  ::Entity::find
  ::Entity::insert
  ::Entity::update
  ::Entity::delete
```

New or modified handlers MUST use `State<AppState>` and delegate to repository traits or services.
**Exception**: Files listed in "Legacy Handlers Pending Migration" below may retain direct SeaORM until migrated.

#### Rule R2: Domain layer MUST have ZERO framework dependencies

```
FORBIDDEN in src/domain/*.rs:
  use sea_orm
  use axum
  use reqwest
  use tokio (except tokio::sync for channels)
```

Domain contains ONLY: trait definitions, error enums, filter structs, and pure business types.

#### Rule R3: New features MUST go through the proper layer chain

```
For CRUD operations:
  Handler (api/) → Repository trait (domain/) → Repository impl (infrastructure/)

For business logic:
  Handler (api/) → Service (services/) → Repository trait (domain/) → Repository impl (infrastructure/)

NEVER: Handler → direct SeaORM / raw SQL
```

#### Rule R4: Infrastructure MUST implement domain traits

All new database access MUST be implemented as:
1. A trait in `domain/repositories.rs`
2. An implementation in `infrastructure/repositories/`
3. Injected via `AppState` in `infrastructure/state.rs`

#### Rule R5: Models are API contract — field names are FROZEN

`src/models/*.rs` struct field names and types MUST NOT change (Flutter FFI depends on them).
Adding new optional fields is allowed. Removing or renaming is FORBIDDEN.

### Flutter Layer Rules (MUST follow)

#### Rule F1: Screens MUST NOT contain data access logic

Screens (`lib/screens/`) interact with data ONLY through:
- Repository abstractions (`lib/data/repositories/`)
- Providers (`lib/providers/`)
- Services (`lib/services/`)

**NEVER**: Direct HTTP calls, raw JSON parsing, or SQL in screen files.

#### Rule F2: New data entities MUST use the repository pattern

For any new data entity:
1. Abstract repository in `lib/data/repositories/`
2. Implementation in `lib/data/repositories_impl/`
3. Wired through Provider or service injection

#### Rule F3: FFI is the primary communication channel

- All Rust calls go through FFI bindings (`lib/src/rust/`)
- HTTP mode exists ONLY for web builds and debug
- New Rust endpoints MUST have FFI bindings in `api/frb.rs`

#### Rule F4: Cache layer lives in Flutter

- Search results, metadata: cached in Flutter services
- No caching in the Rust backend (stateless request handling)
- Cache invalidation is the caller's responsibility

### Legacy Handlers Pending Migration

> These files still use direct SeaORM. They are ALLOWED to remain as-is
> but any MODIFICATION should migrate the touched code to the repository pattern.

| File | Status | Priority |
|------|--------|----------|
| `api/tag.rs` | Legacy | Next to migrate |
| `api/contact.rs` | Legacy | Medium |
| `api/loan.rs` | Legacy | Medium |
| `api/auth.rs` | Legacy | Low |
| `api/batch.rs` | Legacy | Low |
| `api/data.rs` | Legacy | Low |
| `api/export.rs` | Legacy | Low |
| `api/gamification.rs` | Legacy | Low |
| `api/hub.rs` | Legacy | Low |
| `api/integrations.rs` | Legacy | Low (complex) |
| `api/library.rs` | Legacy | Low |
| `api/lookup.rs` | Legacy | Low |
| `api/mcp.rs` | Legacy | Low |
| `api/peer.rs` | Legacy | Low (most complex) |
| `api/profile.rs` | Legacy | Low |
| `api/sales.rs` | Legacy | Low |
| `api/scan.rs` | Legacy | Low |
| `api/search.rs` | Legacy | Low |
| `api/setup.rs` | Legacy | Low |
| `api/user.rs` | Legacy | Low |

### Pre-Completion Architecture Check

**Before considering ANY task complete, verify:**

1. **No new layer violations introduced** — no SeaORM in api/, no framework in domain/
2. **New code follows the proper chain** — Handler -> Service/Repo -> Infrastructure
3. **Flutter changes use repositories** — not direct API calls from screens
4. **FFI contract preserved** — frb.rs structs unchanged (or Flutter updated in sync)
5. **Model fields preserved** — no field renames/removals in models/*.rs
6. **ADR written if needed** — see ADR rule below

> **If the architecture needs to evolve** (e.g., switching from SQLite to Postgres,
> or from Provider to Riverpod), update THIS section FIRST, then implement.
> Claude will enforce whatever is documented here.

### Architecture Decision Records (MANDATORY)

> **Location**: `bibliogenius-docs/docs/technical/adr/`
> **Index**: `bibliogenius-docs/docs/technical/adr/README.md`

**An ADR MUST be created** when a task involves any of the following:
- Adding a new service, module, or external dependency
- Changing the communication pattern (new protocol, new API surface)
- Choosing between multiple viable technical alternatives
- Modifying the security model or crypto pipeline
- Adding or changing a database schema for a new domain concept
- Any decision that a future contributor would ask "why was this done this way?"

**Format**: `ADR-NNN-short-title.md` (sequential numbering, see README for template).
**Update the index** in `README.md` when adding a new ADR.

---

## Project Structure

```
bibliotech/
├── bibliogenius/           # Rust backend (see bibliogenius/CLAUDE.md)
│   ├── src/
│   │   ├── api/           # HTTP API endpoints (thin Axum handlers)
│   │   ├── domain/        # Pure business abstractions (NO framework deps)
│   │   ├── infrastructure/# Technical implementations + repository impls
│   │   ├── modules/       # External integrations (BNF, Inventaire, etc.)
│   │   ├── models/        # DTOs + SeaORM entities (API contract)
│   │   ├── services/      # Business logic orchestration
│   │   └── utils/         # Shared utilities
│   └── Cargo.toml
│
└── bibliogenius-app/       # Flutter frontend (see bibliogenius-app/CLAUDE.md)
    └── lib/
        ├── screens/       # UI screens
        ├── data/          # Repository pattern (abstract + impl)
        ├── services/      # API, Auth, Sync, Translation, Cache
        ├── providers/     # State management
        ├── widgets/       # Reusable UI components
        └── src/rust/      # FFI bindings (generated)
```

## External Integrations (Active)

- **data.bnf.fr**: French National Library (SPARQL endpoint)
- **Inventaire.io**: Wikidata-based book database
- **OpenLibrary**: Open book catalog
- **Google Books**: Optional metadata source (opt-in via profile)

## Backend-only (not yet used in UI)

- **SUDOC**: French academic libraries catalog

## Key Patterns

- FFI mode: Flutter calls Rust directly via FFI bindings
- HTTP mode: Flutter calls Rust backend via HTTP (for web/debug)
- Installation profile: Per-user settings stored in SQLite (enabled modules, etc.)
- Source filtering: UI allows filtering external searches by source

---

## Version Bump — Non-Regression Testing Policy

When incrementing the version in `pubspec.yaml`, run the appropriate level of non-regression tests from `QA_NON_REGRESSION.md`:

| Version Change | Example | Required Tests |
|----------------|---------|----------------|
| **Patch** (`x.y.Z`) | 0.7.0 → 0.7.1 | Pre-release checklist (cargo fmt/clippy/test, flutter analyze/build) + P0 tests only + tests related to the specific fix |
| **Minor** (`x.Y.0`) | 0.7.x → 0.8.0 | Full TNR Part A (all priorities, all platforms) |
| **Major** (`X.0.0`) | 0.x → 1.0.0 | Full TNR Part A + all Part B detailed scenarios (data integrity, security, resilience, performance) |

The pre-release checklist (backend `cargo fmt`/`cargo clippy`/`cargo test`, frontend `flutter analyze`/builds) runs on **every** version bump.
