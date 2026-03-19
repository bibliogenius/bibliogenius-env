# BiblioGenius - Rust Backend Conventions

> **Edition**: Rust 2024 | **Framework**: Axum 0.7 | **ORM**: SeaORM 0.12
>
> Architecture enforcement rules are in `.agents/instructions/architecture.md`.
> This file covers Rust-specific conventions, patterns, and migration guidance.

---

## Architecture Layers

> **Current State**: Many handlers bypass services (technical debt). Migration in progress via Strangler Fig.

```
TARGET ARCHITECTURE (Clean Architecture)
=========================================

+-------------------------------------------------------------+
|  API Layer (src/api/)                                       |
|  - Axum handlers: extract -> validate -> delegate -> respond|
|  - NO business logic, NO direct DB access                   |
|  - Receives Arc<dyn Repository> via AppState                |
+-------------------------------------------------------------+
|  Domain Layer (src/domain/)                                 |
|  - Repository traits (abstractions only)                    |
|  - DomainError enum                                         |
|  - NO framework dependencies (no SeaORM, no Axum)           |
+-------------------------------------------------------------+
|  Infrastructure Layer (src/infrastructure/)                 |
|  - SeaORM implementations of repository traits              |
|  - External API clients                                     |
|  - Converts DomainError <-> DbErr                           |
+-------------------------------------------------------------+
|  Service Layer (src/services/)                              |
|  - Business logic, orchestration                            |
|  - Transaction management                                   |
|  - Uses repository traits (not concrete impls)              |
+-------------------------------------------------------------+
|  Data Layer (src/models/)                                   |
|  - DTOs for API responses (Book, Copy, Contact)             |
|  - SeaORM entities (internal)                               |
|  - Conversion: Entity <-> DTO                               |
+-------------------------------------------------------------+

DEPENDENCY FLOW (Clean Architecture Rule)
=========================================

  API -> Domain (traits) <- Infrastructure (impl)
         ^
      Services
         ^
      Domain (uses traits, not concrete types)
```

**Rules**:
1. API handlers delegate to services or repositories, never direct DB
2. Domain layer has ZERO external dependencies
3. All DB access goes through repository implementations
4. DTOs in `models/` are the API contract - do not change field names/types

---

## Error Handling

### Service Layer Errors

```rust
#[derive(Debug)]
pub enum ServiceError {
    Database(String),
    NotFound,
    InvalidState(String),
    Validation(String),
}

impl From<sea_orm::DbErr> for ServiceError {
    fn from(e: sea_orm::DbErr) -> Self {
        ServiceError::Database(e.to_string())
    }
}
```

### API Layer Errors

```rust
// Use tuple (StatusCode, Json) for error responses
async fn handler(...) -> Result<Json<T>, (StatusCode, Json<Value>)> {
    service::do_something(&db, id).await.map_err(|e| match e {
        ServiceError::NotFound => (
            StatusCode::NOT_FOUND,
            Json(json!({ "error": "Resource not found" }))
        ),
        ServiceError::Database(msg) => (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(json!({ "error": msg }))
        ),
        // ...
    })?;
    Ok(Json(result))
}
```

### External API Errors

```rust
// Simple String errors for external integrations
pub async fn fetch_metadata(isbn: &str) -> Result<Metadata, String> {
    let resp = client.get(&url).send().await
        .map_err(|e| format!("Request failed: {}", e))?;
    // ...
}
```

---

## Async & HTTP Clients

### Shared HTTP Client (preferred)

```rust
// Build once, reuse via Axum State
let http_client = reqwest::Client::builder()
    .user_agent("BiblioGenius/1.0")
    .timeout(Duration::from_secs(5))
    .build()?;

Router::new()
    .with_state(AppState { db, http_client })
```

### Timeout Standards

| Source Type                        | Timeout | Rationale              |
| ---------------------------------- | ------- | ---------------------- |
| Local DB                           | -       | No timeout needed      |
| Fast APIs (Inventaire, OpenLibrary)| 5s      | Typically < 1s response|
| SPARQL endpoints (BNF)             | 10s     | Complex queries        |
| Google Books                       | 5s      | Rate-limited           |

### Parallel Fetching

```rust
use futures::stream::{self, StreamExt};

// Process up to 5 concurrent requests
let results: Vec<_> = stream::iter(items)
    .map(|item| async { fetch_one(item).await })
    .buffer_unordered(5)
    .collect()
    .await;
```

---

## Database (SeaORM)

### Query Patterns

