# BiblioGenius - Architecture Enforcement

> **THIS FILE IS THE SINGLE SOURCE OF TRUTH for the current architecture.**
> Every code change - feature, bugfix, refactor - MUST comply with these rules.
> If the architecture evolves, update THIS file first. All enforcement follows from here.

---

## Stack Overview

- **Backend**: Rust (Axum framework)
- **Database**: SQLite (via SeaORM)
- **Frontend**: Flutter
- **Communication**: FFI (Flutter Foreign Function Interface) for direct Rust calls
- **Caching**: Flutter-side cache layer

> **Detailed conventions**:
> - Rust backend: `.agents/instructions/rust-backend.md`
> - Flutter frontend: `.agents/instructions/flutter-frontend.md`
> - **Security & E2EE**: `bibliogenius-docs/docs/technical/SECURITY_GUIDELINES.md`

### Security Guidelines (MANDATORY)

> **Before modifying ANY code in `bibliogenius/src/crypto/`, `bibliogenius/src/services/crypto_service.rs`, `bibliogenius/src/services/relay_service.rs`, `bibliogenius/src/api/e2ee.rs`, or any code handling secrets (keys, tokens, passwords), you MUST read `bibliogenius-docs/docs/technical/SECURITY_GUIDELINES.md`.**
> This file contains the binding security audit results (14 findings, Feb 2026) and the corrected crypto pipeline.

---

## Current Architecture Stack

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
| Extension Modules | Self-contained features (game, quiz...) | `bibliogenius/src/modules/<name>/` |

---

## Rust Layer Rules (MUST follow)

### Rule R1: API handlers MUST NOT import SeaORM

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

### Rule R2: Domain layer MUST have ZERO framework dependencies

```
FORBIDDEN in src/domain/*.rs:
  use sea_orm
  use axum
  use reqwest
  use tokio (except tokio::sync for channels)
```

Domain contains ONLY: trait definitions, error enums, filter structs, and pure business types.

### Rule R3: New features MUST go through the proper layer chain

```
For CRUD operations:
  Handler (api/) -> Repository trait (domain/) -> Repository impl (infrastructure/)

For business logic:
  Handler (api/) -> Service (services/) -> Repository trait (domain/) -> Repository impl (infrastructure/)

NEVER: Handler -> direct SeaORM / raw SQL
```

### Rule R4: Core features - Infrastructure MUST implement domain traits

For **core** features (books, loans, contacts, peers, collections, etc.):
1. A trait in `domain/<entity>_repository.rs`
2. An implementation in `infrastructure/repositories/`
3. Injected via `AppState` in `infrastructure/state.rs`

### Rule R4b: Extension features - self-contained module pattern

For **independent features** (games, quizzes, standalone add-ons with no cross-dependency):

New extension features MUST use the self-contained module pattern in `src/modules/<name>/`:

```
src/modules/<name>/
|-- mod.rs          <- pub fn routes() -> Router<AppState>
|                      pub async fn migrate(db) -> Result<()>
|-- domain.rs       <- types + trait (re-uses DomainError from core)
|-- models.rs       <- SeaORM entities (module-internal)
|-- repository.rs   <- impl trait (creates repo from db, NOT injected in AppState)
|-- service.rs      <- business logic + unit tests
+-- handlers.rs     <- Axum handlers (creates repo via state.db())
```

Integration = only 2 lines in the rest of the codebase:
- `api/mod.rs`:  `.merge(crate::modules::<name>::routes())`
- `infrastructure/db.rs`:  `crate::modules::<name>::migrate(&db).await?;`

**When to use core vs extension?**
- Core: feature is interconnected with other features (loans need contacts, books, copies...)
- Extension: feature is standalone, could be removed by deleting one folder

### Rule R5: Models are API contract - field names are FROZEN

`src/models/*.rs` struct field names and types MUST NOT change (Flutter FFI depends on them).
Adding new optional fields is allowed. Removing or renaming is FORBIDDEN.

---

## Flutter Layer Rules (MUST follow)

### Rule F1: Screens MUST NOT contain data access logic

Screens (`lib/screens/`) interact with data ONLY through:
- Repository abstractions (`lib/data/repositories/`)
- Providers (`lib/providers/`)
- Services (`lib/services/`)

**NEVER**: Direct HTTP calls, raw JSON parsing, or SQL in screen files.

### Rule F2: New data entities MUST use the repository pattern

For any new data entity:
1. Abstract repository in `lib/data/repositories/`
2. Implementation in `lib/data/repositories_impl/`
3. Wired through Provider or service injection

### Rule F3: Flutter <-> Rust communication channels

The Rust core exposes TWO interfaces. Both call the same domain/service layer:

```
+----------------+     FFI direct (frb.rs)      +----------------+
| Flutter        | --------------------------> | Rust core      |
| native app     |     in-process, typed        | (domain/       |
+----------------+                              |  services/)    |
                                                |                |
+----------------+     HTTP (Axum routes)       |                |
| Any client     | --------------------------> |                |
| web, peers,    |     JSON over TCP            +----------------+
| MCP, CLI...   |
+----------------+
```

**FFI direct** (`FfiService` -> `frb.*`):
- In-process function call, no network, no JSON serialization
- Statically typed Dart objects (generated by `flutter_rust_bridge`)
- Used by Flutter on native platforms (macOS, iOS, Android)

**HTTP API** (Axum):
- Universal REST interface accessible to any client
- Required for: peer-to-peer sync, Flutter web, MCP server, future alternative frontends
- Axum startup is required when P2P or web features are active

**Rules for new features:**

