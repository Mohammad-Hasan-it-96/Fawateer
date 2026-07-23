# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Fawateer** (Arabic: فواتير, "invoices") is an offline-first POS app for small shops (package name: `billing_app`) with an online-validated **subscription gate** on top. It supports barcode scanning, Bluetooth thermal printing, product/inventory management, sales invoices with a filter/summary **audit center**, an **analytics dashboard**, a **customer debt ledger** (credit sales), a **cash drawer** (cashbox), **dual-currency** (SP base + USD pricing) with manual **discounts**, **Google Drive backup/restore**, and PNG **share cards**. The UI is **Arabic-first (RTL)** with English as a secondary locale; the shop is **Syria-first** (default currency `ل.س`).

Feature work is planned up-front in numbered design docs under `docs/plans/` (`001-backup-system.md` … `009-…`). Code comments reference these by number ("Plan 005"), so when a comment cites a plan, that file is the rationale of record. Plans 002 (multi-device) and 009 (smart assistant) are deferred to V2 — they describe work that does **not** exist in the codebase.

## Commands

```bash
# Run the app
flutter run

# Analyze for lint/type errors
flutter analyze

# Run tests
flutter test

# Run a single test file (test/ holds app_smoke_test, num_input_test,
# cashbox_test, dashboard_test, billing_scan_test, license_guards_test,
# subscription_plan_test, support_launcher_test, product_attributes_test,
# product_search_test)
flutter test test/num_input_test.dart

# Regenerate Drift database code (*.g.dart files)
dart run build_runner build --delete-conflicting-outputs

# Watch and regenerate on file changes
dart run build_runner watch --delete-conflicting-outputs
```

Run `build_runner` whenever you modify Drift table definitions (`lib/core/database/tables/`), DAO files (`lib/core/database/daos/`), or the `AppDatabase` class. Localization Dart code (`lib/l10n/app_localizations*.dart`) is generated from the ARB files automatically by `flutter run`/`flutter gen-l10n` because `generate: true` is set in `pubspec.yaml`.

**Tests drive BLoCs against hand-written fake repositories** — never real Drift, native SQLite, or plugins — so `flutter test` runs on any machine with no device/emulator. Keep it that way: a new test should implement the repository interface as a fake (see `_FakeDashboardRepository` in `dashboard_test.dart`), not spin up an `AppDatabase`. Pure logic (`num_input_test`, `cashbox_test`'s balance derivation) is tested directly with no BLoC at all.

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
- `lib/core/error/failure.dart` — `Failure` base class + typed subclasses: `CacheFailure` (DB/unexpected), `NotFoundFailure` (entity missing), `PermissionFailure` (OS permission denied), `DuplicateFailure` (unique-name clash, e.g. a second customer with the same name), `ConflictFailure` (delete blocked by existing history), `NetworkFailure` (offline/timeout), `ServerFailure` (server reached but errored) and `IncompatibleFailure` (backup snapshot rejected — schema too new / checksum mismatch). `Failure.message` is debug detail only — never shown to users.
- `lib/core/service_locator.dart` — All GetIt registrations
- `lib/core/theme/app_theme.dart` — `AppTheme.lightTheme`
- `lib/core/currency/` — `ExchangeRateService` + `usdToSp` (see Dual currency below)
- `lib/core/share/` — widget→PNG capture, `ShareService`, and the shareable cards (see Share cards below)
- `lib/core/config/` — `RemoteConfigService` (see Licensing below)
- `lib/config/routes/app_routes.dart` — GoRouter config; `app_shell.dart` — bottom-nav tab shell

`lib/core/data/` is an empty leftover directory — nothing lives there; don't infer a layer from it.

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

`main.dart` provides app-wide BLoCs through a `MultiBlocProvider` and dispatches initial load events (`CheckLicenseEvent`, `LoadProducts`, `LoadShopEvent`, `LoadExchangeRateEvent` (on `BillingBloc`), `InitPrinterEvent`, `LoadHistoryEvent`, `LoadCustomers`, `LoadCashbox`). `LicenseBloc` is a `.value` provider (the shared singleton).

**Three BLoCs are deliberately *not* app-wide** — they're route-scoped, and each starts differently, so copy the right precedent:
- `LedgerBloc` — scoped to `/customers/detail/:id` (per-customer).
- `DashboardBloc` — scoped to `/history`; its initial `LoadDashboard()` is dispatched **in the route's `create:`**.
- `BackupBloc` — scoped to `/settings/backup`; the route dispatches **nothing**. `BackupPage.initState` fires `BackupStatusRequested()`. Reading only `app_routes.dart` makes it look like nothing loads.

### Database

Drift (SQLite) backed by `driftDatabase(name: 'fawateer')`. All tables and DAOs are declared in the `@DriftDatabase(...)` annotation on `AppDatabase`. Generated code lives in `*.g.dart` files — **never edit these manually**.

There's also a generic `AppSettings` key-value table (`SettingRow`, `key`/`value` PK) for small app-level prefs that don't warrant their own typed table — `printer_mac`, `printer_name`, the USD exchange rate (`exchange_rate_usd_sp` + `exchange_rate_updated_at`), and backup state (`backup_last_at`, `backup_account_email`). **Reach for this before adding a table**: several features ship with no migration at all because their state is a couple of key-value rows.

Note the DAO list is one longer than the table list: `DashboardDao` is a read-only `@DriftAccessor` over existing tables and owns none of its own.

Schema is at **version 13** with a `MigrationStrategy`. When changing tables, bump `schemaVersion` and **append** a new `if (from < N)` block to `onUpgrade` — never edit a shipped block (old installs have already run it). Existing steps:
- v1→v2: added `shopSettings.currencySymbol`
- v2→v3: dropped removed `customers`/`debts`/`purchase_invoices`/`purchase_items`/`cashbox_entries` tables
- v3→v4: added `cost` column to `products` and `salesItems`; created barcode/sales indexes
- v4→v5: replaced `products.stock` (int) with `quantity` (double, supports weight/fractions) and added `minStockAlert` (double); copies old `stock` values into `quantity`
- v5→v6: `salesItems.quantity` int→double (matches `products.quantity` for weight/fractional sales). SQLite can't change a column type in place, so this rebuilds the table via `migrator.alterTable(TableMigration(salesItems))` then re-runs `_createIndexes()` (the rebuild drops the table's indexes).
- v6→v7: debt ledger — created `customers` + `ledger_entries` tables and `_createLedgerIndexes()`. **Purely additive**: no existing table is touched. The sale↔customer link deliberately lives on `ledger_entries.invoiceId` (a credit sale writes a `charge` entry referencing the invoice) rather than a column on `sales_invoices` — this avoids the landmine that the old `customer_id` column is still physically present (orphaned) in pre-removal DBs, which would make `addColumn` throw "duplicate column".
- v7→v8: added `products.saleType` (text, default `'piece'`) for sell-by-weight. Additive `addColumn`; every existing product decodes as `piece`.
- v8→v9: cashbox — created the `cashbox_transactions` table and `_createCashboxIndexes()`. **Purely additive**: no existing table is touched. Uses the name `cashbox_transactions` deliberately (not `cashbox_entries`, which was a *different* removed pre-v3 table already dropped in the v2→v3 step) so there's no collision.
- v9→v10: dual currency — added `products.priceCurrency`, and `salesItems.priceCurrency`/`fxRate`/`priceOriginal` (the per-line FX snapshot). All `addColumn` with defaults, so existing rows decode as SP-native.
- v10→v11: **data fix, no DDL** — the old default `shop_settings.currencySymbol` was `'₹'` (Indian rupee), wrong for this Syria-first app. Normalizes `'₹'` *and* blank to `'ل.س'`; a shop that deliberately chose another symbol keeps it.
- v11→v12: manual discounts (Plan 005) — added `salesItems.discount` and `salesInvoices.invoiceDiscount`. Additive; every existing row decodes as "no discount".
- v12→v13: dynamic product attributes (Plan 010) — added `products.attributes` (JSON bag of owner-defined custom-field values) and `salesItems.attributesSnapshot` (the `{label:value}` snapshot of `showOnReceipt` fields, frozen at sale time and replayed on reprint), and created the new `attribute_definitions` table. **Purely additive** (`addColumn` × 2 + `createTable`); every existing row decodes as empty. No table rebuild.

