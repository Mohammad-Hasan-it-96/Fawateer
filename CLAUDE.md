# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Fawateer** (Arabic: فواتير, "invoices") is a simple offline-first POS app for small shops (package name: `billing_app`). It supports barcode scanning, Bluetooth thermal printing, product/inventory management, and sales invoices with history. The UI is **Arabic-first (RTL)** with English as a secondary locale.

## Commands

```bash
# Run the app
flutter run

# Analyze for lint/type errors
flutter analyze

# Run tests
flutter test

# Run a single test file
flutter test test/widget_test.dart

# Regenerate Drift database code (*.g.dart files)
dart run build_runner build --delete-conflicting-outputs

# Watch and regenerate on file changes
dart run build_runner watch --delete-conflicting-outputs
```

Run `build_runner` whenever you modify Drift table definitions (`lib/core/database/tables/`), DAO files (`lib/core/database/daos/`), or the `AppDatabase` class. Localization Dart code (`lib/l10n/app_localizations*.dart`) is generated from the ARB files automatically by `flutter run`/`flutter gen-l10n` because `generate: true` is set in `pubspec.yaml`.

## Architecture

The project follows **Clean Architecture** with **BLoC** state management. DI is via **GetIt** (`sl`), routing via **GoRouter**, functional error handling via **fpdart**.

### Layer structure (per feature)

```
lib/features/<feature>/
  domain/
    entities/        # Pure Dart classes (Equatable)
    repositories/    # Abstract interfaces
    usecases/        # extends UseCase<Result, Params> (often grouped in one file, e.g. product_usecases.dart)
  data/
    repositories/    # Concrete implementations (suffix *_drift_impl.dart); map Drift rows <-> entities directly
  presentation/
    bloc/            # separate bloc/event/state files (NOT part directives — imported individually)
    pages/           # UI pages
```

Note: there is no `data/models/` layer — repository implementations convert Drift-generated row classes to domain entities directly. BLoC event/state classes live in their own files and are imported explicitly (see `main.dart` importing `product_bloc.dart` + `product_event.dart`).

### Core

- `lib/core/database/` — Drift `AppDatabase`, all table definitions (`tables/`), and DAOs (`daos/`)
- `lib/core/error/failure.dart` — `Failure` base class (currently only `CacheFailure`)
- `lib/core/usecase/usecase.dart` — `UseCase<Result, Params>` returning `Future<Either<Failure, Result>>`
- `lib/core/service_locator.dart` — All GetIt registrations
- `lib/core/theme/app_theme.dart` — `AppTheme.lightTheme`
- `lib/config/routes/app_routes.dart` — GoRouter config; `app_shell.dart` — bottom-nav tab shell

### Dependency Injection

`init()` in `service_locator.dart` registers in strict order (each layer depends on the previous):
1. `AppDatabase` (lazy singleton)
2. DAOs (lazy singletons, each receives `AppDatabase` via `sl()`)
3. Repositories (lazy singletons, each receives its DAO)
4. Use cases (lazy singletons)
5. BLoCs (factories)

`main.dart` provides app-wide BLoCs through a `MultiBlocProvider` and dispatches initial load events (`LoadProducts`, `LoadShopEvent`, `InitPrinterEvent`, `LoadHistoryEvent`).

### Database

Drift (SQLite) backed by `driftDatabase(name: 'fawateer')`. All tables and DAOs are declared in the `@DriftDatabase(...)` annotation on `AppDatabase`. Generated code lives in `*.g.dart` files — **never edit these manually**.

Schema is at **version 5** with a `MigrationStrategy`. When changing tables, bump `schemaVersion` and **append** a new `if (from < N)` block to `onUpgrade` — never edit a shipped block (old installs have already run it). Existing steps:
- v1→v2: added `shopSettings.currencySymbol`
- v2→v3: dropped removed `customers`/`debts`/`purchase_invoices`/`purchase_items`/`cashbox_entries` tables
- v3→v4: added `cost` column to `products` and `salesItems`; created barcode/sales indexes
- v4→v5: replaced `products.stock` (int) with `quantity` (double, supports weight/fractions) and added `minStockAlert` (double); copies old `stock` values into `quantity`

Indexes are built by `_createIndexes()` (idempotent `CREATE [UNIQUE] INDEX IF NOT EXISTS`), called from both `onCreate` and the v3→v4 step: a **partial-unique** `idx_products_barcode` (`WHERE barcode != ''`, so many barcode-less items are allowed but non-empty barcodes stay unique), plus `idx_sales_invoices_created_at`, `idx_sales_items_invoice_id`, `idx_sales_items_product_id`. Index/table names use Drift's snake_case. Note: the partial-unique index throws mid-migration if existing rows already share a non-empty barcode.

The `products` table carries a `cost` column (purchase cost, default 0) used for profit-margin reporting; `salesItems` snapshots it at sale time (alongside `productName`/`price`) so historical cost is preserved even if the product is later edited or deleted. Inventory is tracked by `quantity` (double, on-hand) with a `minStockAlert` threshold (`Product.isLowStock` = `minStockAlert > 0 && quantity <= minStockAlert`); the sale flow deducts `quantity` on confirm. The old physical `stock` column is left orphaned by the v4→v5 migration (has `DEFAULT 0`, ignored by Drift) — same approach used when `upiId` was removed; `addColumn`-only migrations avoid table rebuilds.

### Localization

- Arabic is the default locale and the app forces `locale: const Locale('ar')` in `main.dart`; supported locales are `ar` and `en`.
- ARB source files live in `lib/l10n/` (`app_en.arb` is the template per `l10n.yaml`); generated `AppLocalizations` is in `lib/l10n/app_localizations.dart`.
- Add new strings to the ARB files, not the generated Dart.

### Active features

| Feature | BLoCs registered | Notes |
|---|---|---|
| billing | `BillingBloc`, `HistoryBloc` | Cart management, barcode scan, Bluetooth printing, sales history |
| product | `ProductBloc` | CRUD + barcode lookup |
| shop | `ShopBloc` | Shop profile/settings |
| settings | `PrinterBloc` | Bluetooth printer pairing/config |

### Navigation (GoRouter)

Routing uses a `StatefulShellRoute.indexedStack` (`AppShell`) with four tab branches; `initialLocation` is `/pos`. `/scanner` is a top-level modal route outside the shell, but is **currently unused** — `HomePage` embeds its own inline live `MobileScanner` for continuous scanning rather than pushing `/scanner`.

`HomePage` also has a tap-to-add product picker (a bottom sheet, not a route) for items without a barcode. Leaving checkout via Back preserves the cart (it is only cleared after a confirmed sale or "New Sale"); checkout exits with `context.pop()` so `HomePage`'s awaited `push('/pos/checkout')` resumes the camera.

- Branch 0: `/pos` → `HomePage` → `/pos/checkout` → `CheckoutPage`
- Branch 1: `/history` → `HistoryPage`
- Branch 2: `/products` → `ProductListPage` → `/products/add`, `/products/edit/:id` (passes `Product` via `state.extra`)
- Branch 3: `/settings` → `SettingsPage` → `/settings/shop` → `ShopDetailsPage`
- Top-level: `/scanner` → `ScannerPage`

`refreshHistoryIfNeeded(context)` in `app_routes.dart` re-loads `HistoryBloc` after a confirmed sale (no-op if the History tab isn't built yet).

### Functional error handling

Use cases return `Either<Failure, T>` from fpdart. Callers use `.fold(onLeft, onRight)` or `result.match`. BLoCs emit an error state on `Left` and a success state on `Right`.
