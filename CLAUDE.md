# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Fawateer** (Arabic: فواتير, "invoices") is an offline-first POS app for small shops (package name: `billing_app`) with an online-validated **subscription gate** on top. It supports barcode scanning, Bluetooth thermal printing, product/inventory management, sales invoices with a filter/summary **audit center**, a **customer debt ledger** (credit sales), and a **cash drawer** (cashbox). The UI is **Arabic-first (RTL)** with English as a secondary locale.

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
- `lib/core/error/failure.dart` — `Failure` base class + typed subclasses: `CacheFailure` (DB/unexpected), `NotFoundFailure` (entity missing), `PermissionFailure` (OS permission denied), `DuplicateFailure` (unique-name clash, e.g. a second customer with the same name), `ConflictFailure` (delete blocked by existing history), `NetworkFailure` (offline/timeout) and `ServerFailure` (server reached but errored). `Failure.message` is debug detail only — never shown to users.
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

`main.dart` provides app-wide BLoCs through a `MultiBlocProvider` and dispatches initial load events (`LoadProducts`, `LoadShopEvent`, `InitPrinterEvent`, `LoadHistoryEvent`, `LoadCustomers`, `LoadCashbox`, `CheckLicenseEvent`). `LicenseBloc` is a `.value` provider (the shared singleton). The per-customer `LedgerBloc` is *not* here — it's scoped to the `/customers/detail/:id` route.

### Database

Drift (SQLite) backed by `driftDatabase(name: 'fawateer')`. All tables and DAOs are declared in the `@DriftDatabase(...)` annotation on `AppDatabase`. Generated code lives in `*.g.dart` files — **never edit these manually**.

There's also a generic `AppSettings` key-value table (`SettingRow`, `key`/`value` PK) for small app-level prefs (e.g. `printer_mac`, `printer_name`) that don't warrant their own typed table.

Schema is at **version 9** with a `MigrationStrategy`. When changing tables, bump `schemaVersion` and **append** a new `if (from < N)` block to `onUpgrade` — never edit a shipped block (old installs have already run it). Existing steps:
- v1→v2: added `shopSettings.currencySymbol`
- v2→v3: dropped removed `customers`/`debts`/`purchase_invoices`/`purchase_items`/`cashbox_entries` tables
- v3→v4: added `cost` column to `products` and `salesItems`; created barcode/sales indexes
- v4→v5: replaced `products.stock` (int) with `quantity` (double, supports weight/fractions) and added `minStockAlert` (double); copies old `stock` values into `quantity`
- v5→v6: `salesItems.quantity` int→double (matches `products.quantity` for weight/fractional sales). SQLite can't change a column type in place, so this rebuilds the table via `migrator.alterTable(TableMigration(salesItems))` then re-runs `_createIndexes()` (the rebuild drops the table's indexes).
- v6→v7: debt ledger — created `customers` + `ledger_entries` tables and `_createLedgerIndexes()`. **Purely additive**: no existing table is touched. The sale↔customer link deliberately lives on `ledger_entries.invoiceId` (a credit sale writes a `charge` entry referencing the invoice) rather than a column on `sales_invoices` — this avoids the landmine that the old `customer_id` column is still physically present (orphaned) in pre-removal DBs, which would make `addColumn` throw "duplicate column".
- v7→v8: added `products.saleType` (text, default `'piece'`) for sell-by-weight. Additive `addColumn`; every existing product decodes as `piece`.
- v8→v9: cashbox — created the `cashbox_transactions` table and `_createCashboxIndexes()`. **Purely additive**: no existing table is touched. Uses the name `cashbox_transactions` deliberately (not `cashbox_entries`, which was a *different* removed pre-v3 table already dropped in the v2→v3 step) so there's no collision.

**Foreign keys** are enforced per-connection via `PRAGMA foreign_keys = ON` in `MigrationStrategy.beforeOpen` (runs after migrations — table rebuilds need FKs off). No FK constraints are declared on the tables yet, so it's currently a no-op guard; any FK a future feature adds (e.g. `references(...)`) will actually be enforced. Don't set this pragma inside `onUpgrade`.