The v5→v6 `TableMigration` remains the **only** table rebuild in the whole history — everything since has been `addColumn` + one data-normalizing `UPDATE`. Keep it that way when you can.

**Foreign keys** are enforced per-connection via `PRAGMA foreign_keys = ON` in `MigrationStrategy.beforeOpen` (runs after migrations — table rebuilds need FKs off). No FK constraints are declared on the tables yet, so it's currently a no-op guard; any FK a future feature adds (e.g. `references(...)`) will actually be enforced. Don't set this pragma inside `onUpgrade`.

Indexes are built by three idempotent (`CREATE [UNIQUE] INDEX IF NOT EXISTS`) helpers, each called from `onCreate` and from the migration step that first needs it: `_createIndexes()` (POS — partial-unique `idx_products_barcode` `WHERE barcode != ''` so barcode-less items are allowed but non-empty barcodes stay unique, plus `idx_sales_invoices_created_at`, `idx_sales_items_invoice_id`, `idx_sales_items_product_id`), `_createLedgerIndexes()` (`idx_ledger_customer_id`, `idx_ledger_invoice_id`), and `_createCashboxIndexes()` (`idx_cashbox_occurred_at`, `idx_cashbox_related_id`). Index/table names use Drift's snake_case. Note: before creating the partial-unique barcode index, `_createIndexes()` first de-dups (blanks the barcode on all-but-the-earliest row per non-empty barcode) — otherwise the index would throw mid-migration and brick the DB on a legacy v1–v3 install that holds two products with the same barcode.

The `products` table carries a `cost` column (purchase cost, default 0) used for profit-margin reporting; `salesItems` snapshots it at sale time (alongside `productName`/`price`) so historical cost is preserved even if the product is later edited or deleted. Inventory is tracked by `quantity` (double, on-hand) with a `minStockAlert` threshold (`Product.isLowStock` = `minStockAlert > 0 && quantity <= minStockAlert`); the sale flow deducts `quantity` on confirm. The old physical `stock` column is left orphaned by the v4→v5 migration (has `DEFAULT 0`, ignored by Drift) — same approach used when `upiId` was removed; `addColumn`-only migrations avoid table rebuilds.