1. New Flutter features MUST use FFI direct (`FfiService` -> `frb.*`), NOT HTTP local
2. Add `#[frb]` functions in `api/frb.rs` + Axum routes for the HTTP API (both, always)
3. Regenerate bindings: `cd bibliogenius-app && flutter_rust_bridge_codegen generate`
4. Add wrapper methods in `FfiService`, call from providers
5. HTTP local (`_getLocalDio()`) is legacy debt - do NOT extend this pattern

**Legacy HTTP local** (technical debt to migrate):
- Collections CRUD, gamification leaderboard/config use `_getLocalDio()` in `ApiService`
- These should be migrated to FFI direct when touched (Strangler Fig, same as SeaORM migration)

### Rule F4: Cache layer lives in Flutter

- Search results, metadata: cached in Flutter services
- No caching in the Rust backend (stateless request handling)
- Cache invalidation is the caller's responsibility

---

## Accessibility Rules (MUST follow)

> **Reference**: `bibliogenius-docs/docs/research/accessibility-interoperability-roadmap.md`
> **Target**: RGAA 4.1 level AA (French accessibility standard, based on WCAG 2.1)

### Rule A1: Every interactive widget MUST be accessible to screen readers

```
REQUIRED on all new or modified screens/widgets:
  - IconButton          -> MUST have a translated `tooltip`
  - Image / cover       -> MUST have a `semanticLabel` (title + author for books)
  - Tappable cards      -> MUST be wrapped in Semantics(button: true, label: ...)
  - Section titles       -> MUST be wrapped in Semantics(header: true)
  - Decorative images   -> MUST use excludeFromSemantics: true
```

Adding `Semantics` has zero visual/performance impact for sighted users. This is NOT optional.

### Rule A2: Color contrast MUST meet WCAG AA minimums

```
REQUIRED for all themes (default, dark, minimal):
  - Normal text (< 18px):  contrast ratio >= 4.5:1
  - Large text (>= 18px or 14px bold):  contrast ratio >= 3:1
  - UI components (icons, borders, focus indicators):  >= 3:1
```

Before adding a new color to any theme, verify the ratio against its background (use WebAIM Contrast Checker or similar). **Never use teal/pastel colors for text on white without checking.**

### Rule A3: Text scaling MUST NOT override system accessibility settings

The in-app text scale factor MUST compose with (multiply by) the OS-level text scaler, not replace it. Users who set large text at the OS level must see the combined effect.

### Rule A4: Tooltips and labels MUST be translated

Every `tooltip` on an `IconButton` and every `semanticLabel` on an `Image` MUST use `TranslationService.translate()` with keys in both `en.po` and `fr.po`. Hardcoded tooltip strings (English or French) are forbidden in new code.

---

## Legacy Handlers Pending Migration

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
| `api/gamification.rs` | **Migrated** (ADR-006) | Done |
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

---

## Pre-Completion Architecture Check

**Before considering ANY task complete, verify:**

1. **No new layer violations introduced** - no SeaORM in api/, no framework in domain/
2. **New code follows the proper chain** - Handler -> Service/Repo -> Infrastructure
3. **Flutter changes use repositories** - not direct API calls from screens
4. **FFI contract preserved** - frb.rs structs unchanged (or Flutter updated in sync)
5. **Model fields preserved** - no field renames/removals in models/*.rs
6. **ADR written if needed** - see ADR rule below
7. **No hardcoded user IDs** - NEVER use `user_id = 1` or any literal ID. Always fetch the real user ID dynamically (e.g. `repo.get_user_id()` in gamification, or query the `users` table). The local user's ID is assigned by SQLite autoincrement and is NOT predictable.
8. **Accessibility preserved** - new/modified widgets have `Semantics`, `tooltip`, `semanticLabel` where required (Rules A1-A4). No new contrast violations introduced.
9. **No hardcoded hub URL** - `hub.bibliogenius.org` must only appear in `ApiService.hubUrl` (production fallback). Everywhere else, use `ApiService.hubUrl` or pass `hubBaseUrl` as parameter.
10. **Consult ADRs when in doubt** - before implementing or modifying networking, E2EE, relay, invite, or sync features, read the relevant ADRs in `bibliogenius-docs/docs/technical/adr/`. They document the intended architecture and fallback patterns (e.g. ADR-004 relay fallback, ADR-009 invite deep links).

> **If the architecture needs to evolve** (e.g., switching from SQLite to Postgres,
> or from Provider to Riverpod), update THIS file FIRST, then implement.

---

## Architecture Decision Records (MANDATORY)

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
|-- bibliogenius/           # Rust backend (see .agents/instructions/rust-backend.md)
|   +-- src/
|       |-- api/           # HTTP API endpoints (thin Axum handlers)
|       |-- domain/        # Pure business abstractions (NO framework deps)
|       |-- infrastructure/# Technical implementations + repository impls
|       |-- modules/       # Integrations + self-contained extensions
|       |   |-- integrations/  # External API clients (BNF, Inventaire...)
|       |   |-- import/        # CSV/JSON parsers
|       |   |-- scanner/       # OCR
|       |   +-- memory_game/   # Extension: Memory Game (ADR-005 pattern)
|       |-- models/        # DTOs + SeaORM entities (API contract)
|       |-- services/      # Business logic orchestration
|       +-- utils/         # Shared utilities
|
+-- bibliogenius-app/       # Flutter frontend (see .agents/instructions/flutter-frontend.md)
    +-- lib/
        |-- screens/       # UI screens
        |-- data/          # Repository pattern (abstract + impl)
        |-- services/      # API, Auth, Sync, Translation, Cache
        |-- providers/     # State management
        |-- widgets/       # Reusable UI components
        +-- src/rust/      # FFI bindings (generated)
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
