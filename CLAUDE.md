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

# Run a single test file (test/ holds app_smoke_test.dart and num_input_test.dart)
flutter test test/num_input_test.dart

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
    repositories/    # Abstract interfaces returning Either<Failure, T>
  data/
    repositories/    # Concrete implementations (suffix *_drift_impl.dart); map Drift rows <-> entities directly
  presentation/
    bloc/            # bloc/event/state (event+state are `part of` the bloc file)
    pages/           # UI pages
```

Note: there is **no use case layer** — BLoCs depend on repository interfaces directly (e.g. `ProductBloc({required ProductRepository repository})`) and call their methods. There is also no `data/models/` layer; repository implementations convert Drift-generated row classes to domain entities directly. Keep any real business logic in the repository (or the BLoC if it's UI state logic), not in a new pass-through layer.

### Core

- `lib/core/database/` — Drift `AppDatabase`, all table definitions (`tables/`), and DAOs (`daos/`)
- `lib/core/error/failure.dart` — `Failure` base class + typed subclasses: `CacheFailure` (DB/unexpected), `NotFoundFailure` (entity missing), `PermissionFailure` (OS permission denied). `Failure.message` is debug detail only — never shown to users.
- `lib/core/service_locator.dart` — All GetIt registrations
- `lib/core/theme/app_theme.dart` — `AppTheme.lightTheme`
- `lib/config/routes/app_routes.dart` — GoRouter config; `app_shell.dart` — bottom-nav tab shell

### Shared input/format helpers (`lib/core/utils/`)

Reuse these for any money/quantity field or displayed number — don't hand-roll parsing/formatting:
- `num_input.dart` — `NumInput.decimalFormatters` (restrict keystrokes **and paste** to digits + one separator, length-capped) and `NumInput.parseFlexibleNumber` (normalizes Arabic-Indic/Persian digits and Arabic/comma decimal separators; returns `null` for empty/unparseable/**non-finite** input, so downstream `toStringAsFixed` never crashes on `Infinity`/`NaN`). Covered by `test/num_input_test.dart`.
- `format.dart` — `formatQty(num)` prints whole numbers with no decimals and fractional/weight values with up to 3 trimmed decimals; used by cart, checkout, and printed receipts so a sold quantity reads identically everywhere.
- `app_validators.dart` — `AppValidators` composable `TextFormField` validators (e.g. `required(message)`) that take pre-localized messages from the page.

### Dependency Injection

`init()` in `service_locator.dart` registers in strict order (each layer depends on the previous):
1. `AppDatabase` (lazy singleton)
2. DAOs (lazy singletons, each receives `AppDatabase` via `sl()`)
3. Repositories (lazy singletons, each receives its DAO)
4. BLoCs (factories, each receives the repository interface(s) it needs)

`main.dart` provides app-wide BLoCs through a `MultiBlocProvider` and dispatches initial load events (`LoadProducts`, `LoadShopEvent`, `InitPrinterEvent`, `LoadHistoryEvent`).

### Database

Drift (SQLite) backed by `driftDatabase(name: 'fawateer')`. All tables and DAOs are declared in the `@DriftDatabase(...)` annotation on `AppDatabase`. Generated code lives in `*.g.dart` files — **never edit these manually**.

Schema is at **version 7** with a `MigrationStrategy`. When changing tables, bump `schemaVersion` and **append** a new `if (from < N)` block to `onUpgrade` — never edit a shipped block (old installs have already run it). Existing steps:
- v1→v2: added `shopSettings.currencySymbol`
- v2→v3: dropped removed `customers`/`debts`/`purchase_invoices`/`purchase_items`/`cashbox_entries` tables
- v3→v4: added `cost` column to `products` and `salesItems`; created barcode/sales indexes
- v4→v5: replaced `products.stock` (int) with `quantity` (double, supports weight/fractions) and added `minStockAlert` (double); copies old `stock` values into `quantity`
- v5→v6: `salesItems.quantity` int→double (matches `products.quantity` for weight/fractional sales). SQLite can't change a column type in place, so this rebuilds the table via `migrator.alterTable(TableMigration(salesItems))` then re-runs `_createIndexes()` (the rebuild drops the table's indexes).
- v6→v7: debt ledger — created `customers` + `ledger_entries` tables and `_createLedgerIndexes()`. **Purely additive**: no existing table is touched. The sale↔customer link deliberately lives on `ledger_entries.invoiceId` (a credit sale writes a `charge` entry referencing the invoice) rather than a column on `sales_invoices` — this avoids the landmine that the old `customer_id` column is still physically present (orphaned) in pre-removal DBs, which would make `addColumn` throw "duplicate column".

**Foreign keys** are enforced per-connection via `PRAGMA foreign_keys = ON` in `MigrationStrategy.beforeOpen` (runs after migrations — table rebuilds need FKs off). No FK constraints are declared on the tables yet, so it's currently a no-op guard; any FK a future feature adds (e.g. `references(...)`) will actually be enforced. Don't set this pragma inside `onUpgrade`.

Indexes are built by `_createIndexes()` (idempotent `CREATE [UNIQUE] INDEX IF NOT EXISTS`), called from both `onCreate` and the v3→v4 step: a **partial-unique** `idx_products_barcode` (`WHERE barcode != ''`, so many barcode-less items are allowed but non-empty barcodes stay unique), plus `idx_sales_invoices_created_at`, `idx_sales_items_invoice_id`, `idx_sales_items_product_id`. Index/table names use Drift's snake_case. Note: the partial-unique index throws mid-migration if existing rows already share a non-empty barcode.

The `products` table carries a `cost` column (purchase cost, default 0) used for profit-margin reporting; `salesItems` snapshots it at sale time (alongside `productName`/`price`) so historical cost is preserved even if the product is later edited or deleted. Inventory is tracked by `quantity` (double, on-hand) with a `minStockAlert` threshold (`Product.isLowStock` = `minStockAlert > 0 && quantity <= minStockAlert`); the sale flow deducts `quantity` on confirm. The old physical `stock` column is left orphaned by the v4→v5 migration (has `DEFAULT 0`, ignored by Drift) — same approach used when `upiId` was removed; `addColumn`-only migrations avoid table rebuilds. The `sales_invoices.customerId`/`customerName` columns were likewise removed from the table class (and the `Invoice` entity) but stay physically present in existing DBs, ignored by Drift — no migration or `schemaVersion` bump needed, since dropping a column requires no DDL. `SalesDao.deleteInvoice` deletes an invoice and its `sales_items` rows in one transaction (no orphans).

### Localization

- Arabic is the default locale and the app forces `locale: const Locale('ar')` in `main.dart`; supported locales are `ar` and `en`.
- ARB source files live in `lib/l10n/` (`app_en.arb` is the template per `l10n.yaml`); generated `AppLocalizations` is in `lib/l10n/app_localizations.dart`.
- Add new strings to the ARB files, not the generated Dart.

### Active features

| Feature | BLoCs registered | Notes |
|---|---|---|
| billing | `BillingBloc`, `HistoryBloc` | Cart management, barcode scan, sales history. Receipt printing is delegated to `PrinterRepository.printReceipt` (which ensures/reconnects the printer); the BLoC builds `ReceiptLine`s and never touches `PrinterHelper` directly. |
| product | `ProductBloc` | CRUD + barcode lookup |
| shop | `ShopBloc` | Shop profile/settings |
| settings | `PrinterBloc` | Bluetooth printer pairing/config. Domain exposes `PrinterDevice` (not the plugin's `BluetoothInfo`) and `ReceiptLine`; only `core/utils/printer_helper.dart` and the repo impl touch `print_bluetooth_thermal`. `scanDevices` returns `Either<Failure, List<PrinterDevice>>`. |
| licensing | `LicenseBloc` | Subscription/activation gate (see below). The only network-backed feature; has **no DAO** — state lives in `SharedPreferences`, not Drift. Registered as a **singleton** (not a factory) so the router gate and the widget tree share one instance. |
| ledger | `CustomerBloc`, `LedgerBloc` | Customers + debt ledger (see below). `CustomerBloc` (app-wide) is the stream-backed list with derived balances; `LedgerBloc` is per-customer (scoped to the detail route). |

### Licensing & networking (subscription gate)

The app's **first and only server communication**, added for commercial subscriptions. Operator-driven activation, modeled on the Smart-Agent app.

- **`core/network/`** — the app's networking primitive: `ApiClient` (JSON over `http`, timeouts, error→`ApiException` mapping) + `ApiConfig` (base URL, `appName`, operator contacts, device-id salt). Currently points at the **Smart-Agent backend** (`create_device`/`check_device`/`getPlans`), keyed by `appName: 'Fawateer'`, until Fawateer's own server ships — swap `ApiConfig.defaultBaseUrl` then. Two new `Failure` subtypes back this: `NetworkFailure` (offline/timeout) and `ServerFailure` (reached but errored).
- **Device identity** = `SHA-256(ANDROID_ID + ApiConfig.deviceIdSalt)` on Android (`DeviceIdentityService`); iOS/other return a fallback (documented gap — this POS targets Android). No permissions. Surfaced in the UI via `DeviceIdCard` (copy-to-clipboard) on both the activation and subscription screens, so the user can send it to support for operator-driven activation. It's loaded into `LicenseState.deviceId` during the startup `CheckLicenseEvent`.
- **License model** = the server returns an `expiresAt`; `LicenseLocalStorage` caches it (+ last-sync + trusted-server-time) in `SharedPreferences`. The whole app gates on `LicenseStatus.isActive` (verified & not expired & not guard-blocked). Offline it runs on the cache within a **72h grace** window; `LicenseGuards` (pure, testable) enforces that grace and a **5-min clock-rollback** tamper check.
- **Operator flow**: `activate()` calls `create_device`; if unverified, the user picks a plan (`getPlans`) and files a `status:'pending'` request (`requestPlan`), then is handed to WhatsApp/Telegram (`url_launcher`). A human activates the device server-side; the app re-checks on next launch (FCM live-unlock is a deliberate follow-up).
- **The gate** is a GoRouter `redirect` driven by the shared `LicenseBloc` state (via a `ChangeNotifier` bridged to `bloc.stream` as `refreshListenable`): before the first check resolves (`!state.bootstrapped`) → `/splash`, inactive → `/activation` (+ `/activation/plans`), active → the tab shell. Follows the typed-error rule — `LicenseError` maps to ARB via `licenseErrorText`. The gate keys off `bootstrapped` (set true once the first check resolves), **not** the transient `checking` status — so an in-app re-check (Refresh below) doesn't bounce the user to the splash.
- **Management**: while active, Settings → "Subscription" opens `SubscriptionStatusPage` (`/settings/subscription`) showing status/plan/expiry/days-left/last-sync, with Refresh (`CheckLicenseEvent`) and Renew (`/settings/subscription/plans`, reusing `SubscriptionPlansPage`). It lives outside the gate routes, so it's only reachable while active — exactly when the activation screen isn't.
- **Money in this domain stays `double`** (consistent with the rest of the app), rounded at display; no integer-minor-unit migration.

### Debt ledger (customers & credit sales)

Adapted from the Accounts-Ledger reference app onto Fawateer's Drift + Clean-Arch conventions. Lives in `features/ledger/`.

- **Single-entry, derived-balance model** (like the reference): one `ledger_entries` row per movement, `entryType` ∈ {`charge`, `payment`}. The balance is **never stored** — it's `SUM(CASE WHEN entry_type='charge' THEN amount ELSE -amount END)`, computed in SQL (`CustomersDao.watchCustomersWithBalance` for the list; `LedgerDao.watchBalance` for one customer) or summed in `LedgerBloc` from the entries stream. Positive balance = customer owes the shop.
- **Money stays `double`** (app-wide convention), rounded to 2 decimals at write time (`LedgerRepositoryDriftImpl.addEntry`) so float noise can't accumulate in a running balance.
- **Sell on credit**: the checkout's `_CreditAwareConfirm` picks a customer; `ConfirmSaleEvent.customerId` flows to `InvoiceRepository.saveInvoice(..., customerId:)`, which builds a `charge` `LedgerEntriesCompanion` and passes it to `SalesDao.insertInvoiceWithItems` — written in the **same transaction** as the invoice + stock deduction, so a credit sale can't leave an invoice without its debt. A repayment is a manual `payment` entry (invoiceId null).
- **Delete guard**: `CustomerRepository.deleteCustomer` returns `Left(ConflictFailure)` (new `Failure` subtype) when the customer has any ledger entries — history is never silently discarded. `CustomerBloc` maps it to `CustomerMessage.deleteBlocked`; customers also have an `isArchived` flag for soft-hide.
- **Reachable** via its own **bottom-nav tab** "Customers" (`/customers` → list → `detail/:id` / `add` / `edit/:id`) — the 4th shell branch, between Products and Settings (the shell now has **5** tabs).
- **Account statement**: the detail page shares a plain-text Arabic statement (`buildCustomerStatement` → `share_plus`) — header, chronological entries, debit/credit totals, final balance. Handy for WhatsApp debt reminders.

**Android manifest**: the app gained `INTERNET` (release builds don't inherit the debug manifest's auto-added copy — required for the license API) and an `https` `VIEW` `<queries>` intent (so `url_launcher.canLaunchUrl` resolves WhatsApp/Telegram links on Android 11+).

### Navigation (GoRouter)

Routing uses a `StatefulShellRoute.indexedStack` (`AppShell`) with five tab branches; `initialLocation` is `/pos`. `/scanner` is a top-level modal route outside the shell, but is **currently unused** — `HomePage` embeds its own inline live `MobileScanner` for continuous scanning rather than pushing `/scanner`.

`HomePage` also has a tap-to-add product picker (a bottom sheet, not a route) for items without a barcode. Leaving checkout via Back preserves the cart (it is only cleared after a confirmed sale or "New Sale"); checkout exits with `context.pop()` so `HomePage`'s awaited `push('/pos/checkout')` resumes the camera.

- Branch 0: `/pos` → `HomePage` → `/pos/checkout` → `CheckoutPage`
- Branch 1: `/history` → `HistoryPage`
- Branch 2: `/products` → `ProductListPage` → `/products/add`, `/products/edit/:id` (passes `Product` via `state.extra`)
- Branch 3: `/customers` → `CustomersPage` → `/customers/add`, `/customers/edit/:id` (passes `Customer` via `state.extra`), `/customers/detail/:id` (scopes `LedgerBloc`)
- Branch 4: `/settings` → `SettingsPage` → `/settings/shop` → `ShopDetailsPage`; `/settings/subscription` → `SubscriptionStatusPage` → `/settings/subscription/plans`
- Top-level: `/scanner` → `ScannerPage`
- Top-level (licensing gate, outside the shell): `/splash` → `SplashPage`; `/activation` → `ActivationPage` → `/activation/plans` → `SubscriptionPlansPage`. A `redirect` on the shared `LicenseBloc` state holds unlicensed users here before any tab is reachable.

History and the product list are **stream-backed**: `ProductBloc`/`HistoryBloc` dispatch `LoadProducts`/`LoadHistoryEvent` once at startup, which subscribe (via `emit.forEach`) to `repository.watchProducts()`/`watchInvoices()`. After a sale, the stock decrement and new invoice flow back automatically — there is no manual reload after a confirmed sale (the old `refreshHistoryIfNeeded` helper was removed). Product mutation handlers (add/update/delete) emit only their transient success/error message; the list itself updates from the stream.

### Functional error handling

Repositories return `Either<Failure, T>` from fpdart. BLoCs call the repository, then `.fold(onLeft, onRight)` (or `result.match`), emitting an error state on `Left` and a success state on `Right`.

**No user-facing English in BLoCs.** A BLoC that hits a failure stores a *typed* error in its state — either the `Failure` subtype or a feature error enum (`BillingError`, `PrinterError`) — never a pre-rendered string. The page maps that type to a localized ARB string (`billingErrorText(...)`, `_printerErrorText(...)`). Add new error strings to the ARB files. (`PrinterRepository.connect`/`disconnect`/`printReceipt` still return plain `bool` — a connect/print is a boolean outcome, not an error channel; only `scanDevices` returns `Either` because it can fail on permission.)

Note: Product/Shop BLoC *success* messages (e.g. "Product added successfully") are still English — localizing those is a separate i18n pass, not part of the failure taxonomy.