**Stock is optional, and overselling is allowed by default.** Many shops sell loose/produce items they never count, so the deduction (`SalesDao.insertInvoiceWithItems`) does `UPDATE products SET quantity = MAX(quantity - ?, 0)` — it *floors at 0, never rejects a sale*. Don't "fix" that into a blocking guard. Selling below zero is instead gated by an **opt-in** setting: `InventorySettingsService` (`core/settings/`, `AppSettings` key `inventory_block_oversell`, default off). When on, `BillingBloc._onConfirmSale` refuses a cart that sells any line past its on-hand count (`BillingError.insufficientStock`). The block list is `BillingState.oversoldItems` (`qty > onHand` for **every** product, sold-out items at on-hand 0 included) — deliberately **not** `lowStockWarnings`, whose softer "tracked" predicate (`quantity > 0 || minStockAlert > 0`) skips loose items and so silently let sold-out items through in the first cut. Strict mode means "enforce stock for everything"; a shop with genuinely untracked loose items should leave the toggle off (its default). The flag rides in `BillingState.blockOversell`, loaded by `LoadInventorySettingsEvent` at startup and on toggle (Settings → Inventory); `checkout_page` shows a red block strip (listing `oversoldItems`) and disables Confirm via `state.isStockBlocked`, falling back to the amber `lowStockWarnings` heads-up when not blocking. That deduction is written with `customUpdate(..., updates: {products})`, **never `customStatement`** — the raw form writes the row but tells Drift nothing changed, so `watchAllProducts` never re-runs and every screen keeps showing pre-sale stock until restart (this is why `Products` is in `SalesDao`'s `@DriftAccessor` list — so the update can name it). `ClearCartEvent` preserves the session-loaded `exchangeRate`/`blockOversell` rather than emitting a bare `const BillingState()`, which would drop them for the rest of the session. The `sales_invoices.customerId`/`customerName` columns were likewise removed from the table class (and the `Invoice` entity) but stay physically present in existing DBs, ignored by Drift — no migration or `schemaVersion` bump needed, since dropping a column requires no DDL. `SalesDao.deleteInvoice` deletes an invoice and its `sales_items` rows in one transaction (no orphans).

### Sale types (piece vs sell-by-weight)

`Product.saleType` is a `ProductSaleType` enum (`product_sale_type.dart`): `piece` (default) or `weight`, with `isMeasured`/`fromName` helpers and room to grow (volume/length/box) with **no migration** — it's persisted **by name string** in `products.saleType`, never by index, so reordering enum cases can't remap rows. `price` doubles as the **per-kg price** for weighed products.

- A weighed product is entered via `_MeasuredEntryDialog` (in `home_page.dart`): weight (kg) and money amount shown together and **live-linked** (typing one recomputes the other at the per-kg price; only the non-focused controller is written, so no feedback loop). It returns a **weight** which becomes the cart line's `quantity`.
- **Exact-money precision**: the weight is stored at full `double` precision (only `formatQty`-rounded for *display*), so `price × quantity` reconstructs the entered amount exactly (`5000` → `5000.00`). Consequence: **no stored line-total column** — history/receipts derive the total from the per-line `price` + `quantity` snapshots.
- Wiring: the picker and cart-edit call the dialog directly; a **scanned** weighed product surfaces via the transient `BillingState.measuredPrompt` (the BLoC never opens UI). `AddProductToCartEvent` has an optional `quantity` — when set it's an absolute add-or-replace (measured), when null it's the piece +1 behavior. `ReceiptLine.unit` (`'كغ'`) makes the raster receipt print `0.333 كغ × …`.

### Dual currency (SP base + USD pricing)

**SP (Syrian pound) is the one book currency.** Everything written to invoices, the cashbox, the ledger and reports is SP. USD is only a *pricing label* on a product — it's converted to SP at the moment of sale, and only the resolved SP number ever reaches the books. There is no multi-currency accounting here, and adding one would be a much larger change than it looks.

- `Product.priceCurrency` is a `PriceCurrency` enum (`price_currency.dart`, `sp`/`usd`) persisted **by name** (`fromName` falls back to `sp` for unknown/legacy values) — same rule as `ProductSaleType`/`CashTransactionType`. `PriceCurrency.label` renders USD with a literal `$`, never the shop's configured symbol.
- **The rate is not a table** — `ExchangeRateService` (`core/currency/`) keeps SP-per-USD in two `AppSettings` rows (`exchange_rate_usd_sp`, `exchange_rate_updated_at`, the latter feeding a stale-rate nudge). It parses defensively: non-finite or `<= 0` reads as *unset*.
- `usdToSp(amount, rate)` **rounds to a whole pound** at the conversion boundary (piastres are dead) and returns `null` when the rate is missing/invalid — so callers must guard rather than silently price a USD item at its raw number. `CartItem.isUnpriced` (`isForeign && fxRate <= 0`) is that guard, and it blocks checkout.
- **Never use a raw `product.price` downstream** — read the resolved `unitPriceSp` / `salesItems.price`.
- **Historical invoices are immune to later rate edits**: `salesItems` snapshots `priceCurrency` + `fxRate` (0 for SP-native lines) + `priceOriginal` at sale time and never recomputes, so an old receipt still reprints as `$10 × 15000 = 150,000 ل.س`. The live rate is read only when pricing a *new* sale.