```rust
// Simple find
let book = book::Entity::find_by_id(id).one(db).await?;

// Filtered query with conditions
let books = book::Entity::find()
    .filter(book::Column::Title.contains(&query))
    .filter(book::Column::IsOwned.eq(true))
    .order_by_asc(book::Column::Title)
    .all(db)
    .await?;

// Always use .as_ref() before .and_then() to avoid moves
let year = entity.claims.publication_date
    .as_ref()
    .and_then(|v| v.first().cloned());
```

### Transactions

```rust
use sea_orm::TransactionTrait;

let txn = db.begin().await?;

// Multiple operations
book::Entity::insert(book_model).exec(&txn).await?;
copy::Entity::insert(copy_model).exec(&txn).await?;

txn.commit().await?;
```

---

## API Endpoints (Axum)

### Handler Signature

```rust
use axum::{extract::{State, Path, Query}, Json};

pub async fn get_book(
    State(db): State<DatabaseConnection>,
    Path(id): Path<i32>,
) -> Result<Json<Book>, (StatusCode, Json<Value>)> {
    // ...
}
```

### Response Consistency

```rust
// Success: Return data directly
Ok(Json(book))

// Success with message
Ok(Json(json!({ "id": new_id, "message": "Created" })))

// Error: Always use { "error": "..." } structure
Err((StatusCode::NOT_FOUND, Json(json!({ "error": "Book not found" }))))
```

---

## External API Integration

### URL Construction

```rust
// Always use helper for image URLs
fn get_entity_image_url(entity: &Entity) -> Option<String> {
    // Priority: entity.image.url > claims.image
    if let Some(img) = &entity.image {
        return Some(normalize_url(&img.url));
    }
    entity.claims.image.as_ref()
        .and_then(|v| v.first().cloned())
        .map(|hash| normalize_url(&hash))
}

fn normalize_url(url: &str) -> String {
    if url.starts_with("http") { url.to_string() }
    else if url.starts_with("/") { format!("https://example.io{}", url) }
    else { format!("https://example.io/img/{}", url) }
}
```

### Batch Fetching

```rust
// Chunk large URI lists to avoid URL length limits
const BATCH_SIZE: usize = 50;

for chunk in uris.chunks(BATCH_SIZE) {
    let joined = chunk.join("|");
    let url = format!("{}?uris={}", API_URL, joined);
    // ...
}
```

---

## Module System & Feature Flags

### Compile-time Features (Cargo.toml)

```toml
[features]
default = ["desktop", "mcp"]
desktop = []           # Desktop binary
mcp = []               # MCP server support
experimental = []      # Experimental features
```

### Runtime Module Toggles

Modules are enabled/disabled via `installation_profile.enabled_modules`:

```rust
// Check if module is enabled
let profile = get_installation_profile(&db).await?;
if profile.enabled_modules.contains("google_books") {
    // Include Google Books in search
}

// Disable specific fallbacks
if profile.enabled_modules.contains("disable_fallback:openlibrary") {
    // Skip OpenLibrary
}
```

### Adding a New Integration Module

1. Create `src/modules/integrations/new_source.rs`
2. Define response structs with `#[derive(Deserialize)]`
3. Implement `pub async fn search_new_source(query: &str) -> Result<Vec<T>, String>`
4. Add to `search_unified()` fallback chain in `api/integrations.rs`
5. Add module name to profile UI in Flutter

---

## Testing

### Unit Tests (in-module)

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_fetch_metadata() {
        let result = fetch_metadata("9782264024848").await;
        assert!(result.is_ok());
        assert_eq!(result.unwrap().title, "Martin Eden");
    }
}
```

### Integration Tests (tests/)

```rust
// tests/api_integration_test.rs
#[tokio::test]
async fn test_book_crud() {
    let db = setup_test_db().await;
    // Test full CRUD cycle
}
```

### Test Database

```rust
async fn setup_test_db() -> DatabaseConnection {
    let db = Database::connect("sqlite::memory:").await.unwrap();
    run_migrations(&db).await;
    db
}
```

---

## Post-Development Checks

**MANDATORY**: After completing any development work, run the following commands:

```bash
# 1. Format code
cargo fmt

# 2. Run linter (fix all warnings)
cargo clippy -- -D warnings