Indexes are built by three idempotent (`CREATE [UNIQUE] INDEX IF NOT EXISTS`) helpers, each called from `onCreate` and from the migration step that first needs it: `_createIndexes()` (POS — partial-unique `idx_products_barcode` `WHERE barcode != ''` so barcode-less items are allowed but non-empty barcodes stay unique, plus `idx_sales_invoices_created_at`, `idx_sales_items_invoice_id`, `idx_sales_items_product_id`), `_createLedgerIndexes()` (`idx_ledger_customer_id`, `idx_ledger_invoice_id`), and `_createCashboxIndexes()` (`idx_cashbox_occurred_at`, `idx_cashbox_related_id`). Index/table names use Drift's snake_case. Note: before creating the partial-unique barcode index, `_createIndexes()` first de-dups (blanks the barcode on all-but-the-earliest row per non-empty barcode) — otherwise the index would throw mid-migration and brick the DB on a legacy v1–v3 install that holds two products with the same barcode.

The `products` table carries a `cost` column (purchase cost, default 0) used for profit-margin reporting; `salesItems` snapshots it at sale time (alongside `productName`/`price`) so historical cost is preserved even if the product is later edited or deleted. Inventory is tracked by `quantity` (double, on-hand) with a `minStockAlert` threshold (`Product.isLowStock` = `minStockAlert > 0 && quantity <= minStockAlert`); the sale flow deducts `quantity` on confirm. The old physical `stock` column is left orphaned by the v4→v5 migration (has `DEFAULT 0`, ignored by Drift) — same approach used when `upiId` was removed; `addColumn`-only migrations avoid table rebuilds. The `sales_invoices.customerId`/`customerName` columns were likewise removed from the table class (and the `Invoice` entity) but stay physically present in existing DBs, ignored by Drift — no migration or `schemaVersion` bump needed, since dropping a column requires no DDL. `SalesDao.deleteInvoice` deletes an invoice and its `sales_items` rows in one transaction (no orphans).

### Sale types (piece vs sell-by-weight)

`Product.saleType` is a `ProductSaleType` enum (`product_sale_type.dart`): `piece` (default) or `weight`, with `isMeasured`/`fromName` helpers and room to grow (volume/length/box) with **no migration** — it's persisted **by name string** in `products.saleType`, never by index, so reordering enum cases can't remap rows. `price` doubles as the **per-kg price** for weighed products.

- A weighed product is entered via `_MeasuredEntryDialog` (in `home_page.dart`): weight (kg) and money amount shown together and **live-linked** (typing one recomputes the other at the per-kg price; only the non-focused controller is written, so no feedback loop). It returns a **weight** which becomes the cart line's `quantity`.
- **Exact-money precision**: the weight is stored at full `double` precision (only `formatQty`-rounded for *display*), so `price × quantity` reconstructs the entered amount exactly (`5000` → `5000.00`). Consequence: **no stored line-total column** — history/receipts derive the total from the per-line `price` + `quantity` snapshots.
- Wiring: the picker and cart-edit call the dialog directly; a **scanned** weighed product surfaces via the transient `BillingState.measuredPrompt` (the BLoC never opens UI). `AddProductToCartEvent` has an optional `quantity` — when set it's an absolute add-or-replace (measured), when null it's the piece +1 behavior. `ReceiptLine.unit` (`'كغ'`) makes the raster receipt print `0.333 كغ × …`.

### Localization

- Arabic is the default locale and the app forces `locale: const Locale('ar')` in `main.dart`; supported locales are `ar` and `en`.
- ARB source files live in `lib/l10n/` (`app_en.arb` is the template per `l10n.yaml`); generated `AppLocalizations` is in `lib/l10n/app_localizations.dart`.
- Add new strings to the ARB files, not the generated Dart.

### Active features