### Discounts (manual, line + whole-cart)

Plan 005. Two additive columns (v11→v12): `salesItems.discount` (per line) and `salesInvoices.invoiceDiscount` (whole cart).

- **Both are stored as resolved SP amounts.** The percent-vs-amount choice (`_Mode` in `discount_dialog.dart`) is a *UI* affordance only — it's resolved to a flat SP number before it reaches domain or DB code. There is **no `isPercentage` flag stored**, so "this was 10% off" is not reconstructable from the data; don't build a report that assumes it is.
- **Cart discount stacks on top of line discounts**: `subtotal = Σ CartItem.total` (already line-discounted), then `totalAmount = subtotal − effectiveInvoiceDiscount` — it is not computed against the raw pre-line-discount subtotal.
- **Clamping is deliberately redundant in three places** — `showDiscountDialog._resolved` (to `base`), `CartItem.effectiveDiscount` (to `[0, gross]`), and `BillingState.effectiveInvoiceDiscount` (to `[0, subtotal]`). This is load-bearing, not duplication: discounts aren't re-validated when quantity changes, so `effectiveDiscount` re-clamps against the shrunk `gross` on every read and a shrunk line can't go negative. Don't "simplify" it to one clamp.
- The **no-stored-line-total** rule still holds: `gross = unitPriceSp × quantity` and `CartItem.total = gross − effectiveDiscount` are always derived. The *discount amount* is snapshotted (like `price`/`cost`/`fxRate`), and the pre-existing `sales_invoices.totalAmount` is stored **already net of both discounts** — but per-line net totals are still reconstructed from `price × quantity − discount`.

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
| dashboard | `DashboardBloc` | Analytics/KPIs (see below). Route-scoped to `/history`; reads `DashboardDao` (no tables of its own). |
| backup | `BackupBloc` | Google Drive backup/restore of the whole SQLite file (see below). Route-scoped to `/settings/backup`. |
| attributes | `AttributeDefinitionBloc` | Owner-defined **dynamic product fields** (Plan 010, bucket A). App-wide, stream-backed; loaded at startup. Definitions live in `attribute_definitions` (via `AttributesDao`); per-product values are a JSON map in `products.attributes` (the `ProductAttributes` value object in `core/attributes/`, kept as `Map<String,String>`). Managed at Settings → **Product fields** (`/settings/product-fields`); dynamic form renders in add/edit product; `showInList` fields show as a product-list subtitle. Curated seed **templates** in `data/business_templates.dart` (const map, not a table). **Deliberately not attributes:** IMEI/Serial (per-unit, bucket C) and Size×Color variants (bucket B) — separate future plans. **Receipt printing (V1.1, shipped):** `BillingBloc` subscribes to the definitions stream (`_receiptDefs`, kept fresh) and snapshots the resolved `{label:value}` pairs (unit baked in) of `showOnReceipt` fields onto `salesItems.attributesSnapshot` **in the sale transaction**; `ReceiptImage` renders them as small RTL sub-lines under each item, and `HistoryBloc` reprints from the frozen snapshot (immune to later product/definition edits — same rule as `price`/`fxRate`). Because of that subscription, `BillingBloc` now depends on `AttributeDefinitionRepository` and overrides `close()`. **Search/filter (V1.2, shipped):** the product-list free-text search also matches **any attribute value** (search-by-IMEI/color), and a filter sheet exposes `select` fields as option chips (AND across fields, OR within one). It's Dart-side over the in-memory product list (no index table — deliberately dropped for simple shops); the predicate is the pure `productMatchesSearch` in `features/product/domain/product_search.dart`. No `isSearchable` flag — every field is searchable, every choice-list field filterable. **Report group-by (V1.3, shipped):** a "Sales by field" section on the Reports dashboard groups sales by a chosen custom field's values via `DashboardDao.salesByAttribute` — `json_extract(p.attributes, ?)` in SQL (JSON path is a **bound parameter**, `ORDER BY` is the whitelisted metric column), joined live to `products` (uses the product's *current* value; `json_valid`-guarded; no-value rows bucket under `'—'`). Reuses `TopProduct`/`TopProductsChart`; needs SQLite JSON1 (bundled). **Product labels/QR (V1.4, shipped):** a print action per product-list row → dialog (copies + Barcode/QR toggle) → thermal label (name, price, Code128 or QR of the barcode) via `LabelImage` (`core/utils/`, uses the pure-Dart `barcode` package and the shared `ReceiptImage.imageToRaster` ESC/POS pipeline), `PrinterRepository.printLabel`, and a `ProductBloc.PrintProductLabel` event (so `ProductBloc` now also depends on `PrinterRepository`). Bucket A is **feature-complete**; only serialized-units (C) and variants (B) remain as separate plans. |

### Licensing & networking (subscription gate)

The app's **first and only server communication**, added for commercial subscriptions. Operator-driven activation, modeled on the Smart-Agent app.

- **`core/network/`** — the app's networking primitive: `ApiClient` (JSON over `http`, timeouts, error→`ApiException` mapping) + `ApiConfig` (base URL, `appName`, operator contacts, device-id salt). Currently points at the **Smart-Agent backend** (`create_device`/`check_device`/`getPlans`/`update_my_data`), keyed by `appName: 'Fawateer'`, until Fawateer's own server ships. `ApiConfig.baseUrl` and the support contacts are **runtime-mutable** (not `const`) — `ApiClient` reads `baseUrl` per-request, so the remote config (below) can repoint the server without a rebuild; `defaultBaseUrl` is the baked-in fallback. Two `Failure` subtypes back this: `NetworkFailure` (offline/timeout) and `ServerFailure` (reached but errored).
- **`core/config/` remote config** — `RemoteConfigService` fetches a hosted `fawateer_version.json` at startup (time-boxed, → SharedPreferences cache → baked-in defaults; `main.dart` awaits it briefly before the first license call). It overwrites `ApiConfig.baseUrl` + support contacts, and drives an **in-app update prompt**: compares `latest_version` to `package_info_plus`'s installed version and, if newer, `_UpdateChecker` (wrapping `MaterialApp.router`) shows a one-time dialog with a Download button opening the ABI-matched APK URL (`device_info_plus` `supportedAbis`). The dialog itself lives in `core/config/update_dialog.dart` (`showUpdateDialog`), shared with the **manual check**: tapping the app-version row in Settings calls `RemoteConfigService.refresh()` (returns `bool` — config resolved or not) and shows the same dialog, an "up to date" snackbar, or a "check failed" snackbar. **Two landmines, both shipped broken in 1.0.0 and verified on-device** (`test/update_prompt_test.dart` pins them): (1) `_UpdateChecker` sits in `MaterialApp.builder`, whose context is *above* the router's Navigator — `showDialog` from it throws "no Navigator ancestor" silently inside a post-frame future, so the prompt must go through `rootNavigatorKey.currentContext` (the key is on the GoRouter); (2) the prompt must wait for `LicenseBloc.state.bootstrapped` (+600ms) before showing — earlier it attaches to the splash page, and the gate's redirect swap disposes the dialog with the page ~2s later. This exists because the automatic prompt runs once per process at cold start only — Android keeps the app alive for days, so a shop that never swipe-kills it wouldn't see a new release otherwise. If the startup fetch never reaches the network (opened offline), `_UpdateChecker` retries quietly (1-min timer + on app resume) until one network fetch succeeds (`RemoteConfigService.networkResolved`), then prompts; startup itself is never blocked (the awaited load in `main()` stays capped at 4s). Registered in `service_locator.dart`.
- **Device identity** (`DeviceIdentityService`) = `SHA-256(rawId + ApiConfig.deviceIdSalt)`, where `rawId` is `ANDROID_ID` on Android (`android_id`) and `identifierForVendor` on iOS (`device_info_plus`); both are hashed with the salt so the two platforms emit interchangeable opaque tokens. Other platforms — or a null/empty native id (e.g. iOS `identifierForVendor` before first unlock) — fall back to the constant `'fallback_device_id'`; it never throws. No permissions. Surfaced in the UI via `DeviceIdCard` (copy-to-clipboard) on both the activation and subscription screens, so the user can send it to support for operator-driven activation. It's loaded into `LicenseState.deviceId` during the startup `CheckLicenseEvent`.
- **License model** = the server returns an `expiresAt`; `LicenseLocalStorage` caches it (+ last-sync + trusted-server-time) in `SharedPreferences`. The whole app gates on `LicenseStatus.isActive` (verified & not expired & not guard-blocked). Offline it runs on the cache within a **30-day grace** window; `LicenseGuards` (pure, testable) enforces that grace and a **48-hour clock-rollback** tamper check. Both thresholds were deliberately widened (from 72 h / 5 min) to avoid locking shops out after mundane events (multi-day outages, flat batteries, timezone corrections) that were triggering false positives.
- **Operator flow**: `activate()` calls `create_device`; if unverified, the user picks a plan (`getPlans`) and files a `status:'pending'` request (`requestPlan`), then is handed to WhatsApp/Telegram (`url_launcher`). A human activates the device server-side; the app then unlocks **live** via FCM (below), falling back to a re-check on next launch.
- **FCM live-unlock**: `PushNotificationService` (`features/licensing/data/services/`) wires Firebase Cloud Messaging so an operator-side activation unlocks the app instantly — a data message with `data.type` ∈ {`new_plan_activated`, `subscription_activated`, `license_updated`} invokes `onLicenseChanged`, which `main.dart` wires to `LicenseBloc.add(CheckLicenseEvent())` (the shared singleton the gate reads), so the gate flips to active with no restart. If the push lands while the app is in the **foreground**, a second callback (`onForegroundLicenseChange`) also fires a visible in-app banner (`subscriptionActivatedBanner` SnackBar via a top-level `rootMessengerKey`); background/terminated deliveries surface as an OS tray notification instead, so they don't double up. The FCM token is registered with the server (`activate()` attaches the cached token to `create_device`; `LicenseRepository.registerPushToken` re-syncs it on **every startup** and on token rotation via `update_my_data`). Two-key token cache in `LicenseLocalStorage`: `lic_push_token` is the device's current token (written *before* any network call, so activation can attach it), `last_sent_fcm_token` is the last token the server confirmed with a 2xx (written only *after* a successful send — the skip-if-unchanged check reads this one, so a failed send retries next launch instead of being wrongly skipped; stale server tokens are what caused FCM "NotRegistered"). **Foreground display**: notification-type FCM messages only auto-display in the background; `PushNotificationService` renders them in the foreground via `flutter_local_notifications` (channel `fawateer_general`, created explicitly — Android 8+ drops posts to nonexistent channels; requires core-library desugaring, enabled in `android/app/build.gradle.kts`). Data-only messages (the license unlock) have no `notification` payload and skip this path. **It's dormant by default and self-disabling**: with no Firebase project configured, `Firebase.initializeApp()` fails gracefully and push stays off — the app builds/runs unchanged. Enabling it (google-services.json + two Gradle plugin lines, both stubbed as comments) and the exact server payload are documented in `android/README-fcm.md`. Deps: `firebase_core`, `firebase_messaging`. Manifest gained `POST_NOTIFICATIONS` (Android 13+ tray banner).
- **The gate** is a GoRouter `redirect` driven by the shared `LicenseBloc` state (via a `ChangeNotifier` bridged to `bloc.stream` as `refreshListenable`): before the first check resolves (`!state.bootstrapped`) → `/splash`, inactive → `/activation` (+ `/activation/plans`), active → the tab shell. Follows the typed-error rule — `LicenseError` maps to ARB via `licenseErrorText`. The gate keys off `bootstrapped` (set true once the first check resolves), **not** the transient `checking` status — so an in-app re-check (Refresh below) doesn't bounce the user to the splash. An expired-but-registered user is routed to the **plans** screen (re-subscribe), never back to the name/phone form, and `SubscriptionPlansPage` shows an expired notice (trial vs paid wording, `license.isExpired`/`isTrial`) reassuring that data is intact. **Mid-session expiry locks live**: `LicenseBloc` arms an expiry `Timer` (in `onChange` — off `change.nextState`, since `state` there still holds the previous state) that fires a `CheckLicenseEvent` just past `expiresAt` (capped at 24h, re-arming — which doubles as a daily re-check for never-restarted devices; works offline since the cached expiry locks locally). Without it, expiry only bit on the next navigation/restart because nothing re-evaluates the gate on pure time passage. Covered by `test/license_expiry_lock_test.dart` (`expiryCheckBuffer` is injectable for tests).
- **Management**: while active, Settings → "Subscription" opens `SubscriptionStatusPage` (`/settings/subscription`) showing status/plan/expiry/days-left/last-sync, with Refresh (`CheckLicenseEvent`) and Renew (`/settings/subscription/plans`, reusing `SubscriptionPlansPage`). It lives outside the gate routes, so it's only reachable while active — exactly when the activation screen isn't.
- **Editable account**: `SettingsPage` has an "Account details" section (reads the shared `LicenseBloc`) that edits the agent **name/phone** via a bottom sheet and shows a copyable device ID. `UpdateAgentEvent` → `LicenseRepository.updateAgent` **saves locally first** (never lost) then best-effort syncs (`update_my_data`); the one-shot `AgentSaveOutcome` (`synced`/`localOnly`) drives a green/orange snackbar.
- **Free trial (Plan 006) adds a display flag, not a state machine.** `LicenseStatus` gained one plain `final bool isTrial` (default `false`); `isActive` is still `isVerified && !isExpired && !timeTampered && !offlineLimitExceeded` — **`isTrial` is not a term in it**. There's no new `LicenseStatus` state and **no new endpoint**: the server sets `status:'trial'` + a trial expiry on the existing `create_device`, and `check_device` returns `is_trial` alongside `expires_at` exactly as for a paid device, so the gate, the 72h grace and the clock-tamper check treat trial and paid identically (`LicenseGuards` has zero trial branching — keep it that way). `isTrial` exists only for UI: `TrialBanner` (renders when `isTrial && isActive`, turns red in the last 3 days) and the status chip. Cached as `lic_is_trial` in `SharedPreferences`.
- **Trial anti-abuse is server-side only**, keyed on the device id (`ANDROID_ID`-derived, stable across reinstall — only a factory reset mints a new one). **Do not add a local first-launch date**: a client-tracked trial is trivially reset by clearing app data, and was explicitly rejected in `docs/plans/006-free-trial.md`.
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

### Analytics dashboard

Plan 008. Lives in `features/dashboard/`, but is **not a route or a tab** — it's the default sub-view *inside* the Reports tab: `HistoryPage` holds an internal `int _view` toggle (0 = `DashboardView`, 1 = the sales list). Searching `app_routes.dart` for a dashboard route finds nothing; it's reached only via `/history`.

- **`DashboardDao`** (`core/database/daos/dashboard_dao.dart`) is a read-only `@DriftAccessor` over six existing tables (`SalesInvoices`, `SalesItems`, `Products`, `CashboxTransactions`, `LedgerEntries`, `Customers`) — **zero new tables, zero migrations**. Every aggregate is computed **in SQL** (`periodTotals`, `topProducts`, `cashFlow`, `outstandingDebts`, `inventoryValue`, `lowStockProducts`, `topDebtors`, …), never by loading rows into Dart and summing. Keep that rule.
- **Live via a change-ticker, not per-field streams**: `watchChanges()` is `customSelect('SELECT 1', readsFrom: {…5 tables…}).watch()` — a trivial query that exists purely to re-emit when any of those tables mutate. `DashboardBloc` subscribes in its constructor and re-runs the **whole** `_load()` (10 aggregates via `Future.wait`) per tick. So any sale/cash/debt/stock write anywhere triggers a full reload — cheap-looking, but not free.
- **Profit SQL is duplicated by design** with `SalesDao.watchAuditSummary` (`(si.price - si.cost) * si.quantity - si.discount`). If you change the profit definition in one, change the other — the audit center and dashboard must agree.
- **`topProducts(orderByColumn:)` interpolates a column name into SQL.** That's safe *only* because `DashboardRepositoryDriftImpl._metricColumn` maps the `ProductMetric` enum onto three hardcoded strings. Never pass a user-controlled string down that path.
- **Day bucketing happens in Dart** (`_bucketByDay`, via `DateTime(y, m, d)`), not in SQL, deliberately — epoch-ms division gets UTC/local-day and DST boundaries wrong.
- **`DashboardData` mixes two kinds of metric**: *period* metrics honor the date-range filter (`revenue`, `profit`, `salesTrend`, `topProducts`, plus `*Prev` counterparts driving delta arrows), while *point-in-time* metrics (`cashBalance`, `outstandingDebts`, `inventoryValue`) are always all-time and **never move with the range picker**. Charts: `fl_chart` (pure Dart, offline, no native deps).

### Backup & restore (Google Drive)

Plan 001, in `features/backup/`, reached at Settings → `/settings/backup`. See `docs/google-drive-api-setup.md`.

- **It backs up the entire live SQLite file**, not a row/JSON export — `BackupEngine.createSnapshot` uses `VACUUM INTO ?`. Every table is captured with no per-feature serialization, but restore is **all-or-nothing**; you cannot restore a single table.
- **Auth is `drive.file` scope only** (`GoogleDriveBackupTarget`) — the narrow "app-created files only" scope, chosen specifically so Google requires no app verification / Play Console review. Widening the scope would trigger that review. Snapshots land in a normal user-visible Drive folder ("Fawateer Backups"), not hidden `appDataFolder`.
- **No client-side encryption** — the `.sqlite` goes up as-is (`application/x-sqlite3`), protected only by the user's Drive account. Don't assume customer data is encrypted at rest.
- **Restore has three independent guards** (`BackupRepositoryImpl.restore` + `BackupEngine.restoreSnapshot`), all load-bearing: (1) **downgrade guard** — refuses a snapshot whose `manifest.schemaVersion > schemaVersion`, since Drift migrations are forward-only and a newer schema in an older build corrupts silently; (2) **integrity guard** — SHA-256 checked against the manifest *before* the live DB is touched; (3) **rollback-safe swap** — the current DB is copied to `<path>.pre-restore` and copied back if the swap throws, and `-wal`/`-shm` sidecars are deleted first so a stale journal can't replay over the restored file. Both rejections are `IncompatibleFailure` (`schema_too_new` / `checksum_mismatch`).
- **A restore kills the app.** There's no in-Dart reinitialization of `AppDatabase`/`sl`; `BackupPage` shows a non-dismissible dialog whose only action calls `SystemNavigator.pop()`, and the user relaunches manually.
- `BackupExportRequested` bypasses Drive entirely — same `VACUUM INTO` snapshot handed to `share_plus`, for users who won't sign in to Google.
- No new table: `SettingsDao` holds `backup_last_at` / `backup_account_email`.
- **Auto-backup** (`AutoBackupService`, `features/backup/data/auto_backup_service.dart`): fires silently on launch/resume (foreground-triggered by design — no `WorkManager`, no background service), skips if the last backup is under 24 h old. Default ON once Drive is connected; opt-out stored in `AppSettings` as `backup_auto_enabled`. Failures are silent and leave the timestamp untouched so the next trigger retries. `BackupBloc` takes it as a constructor dependency; `BackupAutoToggled` event toggles it and immediately calls `maybeRun()` when turned on so the user doesn't wait a day for the first one.

### Share cards (PNG)

Plan 007. `core/share/` turns a Flutter widget into a shareable PNG — used for invoices, cashbox summaries and sales summaries (`core/share/cards/`, plain widgets never mounted in the visible tree).

- `captureWidgetToPng` (`widget_capture.dart`) mounts the card in an **off-screen `OverlayEntry`** (`left: -logicalWidth * 3`, so it never flashes), wrapped in a `RepaintBoundary`, inside the app's **real `Overlay`** — that's deliberate: it inherits `Directionality`/`Localizations`/`Theme`, which is what makes Arabic/RTL render correctly. It waits two `endOfFrame`s (layout + paint) before `toImage(pixelRatio: 3.0)`. No screenshot package is involved.
- **This is not the same technique as the ESC/POS receipts** and the two don't generalize to each other. `ReceiptImage.buildTextEscPosBytes` paints via low-level `dart:ui` `Canvas`/`ParagraphBuilder` into monochrome 384px raster bytes for a thermal printer; share cards capture an arbitrary full-color Material widget into a PNG for the OS share sheet. They share only the underlying reason — Flutter's text engine shapes Arabic, so both ship pixels rather than text bytes.
- `ShareService` is the single transport (PNG → temp file via `path_provider` → `Share.shareXFiles`), so WhatsApp/Telegram/email/Drive all come free with no per-channel code. `shareTextToWhatsApp` special-cases a `wa.me` deep link and falls back to the generic sheet.

**Android manifest**: the app gained `INTERNET` (release builds don't inherit the debug manifest's auto-added copy — required for the license API) and an `https` `VIEW` `<queries>` intent (so `url_launcher.canLaunchUrl` resolves WhatsApp/Telegram links on Android 11+).

**Android release build**: `flutter_vibrate` (discontinued) links its resources against an SDK older than API 31, breaking release resource linking (`android:attr/lStar not found`). `android/build.gradle.kts` has a `subprojects { afterEvaluate { … } }` block that bumps any stale subproject's `compileSdkVersion` to 34 — registered **before** the `evaluationDependsOn(":app")` block so the hook attaches while subprojects are still unevaluated (you can't `afterEvaluate` an already-evaluated project).