# 3. Run tests
cargo test
```

All three must pass before considering work complete. Clippy warnings should be fixed, not suppressed (unless there's a documented reason).

---

## Code Style

### Prefer Established Crates Over Custom Code

Before writing custom logic, check whether a well-established crate already solves the problem. Evaluate based on: download count (crates.io), maintenance activity, API fit, and dependency footprint. Only write custom code when no suitable crate exists, when the crate would be overkill for the need, or when it would introduce a heavy/unnecessary dependency tree.

### Single Responsibility & File Size

- **Files over 500 lines**: Extract reusable logic into dedicated modules in `src/utils/` or `src/services/`.
- **Handlers should delegate**: API handlers in `src/api/` must stay thin. Business logic, network utilities, and data transformations belong in separate modules.
- **One concern per module**: `peer.rs` (3000+ lines) is legacy debt. When adding new logic that touches it, prefer extracting into a focused utility (e.g., `utils/peer_discovery.rs`) rather than growing the file further.

### Naming

- Structs: `PascalCase` (e.g., `BookService`, `InventaireResponse`)
- Functions: `snake_case` (e.g., `fetch_metadata`, `get_entity_image_url`)
- Constants: `SCREAMING_SNAKE_CASE` (e.g., `USER_AGENT`, `BATCH_SIZE`)
- Modules: `snake_case` (e.g., `inventaire_client`, `book_service`)

### Imports

```rust
// Group imports: std, external crates, local modules
use std::collections::HashMap;

use axum::{extract::State, Json};
use sea_orm::DatabaseConnection;
use serde::{Deserialize, Serialize};