| Feature | BLoCs registered | Notes |
|---|---|---|
| billing | `BillingBloc`, `HistoryBloc` | Cart management, barcode scan, and the sales-history **audit center** (see below). Receipt printing is delegated to `PrinterRepository.printReceipt` (which ensures/reconnects the printer); the BLoC builds `ReceiptLine`s and never touches `PrinterHelper` directly. |
| product | `ProductBloc` | CRUD + barcode lookup |
| shop | `ShopBloc` | Shop profile/settings |
| settings | `PrinterBloc` | Bluetooth printer pairing/config. Domain exposes `PrinterDevice` (not the plugin's `BluetoothInfo`) and `ReceiptLine`; only `core/utils/printer_helper.dart` and the repo impl touch `print_bluetooth_thermal`. `scanDevices` returns `Either<Failure, List<PrinterDevice>>`. |
| licensing | `LicenseBloc` | Subscription/activation gate (see below). The only network-backed feature; has **no DAO** — state lives in `SharedPreferences`, not Drift. Registered as a **singleton** (not a factory) so the router gate and the widget tree share one instance. |
| ledger | `CustomerBloc`, `LedgerBloc` | Customers + debt ledger (see below). `CustomerBloc` (app-wide) is the stream-backed list with derived balances; `LedgerBloc` is per-customer (scoped to the detail route). |
| cashbox | `CashboxBloc` | Cash drawer / signed cash ledger (see below). App-wide, stream-backed; auto-posts on cash sales & debt repayments. |

### Licensing & networking (subscription gate)

The app's **first and only server communication**, added for commercial subscriptions. Operator-driven activation, modeled on the Smart-Agent app.

- **`core/network/`** — the app's networking primitive: `ApiClient` (JSON over `http`, timeouts, error→`ApiException` mapping) + `ApiConfig` (base URL, `appName`, operator contacts, device-id salt). Currently points at the **Smart-Agent backend** (`create_device`/`check_device`/`getPlans`/`update_my_data`), keyed by `appName: 'Fawateer'`, until Fawateer's own server ships. `ApiConfig.baseUrl` and the support contacts are **runtime-mutable** (not `const`) — `ApiClient` reads `baseUrl` per-request, so the remote config (below) can repoint the server without a rebuild; `defaultBaseUrl` is the baked-in fallback. Two `Failure` subtypes back this: `NetworkFailure` (offline/timeout) and `ServerFailure` (reached but errored).
- **`core/config/` remote config** — `RemoteConfigService` fetches a hosted `fawateer_version.json` at startup (time-boxed, → SharedPreferences cache → baked-in defaults; `main.dart` awaits it briefly before the first license call). It overwrites `ApiConfig.baseUrl` + support contacts, and drives an **in-app update prompt**: compares `latest_version` to `package_info_plus`'s installed version and, if newer, `_UpdateChecker` (wrapping `MaterialApp.router`) shows a one-time dialog with a Download button opening the ABI-matched APK URL (`device_info_plus` `supportedAbis`). Registered in `service_locator.dart`.
- **Device identity** (`DeviceIdentityService`) = `SHA-256(rawId + ApiConfig.deviceIdSalt)`, where `rawId` is `ANDROID_ID` on Android (`android_id`) and `identifierForVendor` on iOS (`device_info_plus`); both are hashed with the salt so the two platforms emit interchangeable opaque tokens. Other platforms — or a null/empty native id (e.g. iOS `identifierForVendor` before first unlock) — fall back to the constant `'fallback_device_id'`; it never throws. No permissions. Surfaced in the UI via `DeviceIdCard` (copy-to-clipboard) on both the activation and subscription screens, so the user can send it to support for operator-driven activation. It's loaded into `LicenseState.deviceId` during the startup `CheckLicenseEvent`.
- **License model** = the server returns an `expiresAt`; `LicenseLocalStorage` caches it (+ last-sync + trusted-server-time) in `SharedPreferences`. The whole app gates on `LicenseStatus.isActive` (verified & not expired & not guard-blocked). Offline it runs on the cache within a **72h grace** window; `LicenseGuards` (pure, testable) enforces that grace and a **5-min clock-rollback** tamper check.
- **Operator flow**: `activate()` calls `create_device`; if unverified, the user picks a plan (`getPlans`) and files a `status:'pending'` request (`requestPlan`), then is handed to WhatsApp/Telegram (`url_launcher`). A human activates the device server-side; the app then unlocks **live** via FCM (below), falling back to a re-check on next launch.
- **FCM live-unlock**: `PushNotificationService` (`features/licensing/data/services/`) wires Firebase Cloud Messaging so an operator-side activation unlocks the app instantly — a data message with `data.type` ∈ {`new_plan_activated`, `subscription_activated`, `license_updated`} invokes `onLicenseChanged`, which `main.dart` wires to `LicenseBloc.add(CheckLicenseEvent())` (the shared singleton the gate reads), so the gate flips to active with no restart. If the push lands while the app is in the **foreground**, a second callback (`onForegroundLicenseChange`) also fires a visible in-app banner (`subscriptionActivatedBanner` SnackBar via a top-level `rootMessengerKey`); background/terminated deliveries surface as an OS tray notification instead, so they don't double up. The FCM token is registered with the server (`activate()` attaches the cached token to `create_device`; `LicenseRepository.registerPushToken` refreshes it via `update_my_data` on token rotation). **It's dormant by default and self-disabling**: with no Firebase project configured, `Firebase.initializeApp()` fails gracefully and push stays off — the app builds/runs unchanged. Enabling it (google-services.json + two Gradle plugin lines, both stubbed as comments) and the exact server payload are documented in `android/README-fcm.md`. Deps: `firebase_core`, `firebase_messaging`. Manifest gained `POST_NOTIFICATIONS` (Android 13+ tray banner).
- **The gate** is a GoRouter `redirect` driven by the shared `LicenseBloc` state (via a `ChangeNotifier` bridged to `bloc.stream` as `refreshListenable`): before the first check resolves (`!state.bootstrapped`) → `/splash`, inactive → `/activation` (+ `/activation/plans`), active → the tab shell. Follows the typed-error rule — `LicenseError` maps to ARB via `licenseErrorText`. The gate keys off `bootstrapped` (set true once the first check resolves), **not** the transient `checking` status — so an in-app re-check (Refresh below) doesn't bounce the user to the splash.
- **Management**: while active, Settings → "Subscription" opens `SubscriptionStatusPage` (`/settings/subscription`) showing status/plan/expiry/days-left/last-sync, with Refresh (`CheckLicenseEvent`) and Renew (`/settings/subscription/plans`, reusing `SubscriptionPlansPage`). It lives outside the gate routes, so it's only reachable while active — exactly when the activation screen isn't.
- **Editable account**: `SettingsPage` has an "Account details" section (reads the shared `LicenseBloc`) that edits the agent **name/phone** via a bottom sheet and shows a copyable device ID. `UpdateAgentEvent` → `LicenseRepository.updateAgent` **saves locally first** (never lost) then best-effort syncs (`update_my_data`); the one-shot `AgentSaveOutcome` (`synced`/`localOnly`) drives a green/orange snackbar.
- **Money in this domain stays `double`** (consistent with the rest of the app), rounded at display; no integer-minor-unit migration.

### Debt ledger (customers & credit sales)

Adapted from the Accounts-Ledger reference app onto Fawateer's Drift + Clean-Arch conventions. Lives in `features/ledger/`.

- **Single-entry, derived-balance model** (like the reference): one `ledger_entries` row per movement, `entryType` ∈ {`charge`, `payment`}. The balance is **never stored** — it's `SUM(CASE WHEN entry_type='charge' THEN amount ELSE -amount END)`, computed in SQL (`CustomersDao.watchCustomersWithBalance` for the list; `LedgerDao.watchBalance` for one customer) or summed in `LedgerBloc` from the entries stream. Positive balance = customer owes the shop.
- **Money stays `double`** (app-wide convention), rounded to 2 decimals at write time (`LedgerRepositoryDriftImpl.addEntry`) so float noise can't accumulate in a running balance.
- **Sell on credit**: the checkout's `_CreditAwareConfirm` picks a customer; `ConfirmSaleEvent.customerId` flows to `InvoiceRepository.saveInvoice(..., customerId:)`. A sale is **either cash or credit, never both** (keyed off `customerId == null`): a credit sale builds a `charge` `LedgerEntriesCompanion`, a cash sale builds a `cashSale` `CashboxTransactionsCompanion` — one of the two is passed to `SalesDao.insertInvoiceWithItems` and written in the **same transaction** as the invoice + stock deduction, so a sale can never leave an invoice without its matching debt (or its cash-drawer entry). A repayment is a manual `payment` entry (invoiceId null) which **also** posts a matching cashbox inflow (below).
- **Delete guard**: `CustomerRepository.deleteCustomer` returns `Left(ConflictFailure)` (new `Failure` subtype) when the customer has any ledger entries — history is never silently discarded. `CustomerBloc` maps it to `CustomerMessage.deleteBlocked`; customers also have an `isArchived` flag for soft-hide.
- **Reachable** via its own **bottom-nav tab** "Customers" (`/customers` → list → `detail/:id` / `add` / `edit/:id`) — the 4th shell branch, between Products and Settings (the shell now has **5** tabs).
- **Account statement**: `buildCustomerStatement` produces one Arabic text statement (header, chronological entries, debit/credit totals, final balance) used by **both** the detail page's **share** (`share_plus` — WhatsApp reminders) and **print** actions. Printing goes `PrintStatement` event → `PrinterRepository.printStatement(text)` → `PrinterHelper.printStatement` → `ReceiptImage.buildTextEscPosBytes` (renders the text to a **raster bitmap**, since the plain-text ESC/POS path replaces non-Latin with `?` — Arabic must be shipped as pixels). `LedgerBloc` therefore also depends on `PrinterRepository`.

### Cashbox (cash drawer)

A **single-entry, derived-balance** cash ledger (same model as the debt ledger), in `features/cashbox/`. One `cashbox_transactions` row per movement; the balance is **never stored** — it's `SUM(amount)` where `amount` is **signed** (`+` in, `−` out), simpler than the debt ledger's `SUM(CASE …)` because the sign already lives in the value. `CashboxDao.watchBalance` computes it. Money stays `double`, rounded to 2 decimals at write time (`CashboxRepositoryDriftImpl.addTransaction`).

- **`CashTransactionType`** (`cash_transaction_type.dart`) is an extensible enum persisted **by name** (never index — same rule as `ProductSaleType`/ledger entry types). Each type has a `defaultDirection` (`inflow`/`outflow`/`either`); `manualAdjustment` is the only bidirectional one (the entry UI shows an in/out toggle). `purchasePayment`/`supplierPayment` are **reserved** — no purchases/suppliers module exists yet, but those flows can post here with no migration when they ship. `manualTypes` is the user-pickable subset for a manual entry.
- **Auto-posted, source-owned entries**: a **cash sale** posts a `cashSale` inflow (from `SalesDao.insertInvoiceWithItems`, in the sale's transaction — see the ledger section) and a **debt repayment** posts a `customerDebtPayment` inflow (from `LedgerRepositoryDriftImpl.addEntry`, in the payment's transaction — so `LedgerRepository` also depends on `CashboxDao`). Both link back via `relatedId` (invoice id / ledger-entry id) and are flagged `isSystemGenerated`: the cashbox UI **won't let you delete them** (`CashboxMessage.deleteNotAllowed`) — you delete the *source* instead, which **reverses** the cashbox entry (`CashboxDao.deleteByRelatedId`, called from `SalesDao.deleteInvoice` / `LedgerDao` delete) so the derived balance stays honest.
- **Reachable** from **Settings → Cashbox** (`/settings/cashbox` → `/settings/cashbox/history`), *not* its own tab — the shell still has 5 tabs. `CashboxBloc` is app-wide (provided in `main.dart`, dispatched `LoadCashbox` at startup).
- **Shared money formatting**: `core/utils/money_display.dart` is used by both the cashbox and the ledger presentation layers.

### Sales history / audit center

The History tab (`HistoryBloc` + `HistoryPage`) is a **filter-driven, paginated audit center**, not a flat list:
- **Filter** (`SalesFilter`): a `DatePreset` (`today`/`yesterday`/`thisWeek`/`thisMonth`/`custom`), a `PaymentFilter` (`all`/`cash`/`credit`), a text `search`, and a `SalesSort`. `SalesFilter.initial()` defaults to **today**. Cash-vs-credit is *derived* per invoice (an invoice is credit iff it has a `charge` ledger entry) — `SalesDao.watchAuditInvoices` returns `AuditInvoiceRow`s (with `isCredit`, `customerName`, `itemCount`) and `watchAuditSummary` returns an `AuditSummaryRow` (count/total/creditTotal).
- **Live + paginated**: the list and the summary aggregate are each backed by a `StreamSubscription` that feeds **internal** events (`_InvoicesUpdated`/`_SummaryUpdated`) — you can't `emit` outside a handler. Changing the filter, or paging in more rows (`LoadMoreEvent`, `_kPageSize = 30`), cancels and re-subscribes with the new query/window. Both re-emit automatically after every sale.
- Line items for the detail page (`/history/detail/:id` → `InvoiceDetailPage`) are **lazy-loaded and cached** (`LoadInvoiceDetailsEvent`); a load failure is recorded (not cached) so the UI can retry. `ReprintInvoiceEvent` reprints a stored invoice via the same `PrinterRepository.printReceipt` the checkout uses.

**Android manifest**: the app gained `INTERNET` (release builds don't inherit the debug manifest's auto-added copy — required for the license API) and an `https` `VIEW` `<queries>` intent (so `url_launcher.canLaunchUrl` resolves WhatsApp/Telegram links on Android 11+).

**Android release build**: `flutter_vibrate` (discontinued) links its resources against an SDK older than API 31, breaking release resource linking (`android:attr/lStar not found`). `android/build.gradle.kts` has a `subprojects { afterEvaluate { … } }` block that bumps any stale subproject's `compileSdkVersion` to 34 — registered **before** the `evaluationDependsOn(":app")` block so the hook attaches while subprojects are still unevaluated (you can't `afterEvaluate` an already-evaluated project).