**Android release signing**: release builds are signed with an owned keystore whose secrets live in `android/key.properties` (gitignored, pointing at a keystore stored **outside** the repo). A release build without it **fails loudly by design** rather than silently falling back to the debug key — a debug-signed APK can't update a real install. **Losing the keystore is unrecoverable**: Android refuses updates signed with a different key. Setup and distribution (per-ABI APKs) are documented in `docs/android-release-signing.md` and `docs/android-release-distribution.md`.

### Navigation (GoRouter)

Routing uses a `StatefulShellRoute.indexedStack` (`AppShell`) with five tab branches; `initialLocation` is `/pos`. `/scanner` is a top-level modal route outside the shell. The **POS does not use it** — `HomePage` embeds its own inline live `MobileScanner` for continuous scanning — but the **product pages do**: `add_product_page.dart` and `product_list_page.dart` both `push<String>('/scanner')` to capture one barcode and pop it back. So it is on the shopkeeper's path every time they add a product by scanning, and its strings are user-visible.

`HomePage` also has a tap-to-add product picker (a bottom sheet, not a route) for items without a barcode. The picker reads the product list **live** from `ProductBloc` (via `context.watch`, not a one-time snapshot — so it isn't empty when opened before the first stream emission), and each tile gives add feedback (scale pop + green check flash + a live cart-count badge). Leaving checkout via Back preserves the cart (it is only cleared after a confirmed sale or "New Sale"); checkout exits with `context.pop()` so `HomePage`'s awaited `push('/pos/checkout')` resumes the camera.

- Branch 0: `/pos` → `HomePage` → `/pos/checkout` → `CheckoutPage`
- Branch 1: `/history` → `HistoryPage` → `/history/detail/:id` → `InvoiceDetailPage` (passes `InvoiceListItem` via `state.extra`). The tab is labelled **"Reports"** (`l10n.reportsTab`) and scopes `DashboardBloc`; `HistoryPage` toggles internally between the dashboard (default) and the sales list.
- Branch 2: `/products` → `ProductListPage` → `/products/add`, `/products/edit/:id` (passes `Product` via `state.extra`)
- Branch 3: `/customers` → `CustomersPage` → `/customers/add`, `/customers/edit/:id` (passes `Customer` via `state.extra`), `/customers/detail/:id` (scopes `LedgerBloc`)
- Branch 4: `/settings` → `SettingsPage` → `/settings/shop` → `ShopDetailsPage`; `/settings/cashbox` → `CashboxPage` → `/settings/cashbox/history`; `/settings/backup` → `BackupPage` (scopes `BackupBloc`); `/settings/subscription` → `SubscriptionStatusPage` → `/settings/subscription/plans`
- Top-level: `/scanner` → `ScannerPage`
- Top-level (licensing gate, outside the shell): `/splash` → `SplashPage`; `/activation` → `ActivationPage` → `/activation/plans` → `SubscriptionPlansPage`. A `redirect` on the shared `LicenseBloc` state holds unlicensed users here before any tab is reachable.

History and the product list are **stream-backed**: `ProductBloc`/`HistoryBloc` dispatch `LoadProducts`/`LoadHistoryEvent` once at startup, which subscribe (via `emit.forEach`) to `repository.watchProducts()`/`watchInvoices()`. After a sale, the stock decrement and new invoice flow back automatically — there is no manual reload after a confirmed sale (the old `refreshHistoryIfNeeded` helper was removed). Product mutation handlers (add/update/delete) emit only their transient success/error message; the list itself updates from the stream.

### Functional error handling

Repositories return `Either<Failure, T>` from fpdart. BLoCs call the repository, then `.fold(onLeft, onRight)` (or `result.match`), emitting an error state on `Left` and a success state on `Right`.

**No user-facing English in BLoCs.** A BLoC that hits a failure stores a *typed* error in its state — either the `Failure` subtype or a feature error enum (`BillingError`, `PrinterError`) — never a pre-rendered string. The page maps that type to a localized ARB string (`billingErrorText(...)`, `_printerErrorText(...)`). Add new error strings to the ARB files. (`PrinterRepository.connect`/`disconnect`/`printReceipt` still return plain `bool` — a connect/print is a boolean outcome, not an error channel; only `scanDevices` returns `Either` because it can fail on permission.)

Note: Product/Shop BLoC *success* messages (e.g. "Product added successfully") are still English — localizing those is a separate i18n pass, not part of the failure taxonomy.