use crate::models::book;
use crate::services::book_service;
```

### Documentation

```rust
/// Fetch book metadata from Inventaire.io by ISBN.
///
/// Returns enriched metadata including authors, cover, and publication year.
/// Falls back to work-level data if edition-specific data is incomplete.
pub async fn fetch_inventaire_metadata(isbn: &str) -> Result<Metadata, String> {
```

---

## Security Checklist

> **For E2EE / crypto code: READ `bibliogenius-docs/docs/technical/SECURITY_GUIDELINES.md` FIRST.**
> It contains the binding security audit (14 findings) and the corrected crypto pipeline.
> Non-compliance with that file is a blocking issue.

- [ ] JWT tokens validated via middleware (currently per-endpoint)
- [ ] SSRF protection: `validate_url()` blocks localhost/loopback
- [ ] Input validation on all user-provided data
- [ ] SQL injection: Use SeaORM parameterized queries (never raw SQL with user input)
- [ ] Secrets: Never log tokens, passwords, or API keys
- [ ] Crypto secrets: `Zeroize` + `SecretBox` wrappers (see SECURITY_GUIDELINES.md A1)
- [ ] No secrets in logs, even in debug builds (see SECURITY_GUIDELINES.md A2)
- [ ] Crate audit: `cargo audit` clean before release (see SECURITY_GUIDELINES.md A4)
- [ ] Relay: read_token NEVER sent to hub or included in outbound payloads (S2)
- [ ] Relay: credential refresh via hub MUST verify x25519 key match before trusting (S3)
- [ ] Relay: connection_request payloads MUST include relay credentials for bidirectional comms
- [ ] Catalog: cover_url pushed to hub MUST be HTTP/HTTPS, never local file paths (S5)

---

## Known Technical Debt

> These patterns exist in the codebase but should be refactored:

1. **Direct DB in API handlers**: ~20 API modules bypass service layer
2. **HTTP client per-request**: Some integrations create new clients each call
3. **Inconsistent error responses**: Mix of string tuples and JSON objects
4. **Manual migrations**: `db.rs` has 800+ lines of raw SQL migrations
5. **Limited test coverage**: ~7 tests for 9,600+ lines of code

---

## Clean Architecture Migration

> **Status**: In Progress | **Strategy**: Strangler Fig Pattern

### Target Structure

```
src/
|-- domain/                    # Pure business logic (NO framework deps)
|   |-- mod.rs
|   |-- errors.rs              # DomainError enum
|   +-- repositories.rs        # Trait definitions only
|
|-- infrastructure/            # Framework implementations
|   |-- mod.rs
|   +-- repositories/
|       |-- mod.rs
|       |-- book_repository.rs      # impl BookRepository for SeaOrm
|       |-- contact_repository.rs
|       +-- ...
|
|-- api/                       # HTTP layer (thin handlers)
|-- models/                    # DTOs (unchanged - API contract)
|-- services/                  # Orchestration layer
+-- modules/                   # External integrations
```

### Migration Phases

| Phase | Description | Risk | Flutter Impact |
|-------|-------------|------|----------------|
| 1 | Create `domain/` traits | None | None |
| 2 | Create `infrastructure/` implementations | None | None |
| 3 | Migrate handlers one by one | Low | None if JSON unchanged |
| 4 | Remove dead code | None | None |

### API Stability Rules (CRITICAL)

These elements form the contract with Flutter and MUST remain unchanged:

**HTTP Routes** (defined in `api/mod.rs`):
- All paths: `/api/books`, `/api/copies`, `/api/contacts`, etc.
- All HTTP methods: GET, POST, PUT, DELETE, PATCH
- All query parameters: `status`, `title`, `author`, `tag`, `q`, `sort`, `page`, `limit`

**JSON Response Structures**:
```rust
// Book - field names and types are CONTRACT
{
  "id": i32,
  "title": String,
  "isbn": Option<String>,
  "summary": Option<String>,           // NOT "description"
  "publisher": Option<String>,
  "publication_year": Option<i32>,
  "cover_url": Option<String>,
  "reading_status": Option<String>,
  "shelf_position": Option<i32>,
  "user_rating": Option<i32>,
  "subjects": Option<Vec<String>>,     // Array, not JSON string
  "digital_formats": Option<Vec<String>>,
  "owned": bool,
  "price": Option<f64>,
  // ... other fields
}
```

**Error Response Format**:
```rust
// MUST always use this structure
{"error": "Human readable message"}

// Status codes: 200, 201, 400, 401, 404, 500
```

**FFI Contract** (`api/frb.rs`):
- All `Frb*` structs: `FrbBook`, `FrbTag`, `FrbContact`, etc.
- All `pub async fn` signatures
- Conversion traits: `From<Model> for FrbBook`, etc.

### Files: DO NOT MODIFY (Contract)

```
src/api/frb.rs           # FFI contract with Flutter
src/api/mod.rs           # Route definitions (paths only)
src/models/book.rs       # Book DTO struct (field names/types)
src/models/copy.rs       # Copy DTO struct
src/models/contact.rs    # Contact DTO struct
src/models/loan.rs       # Loan DTO struct
```

### Files: SAFE TO REFACTOR (Implementation)

```
src/api/books.rs         # Handler logic -> delegate to repository
src/api/collections.rs   # Handler logic -> delegate to repository
src/api/contact.rs       # Handler logic -> delegate to repository
src/api/copy.rs          # Handler logic -> delegate to repository
src/services/*           # Can restructure freely
src/db.rs                # Internal, no API impact
```

### Files: REFACTOR WITH CAUTION (Complex)

```
src/api/peer.rs          # 2,677 LOC, P2P critical - migrate last
src/api/integrations.rs  # 1,227 LOC, external APIs - test thoroughly
```

### Repository Trait Template

```rust
// domain/repositories.rs
use async_trait::async_trait;

#[async_trait]
pub trait BookRepository: Send + Sync {
    async fn find_all(&self, filter: BookFilter) -> Result<Vec<Book>, DomainError>;
    async fn find_by_id(&self, id: i32) -> Result<Option<Book>, DomainError>;
    async fn create(&self, book: Book) -> Result<Book, DomainError>;
    async fn update(&self, id: i32, book: Book) -> Result<Book, DomainError>;
    async fn delete(&self, id: i32) -> Result<(), DomainError>;
}

#[derive(Default)]
pub struct BookFilter {
    pub status: Option<String>,
    pub title: Option<String>,
    pub author: Option<String>,
    pub tag: Option<String>,
    pub query: Option<String>,
    pub sort: Option<String>,
    pub page: Option<u64>,
    pub limit: Option<u64>,
}
```

### Handler Migration Template

```rust
// BEFORE: Direct SeaORM in handler
pub async fn get_book(
    State(db): State<DatabaseConnection>,
    Path(id): Path<i32>,
) -> Result<Json<Book>, (StatusCode, Json<Value>)> {
    let model = BookEntity::find_by_id(id).one(&db).await
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, Json(json!({"error": e.to_string()}))))?;
    // ... 50 lines of logic
}

// AFTER: Delegates to repository
pub async fn get_book(
    State(state): State<AppState>,
    Path(id): Path<i32>,
) -> Result<Json<Book>, (StatusCode, Json<Value>)> {
    state.book_repo
        .find_by_id(id)
        .await
        .map_err(map_domain_error)?
        .map(Json)
        .ok_or((StatusCode::NOT_FOUND, Json(json!({"error": "Book not found"}))))
}
```

### Regression Testing Protocol

Before migrating each handler:

```bash
# 1. Capture current behavior
curl -s http://localhost:3000/api/books | jq . > before.json
curl -s http://localhost:3000/api/books/1 | jq . >> before.json

# 2. Migrate handler

# 3. Compare output
curl -s http://localhost:3000/api/books | jq . > after.json
curl -s http://localhost:3000/api/books/1 | jq . >> after.json
diff before.json after.json  # Must be empty
```

### Checklist Per Handler Migration

- [ ] JSON response structure unchanged (field names, types, nesting)
- [ ] HTTP status codes unchanged (200, 404, 500)
- [ ] Query parameters work identically
- [ ] Error format unchanged: `{"error": "..."}`
- [ ] FFI calls return same data (if applicable)
- [ ] Flutter app tested manually for affected screens
