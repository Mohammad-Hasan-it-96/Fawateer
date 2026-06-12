# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Fawateer** is a Flutter billing, invoicing, and accounting app (package name: `billing_app`). It supports barcode scanning, Bluetooth thermal printing, product/inventory management, customer tracking, purchases, and cashbox entries.

## Commands

```bash
# Run the app
flutter run

# Analyze for lint/type errors
flutter analyze

# Run tests
flutter test

# Run a single test file
flutter test test/path/to/test_file.dart

# Regenerate Drift DB code, json_serializable models, and Hive adapters
dart run build_runner build --delete-conflicting-outputs

# Watch and regenerate on file changes
dart run build_runner watch --delete-conflicting-outputs
```

Code generation is required whenever you modify:
- Drift table definitions (`lib/core/database/tables/`)
- Drift DAO files (`lib/core/database/daos/`)
- Classes annotated with `@JsonSerializable` or `@HiveType`

## Architecture

The project follows **Clean Architecture** with **BLoC** state management.

### Layer structure (per feature)

```
lib/features/<feature>/
  domain/
    entities/        # Pure Dart classes (Equatable)
    repositories/    # Abstract interfaces
    usecases/        # One class per use case, extends UseCase<Result, Params>
  data/
    models/          # Data-layer models with serialization
    repositories/    # Concrete implementations (suffix *_drift_impl.dart)
  presentation/
    bloc/            # BLoC + event + state files (part directives)
    pages/           # UI pages
```

### Core

- `lib/core/database/` — Drift `AppDatabase`, all table definitions, and DAOs
- `lib/core/error/failure.dart` — `Failure` base class; currently only `CacheFailure`
- `lib/core/usecase/usecase.dart` — `UseCase<Result, Params>` returning `Future<Either<Failure, Result>>`
- `lib/core/service_locator.dart` — All GetIt registrations (DAOs → Repositories → UseCases → BLoCs)
- `lib/config/routes/app_routes.dart` — GoRouter configuration

### Dependency Injection

GetIt is used via `sl`. Registration order in `service_locator.dart` matters:
1. `AppDatabase` (lazy singleton)
2. DAOs (lazy singletons, each receives `AppDatabase`)
3. Repositories (lazy singletons, each receives its DAO)
4. Use cases (lazy singletons)
5. BLoCs (factories)

### Database

Drift (SQLite) is the active database, backed by `driftDatabase(name: 'fawateer')`. Each feature's DAO lives in `lib/core/database/daos/` and is declared in `@DriftDatabase(daos: [...])`. Generated code lives in `*.g.dart` files — never edit these manually.

> **Note:** Hive still exists as a transient dependency (`lib/core/data/hive_database.dart`, `*_impl.dart` files). Old Hive repository implementations are superseded by `*_drift_impl.dart`. Hive will be removed after full migration.

### Active features

| Feature | BLoC registered | Notes |
|---|---|---|
| billing | `BillingBloc` | Cart management, barcode scan, Bluetooth printing |
| product | `ProductBloc` | CRUD + barcode lookup |
| shop | `ShopBloc` | Shop profile/settings |
| settings | `PrinterBloc` | Bluetooth printer pairing/config |
| customers | — | Entities + repository only (no BLoC yet) |
| purchases | — | Entities + repository only (no BLoC yet) |
| cashbox | — | Entities + repository only (no BLoC yet) |

### Navigation (GoRouter)

- `/` → `HomePage` (billing)
  - `/scanner` → `ScannerPage`
  - `/checkout` → `CheckoutPage`
- `/products` → `ProductListPage`
  - `/products/add`
  - `/products/edit/:id` (passes `Product` via `extra`)
- `/shop` → `ShopDetailsPage`
- `/settings` → `SettingsPage`

### Functional error handling

Use cases return `Either<Failure, T>` from `fpdart`. Callers use `.fold(onLeft, onRight)` or `result.match`. BLoCs emit error state strings on `Left`, and success state on `Right`.
