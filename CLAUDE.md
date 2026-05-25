# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

OneUp is a Flutter + Rust full-stack point-rewards management system. The Rust backend serves both the REST API and the compiled Flutter web app as static files. Deployment is a single Docker container with an embedded SQLite database.

## Development Environment

This project uses a NixOS flake for development. Always enter the dev shell first:

```bash
nix develop
```

The flake provides Rust, Flutter/Dart, sqlx-cli, sqlite, and other tooling.

## Build & Run Commands

### Backend (Rust)
```bash
cd server
cargo build                    # Build debug
cargo build --release          # Build release
cargo run                      # Run server (default: 0.0.0.0:8080)
cargo test                     # Run all tests
cargo test <test_name>         # Run a single test
cargo test routes::            # Run tests in a module
```

### Frontend (Flutter)
```bash
cd flutter
flutter run -d chrome          # Run as web app
flutter run                    # Run as Linux desktop
flutter build web              # Build for web
flutter build linux            # Build for Linux desktop
dart run build_runner build    # Regenerate Freezed/JSON models
dart run build_runner watch    # Watch and regenerate on change
```

### Full Stack Build & Deployment
```bash
make flutter     # Build Flutter web and copy to server/web/
make bin         # Build Rust binary only
make fs          # Build filesystem layout for Docker
make image       # Build Docker image via Nix
make run         # Run Docker container (SQLite volume at /app/data)
make publish     # Push image to ghcr.io/phr0ze/oneup
make clean       # Remove build artifacts
```

### Database
```bash
cd server
sqlx migrate run               # Apply pending migrations
sqlx migrate add <name>        # Create a new migration
```

## Architecture

### Backend (`server/`)

**`src/main.rs`** — Non-async init, custom Tokio runtime, SIGINT/SIGTERM handling, WAL checkpoint on shutdown.

**`src/state/`** — `Config` (IP, port, DB URL, web dir, log level) and `State` (SQLitePool + config). State init runs migrations and seeds the default admin user.

**`src/routes/`** — Axum route definitions. Routes are split into public (no auth) and protected (JWT required). The `routes/mod.rs` wires middleware: CORS (currently permissive), tracing, and JWT authorization middleware.

**`src/db/`** — SQLx data access layer. One module per entity (user, password, role, action, category, point, reward, apikey). All functions are async.

**`src/security/auth.rs`** — Password hashing (PBKDF2-HMAC-SHA256, 100K iterations, 16-byte salt) and JWT (HS256, 1-hour expiry). Bearer token extraction and claims validation.

**`src/errors/`** — Custom `Error` type that maps to HTTP status codes and JSON responses.

**`src/utils/observe.rs`** — Tracing/logging middleware; request/response body logging at DEBUG level.

**Migrations** live in `server/migrations/`. SQLx applies them automatically on startup.

### Frontend (`flutter/`)

**`lib/main.dart`** — Entry point; sets up Provider and renders `Layout()`.

**`lib/providers/appstate.dart`** — Central `AppState` provider. Manages auth token, login/logout, and API call coordination.

**`lib/providers/api.dart`** — Dio HTTP client. Uses relative URLs for web, absolute for native. Tracks token expiration.

**`lib/model/`** — Immutable models generated with Freezed. After modifying any `*.freezed.dart`-adjacent model file, run `dart run build_runner build`.

**`lib/ui/`** — `layout.dart` is the main nav shell. Views under `views/` (points, rewards, settings/*).

### Database Schema

SQLite with tables: `user`, `password` (salt+hash), `role`, `user_role`, `action`, `category`, `point`, `reward`, `apikey`. Foreign keys use CASCADE deletes. Timestamps are managed by SQLite triggers.

### API Contract

- Public: `GET/POST /api/health`, `POST /api/login`, read endpoints for all resources
- Protected (JWT Bearer): write/delete endpoints for admin operations
- Error responses: `{"error": "message"}` with appropriate HTTP status

## Code Patterns

### Rust
- Use `Result`/`Option` with `?` propagation — avoid `unwrap()` in non-test code
- Follow async/await patterns; tokio ecosystem throughout
- New routes follow the pattern in existing route files: extract `State`, validate JWT claims, call `db::` functions, return JSON

### Flutter/Dart
- Models use Freezed for immutability — always regenerate after model changes
- State changes go through `AppState` via `Provider.of<AppState>(context)`
- Keep UI components in `lib/ui/`, data/API logic in `lib/providers/`

## Environment Variables (Runtime)

| Variable | Default | Purpose |
|----------|---------|---------|
| `IP` | `0.0.0.0` | Bind address |
| `PORT` | `8080` | Listen port |
| `DATABASE_URL` | `sqlite:///app/data/sqlite.db` | SQLite path |
| `WEB_APP_DIR` | `./web` | Flutter web build directory |
| `RUST_LOG` | `info` | Log level (debug, info, warn, error) |