### Navigation (GoRouter)

Routing uses a `StatefulShellRoute.indexedStack` (`AppShell`) with five tab branches; `initialLocation` is `/pos`. `/scanner` is a top-level modal route outside the shell, but is **currently unused** — `HomePage` embeds its own inline live `MobileScanner` for continuous scanning rather than pushing `/scanner`.

`HomePage` also has a tap-to-add product picker (a bottom sheet, not a route) for items without a barcode. The picker reads the product list **live** from `ProductBloc` (via `context.watch`, not a one-time snapshot — so it isn't empty when opened before the first stream emission), and each tile gives add feedback (scale pop + green check flash + a live cart-count badge). Leaving checkout via Back preserves the cart (it is only cleared after a confirmed sale or "New Sale"); checkout exits with `context.pop()` so `HomePage`'s awaited `push('/pos/checkout')` resumes the camera.

- Branch 0: `/pos` → `HomePage` → `/pos/checkout` → `CheckoutPage`
- Branch 1: `/history` → `HistoryPage` → `/history/detail/:id` → `InvoiceDetailPage` (passes `InvoiceListItem` via `state.extra`)
- Branch 2: `/products` → `ProductListPage` → `/products/add`, `/products/edit/:id` (passes `Product` via `state.extra`)
- Branch 3: `/customers` → `CustomersPage` → `/customers/add`, `/customers/edit/:id` (passes `Customer` via `state.extra`), `/customers/detail/:id` (scopes `LedgerBloc`)
- Branch 4: `/settings` → `SettingsPage` → `/settings/shop` → `ShopDetailsPage`; `/settings/cashbox` → `CashboxPage` → `/settings/cashbox/history`; `/settings/subscription` → `SubscriptionStatusPage` → `/settings/subscription/plans`
- Top-level: `/scanner` → `ScannerPage`
- Top-level (licensing gate, outside the shell): `/splash` → `SplashPage`; `/activation` → `ActivationPage` → `/activation/plans` → `SubscriptionPlansPage`. A `redirect` on the shared `LicenseBloc` state holds unlicensed users here before any tab is reachable.

History and the product list are **stream-backed**: `ProductBloc`/`HistoryBloc` dispatch `LoadProducts`/`LoadHistoryEvent` once at startup, which subscribe (via `emit.forEach`) to `repository.watchProducts()`/`watchInvoices()`. After a sale, the stock decrement and new invoice flow back automatically — there is no manual reload after a confirmed sale (the old `refreshHistoryIfNeeded` helper was removed). Product mutation handlers (add/update/delete) emit only their transient success/error message; the list itself updates from the stream.

### Functional error handling

Repositories return `Either<Failure, T>` from fpdart. BLoCs call the repository, then `.fold(onLeft, onRight)` (or `result.match`), emitting an error state on `Left` and a success state on `Right`.

**No user-facing English in BLoCs.** A BLoC that hits a failure stores a *typed* error in its state — either the `Failure` subtype or a feature error enum (`BillingError`, `PrinterError`) — never a pre-rendered string. The page maps that type to a localized ARB string (`billingErrorText(...)`, `_printerErrorText(...)`). Add new error strings to the ARB files. (`PrinterRepository.connect`/`disconnect`/`printReceipt` still return plain `bool` — a connect/print is a boolean outcome, not an error channel; only `scanDevices` returns `Either` because it can fail on permission.)

Note: Product/Shop BLoC *success* messages (e.g. "Product added successfully") are still English — localizing those is a separate i18n pass, not part of the failure taxonomy.
