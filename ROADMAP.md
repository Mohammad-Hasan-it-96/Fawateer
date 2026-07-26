# Fawateer — Commercialization Roadmap & Progress

Turning **Fawateer** from a plain offline POS into a commercial product with
**online-validated subscriptions** and a **customer debt ledger**.

**Branch:** `refactor/architecture-hardening`
**App version:** `1.0.1+1` · **Drift schema:** **v14**
**Last updated:** 2026-07-26 (Plan 011 field fixes waves A–D, saleType snapshot v13→v14, scanner overhaul, Android back-button fix)

> **Where the project stands:** the feature backlog is **empty of anything
> committed-to**. Nine of the eleven numbered plans are shipped; the two that
> aren't (002 multi-device, 009 smart assistant) were **deliberately deferred to
> V2**, and 004 was **rejected outright**. Nothing is half-built.
>
> **What stands between here and selling is not a feature — it's verification.**
> See [Before shipping](#before-shipping--verification-debt). Almost nothing has
> been exercised on real hardware, and the highest-blast-radius code in the app
> (backup **restore**, which swaps the live DB) has never run on a device.

---

## Locked decisions

- **Activation = operator-driven.** The app files a `status:'pending'` request,
  hands the user to WhatsApp/Telegram, and a human activates the device
  server-side (no in-app automated payments).
- **Backend = reuse Smart-Agent's server** for now
  (`app_name: 'Fawateer'`, base URL `harrypotter.foodsalebot.com/api`) until
  Fawateer's own server ships — then just change `ApiConfig.defaultBaseUrl`.
- **Money stays `double`** app-wide (no integer-minor-unit migration); rounded
  at display / at ledger write time.
- **Build order:** licensing first, ledger second. *(Both done.)*

### Locked since — conventions every plan has followed

These emerged during the build and are now load-bearing across features. Breaking
one is a cross-cutting change, not a local one.

- **Snapshot at sale time; history is immutable.** `sales_items` freezes
  `price`, `cost`, `fxRate`, `priceOriginal`, `discount`, `attributesSnapshot`
  and `saleType`. A reprint of a 6-month-old invoice must be byte-identical to
  the original. Plan 004 exists to defend this.
- **Persist enums by *name*, never by index** (`ProductSaleType`,
  `PriceCurrency`, `CashTransactionType`, ledger entry types, `AppFontScale`) —
  so reordering enum cases can't remap existing rows.
- **Migrations are additive.** Append a new `if (from < N)` block; never edit a
  shipped one. The v5→v6 `TableMigration` is still the **only** table rebuild in
  the entire history.
- **Reach for the `AppSettings` KV table before adding a table.** Several
  features ship with no migration at all because their state is two key-value rows.
- **Aggregates are computed in SQL**, not by loading rows into Dart and summing.
- **No user-facing English in BLoCs** — store a typed error, let the page map it
  to ARB.
- **Tests use hand-written fakes**, never real Drift/plugins; `integration_test/`
  is the narrow exception for when the native engine *is* what's under test.

### Reference projects
- Licensing/server arch → `D:\work\Flutter\Smart-Agent` (`smart_agent`).
- Debt ledger → `D:\work\Flutter\AccountingBook\accounting_book`.

---

## Progress at a glance

| Phase | Feature | Status |
|-------|---------|--------|
| 0–1 | Networking core + licensing gate | ✅ Done |
| 1 | Account statement — share | ✅ Done |
| 1 | License management screen | ✅ Done |
| 1 | Device-ID display | ✅ Done |
| 2 | Debt ledger (customers + credit sales) | ✅ Done |
| 2 | Ledger bottom-nav tab | ✅ Done |
| 2 | Account statement — thermal print | ✅ Done |
| 3 | FCM live-unlock | ✅ Done (dormant until Firebase configured) |
| 3 | iOS device-id | ✅ Done |
| 3 | Foreground push banner | ✅ Done |
| 3.5 | Remote config (base URL + support) + in-app update check | ✅ Done |
| 3.5 | Runtime API base URL + splash-freeze fix | ✅ Done |
| 3.5 | Editable account (name/phone) in Settings | ✅ Done |
| POS | Product picker — live list + tap-add feedback | ✅ Done |
| POS | Sell by weight / sale type (schema **v8**) | ✅ Done |
| POS | Sales **audit center** (filter / summary / pagination) | ✅ Done |
| Cash | **Cashbox** / cash drawer (schema **v9**) | ✅ Done |
| Ledger | Customer duplicate-name guard | ✅ Done |
| Build | Android release-build fix (`flutter_vibrate` lStar) | ✅ Done |
| Build | Release signing with an owned keystore + per-ABI APKs | ✅ Done |
| Brand | Ribbon-ف adaptive launcher icon, Cairo font bundled offline | ✅ Done |
| POS | Strict inventory mode (opt-in block-oversell) | ✅ Done |
| 4+ | Purchases / suppliers / expenses / multi-store | ⬜ Future |

### Numbered plans (`docs/plans/`)

The design docs are the rationale of record — code comments cite them by number.
Each plan's own header carries its as-built detail.

| Plan | Feature | Status |
|---|---|---|
| **001** | Cloud backup & restore (Google Drive) | ✅ Shipped — `drive.file` scope, `VACUUM INTO`, auto-backup |
| **002** | Multi-device sync | ⏸️ **Deferred to V2** — no code. The hardest item in the roadmap |
| **003** | Dual currency (SP base + USD sticker) | ✅ Shipped — schema **v10** |
| **004** | Historical price recalculation | ❌ **Rejected permanently.** Not a backlog item — history is immutable |
| **005** | Promotions / discounts | ✅ V1 shipped — schema **v12**. Rules engine + standing sale price deferred |
| **006** | Free trial | ✅ Shipped — one display flag, no new state, no migration |
| **007** | WhatsApp integration & sharing (PNG cards) | ✅ Shipped — `core/share/`. PDF deferred |
| **008** | Analytics dashboard | ✅ Lean V1 shipped — zero new tables. V1.5 list deferred |
| **009** | Smart assistant & intelligent alerts | ⏸️ **Deferred to V2** — no code. 008 already ships the passive version |
| **010** | Dynamic product attributes | ✅ Bucket A **feature-complete** (V1→V1.4), schema **v13**. Buckets B/C are separate plans |
| **011** | V1 field-feedback fixes (11 items) | ✅ **All 11 shipped** + 2 follow-ups, schema **v14** |

---

## Done — detail

### ✅ Phase 0+1 — Networking core + licensing gate
- `core/network/` (`ApiClient`, `ApiConfig`) — the app's first server comms.
- `features/licensing/` — device-id activation (`SHA-256(ANDROID_ID + salt)`),
  `create_device` / `check_device` / `getPlans`, `expires_at` caching in
  SharedPreferences, **72h offline grace** + **5-min clock-tamper** guards
  (pure `LicenseGuards`).
- GoRouter **gate**: unlicensed → `/activation`, active → tab shell, pre-boot →
  `/splash`. Keys off `LicenseState.bootstrapped` (not the transient `checking`).
- New failures: `NetworkFailure`, `ServerFailure`.
- Deps: http, crypto, android_id, shared_preferences, url_launcher.

### ✅ License management screen
- Settings → **Subscription** (`SubscriptionStatusPage`, `/settings/subscription`):
  status / plan / expiry / days-left / last-sync + **Refresh** + **Renew**.

### ✅ Device-ID display
- `DeviceIdCard` (copy-to-clipboard) on the activation + subscription screens;
  `LicenseState.deviceId` loaded at startup.

### ✅ Phase 2 — Debt ledger
- Drift **schema v7**: `customers` + `ledger_entries` (purely additive; the
  sale↔customer link lives on `ledger_entries.invoiceId`, dodging the orphaned
  `sales_invoices.customer_id` duplicate-column landmine).
- `features/ledger/` with `CustomerBloc` / `LedgerBloc`, customers CRUD,
  **single-entry signed ledger** (charge/payment), **derived balances**
  (`SUM(CASE …)`, never stored), money rounded to 2dp at write time.
- **Credit sale** wired into checkout (`_CreditAwareConfirm` →
  `ConfirmSaleEvent.customerId` → `saveInvoice(customerId:)` → charge entry in
  the **same transaction** as the invoice + stock deduction).
- **Delete-guard** (`ConflictFailure`) — can't delete a customer with history;
  `isArchived` soft-hide.

### ✅ Ledger bottom-nav tab
- `/customers` is the 4th shell branch (5 tabs: POS, History, Products,
  Customers, Settings).

### ✅ Account statement — share + thermal print
- `buildCustomerStatement` → one Arabic text statement, used by **both**:
  - **Share** (`share_plus`) — WhatsApp reminders.
  - **Print** — `ReceiptImage.buildTextEscPosBytes` renders it to a **raster
    bitmap** (Arabic must be pixels; the plain ESC/POS text path prints `?`).
- Also fixed a latent Phase-1 gap: added `INTERNET` + `https` VIEW query to the
  Android manifest (release builds couldn't reach the license server / open
  WhatsApp).

### ✅ Phase 3 — FCM live-unlock  *(now LIVE — see note)*

> **Update (2026-07-26):** no longer dormant. Firebase project `fawateer-4c9bc`
> is configured, `google-services.json` is in place and the google-services
> Gradle plugin line is committed (no longer stubbed). ⚠️ That JSON is
> **gitignored**, so a fresh clone will fail to build until it's restored.
- `PushNotificationService` (`features/licensing/data/services/`): a data
  message with `data.type` ∈ {`new_plan_activated`, `subscription_activated`,
  `license_updated`} → `onLicenseChanged` → `main.dart` wires it to
  `LicenseBloc.add(CheckLicenseEvent())` → the gate flips to active **with no
  restart**.
- Token: `activate()` attaches the cached token to `create_device`;
  `LicenseRepository.registerPushToken` → `update_my_data` on rotation.
- **Self-disabling**: with no Firebase project, `Firebase.initializeApp()` fails
  gracefully → push off, app builds/runs unchanged.
- Deps: `firebase_core ^4`, `firebase_messaging ^16`. google-services Gradle
  lines stubbed as comments; `POST_NOTIFICATIONS` added; `google-services.json`
  git-ignored.
- **Enable steps + server payload:** [`android/README-fcm.md`](android/README-fcm.md).

### ✅ iOS device-id
- `DeviceIdentityService` now hashes `identifierForVendor` (via `device_info_plus`)
  on iOS, salted identically to the Android `ANDROID_ID` path — the two platforms
  emit interchangeable opaque tokens. A null/empty native id (e.g. iOS before
  first unlock) still falls back to the constant; it never throws.

### ✅ Foreground push banner
- A license push received while the app is **open** now shows a visible in-app
  banner (`subscriptionActivatedBanner` SnackBar) in addition to the silent
  re-check. `PushNotificationService._handleMessage` tags foreground vs
  background deliveries; only foreground fires `onForegroundLicenseChange`,
  which `main.dart` routes through a top-level `rootMessengerKey`. Background /
  terminated deliveries already surface as an OS tray notification, so they
  don't double up. No new dependency (uses the built-in `ScaffoldMessenger`);
  stays dormant with the rest of FCM until Firebase is configured.

### ✅ Phase 3.5 — Remote config + in-app update check
- `core/config/` (`RemoteConfig`, `RemoteConfigService`): fetches a hosted
  `fawateer_version.json` at startup (Google-Drive `uc?export=download`, 10s
  time-boxed → SharedPreferences cache → baked-in defaults), and applies it.
- **Runtime API base URL + support contacts**: `ApiConfig.baseUrl` / WhatsApp /
  Telegram / email are now mutable and read per-request by `ApiClient`, so the
  server or contact channels can move **without shipping a build** — the config's
  `api.base_url` + `support` block overwrite them at boot. Baked-in default is
  still `harrypotter.foodsalebot.com/api`.
- **In-app update prompt**: compares the config's `latest_version` to the
  installed build (`package_info_plus`) and, if newer, shows a one-time Arabic
  dialog with `update_notes` + a **Download** button opening the ABI-matched APK
  URL (`device_info_plus` `supportedAbis`). Wrapped app-wide via `_UpdateChecker`
  so it fires regardless of the licensing-gate screen.
- Deps: `package_info_plus`. Note: Drive hosting is fragile — moving the JSON to
  the same server that serves the APKs is recommended.

### ✅ Phase 3.5 — Splash-freeze fix + gate hardening
- **Root-cause fix for the "checking subscription…" forever-freeze**: the only
  unbounded startup await — the `ANDROID_ID` / `identifierForVendor` platform
  channel — is now time-boxed (`DeviceIdentityService` 3s `.timeout()` → falls
  back to the constant id). Brand-new devices skip the network poll entirely
  and go straight to the activation form; `_onCheck` is wrapped so **nothing**
  can leave the splash spinning (always `bootstrapped: true`).
- **Gate rewrite**: fixed a latent stuck-on-`/splash` case for a not-active user
  and made the redirect key cleanly off `bootstrapped` + `registered` + `isBusy`.

### ✅ Phase 3.5 — Editable account (name/phone) in Settings
- Settings gained an **Account details** section (modeled on Smart-Agent's
  `AccountSettingsPage`): the agent **name** + **phone** are editable via a
  bottom sheet, plus a copyable **device ID** tile — all live from the shared
  `LicenseBloc`.
- `LicenseRepository.updateAgent` **saves locally first** (never lost), then
  best-effort syncs to the server (`update_my_data` with `full_name`/`phone`);
  a one-shot `AgentSaveOutcome` drives a green "synced" / orange "saved locally"
  snackbar. New `UpdateAgentEvent` + `isSavingAgent` state.

### ✅ POS — Product picker: live list + tap-add feedback
- The "Add item" sheet now reads the product list **live** from `ProductBloc`
  (was a one-time snapshot) — fixes the empty-on-first-open bug and shows a
  spinner until the first stream emission; search filters as you type.
- Each tile gives clear add feedback: a scale **pop + green check flash** on tap
  and a **live cart-count badge** (how many are already on the order).

### ✅ POS — Sell by weight / sale type  *(Drift schema v8)*
- New extensible `ProductSaleType` enum (`piece` | `weight`, room for
  volume/length/box) on `Product`, persisted **by name** in an additive
  `products.saleType` text column (**schema v7 → v8**, `addColumn`, defaults
  `'piece'` — every existing product unchanged). Product add/edit forms gained a
  segmented sale-type selector; the price label flips to "per kg".
- **Weighed sale entry**: a dual-field dialog shows **weight (kg)** and **money
  amount** together, live-linked (type one → the other recomputes at the per-kg
  price). Wired into the picker, barcode scan (state-driven `measuredPrompt` so
  the BLoC stays UI-free), and cart-line editing (`AddProductToCartEvent` gained
  an optional absolute `quantity`).
- **Exact-money precision**: weight is stored at full `double` precision (only
  rounded for display), so `price × quantity` reconstructs the entered amount
  exactly (`5000` → `5000.00`) — no stored line-total column needed. Checkout
  and the Arabic raster receipt render the weight + `كغ` unit.

### ✅ POS — Sales audit center  *(reworked History tab)*
- `HistoryBloc` / `HistoryPage` became a **filter-driven, paginated audit center**:
  a `SalesFilter` (date preset `today`/`yesterday`/`thisWeek`/`thisMonth`/`custom`,
  `PaymentFilter` `all`/`cash`/`credit`, text search, sort — defaults to **today**)
  plus a live **summary aggregate** (count / total / credit total).
- Cash-vs-credit is **derived** per invoice (credit iff the invoice has a `charge`
  ledger entry). New DAO projections `AuditInvoiceRow` (with `isCredit`,
  `customerName`, `itemCount`) + `AuditSummaryRow`, via
  `SalesDao.watchAuditInvoices` / `watchAuditSummary`.
- **Live + paginated**: list and summary each ride a `StreamSubscription` feeding
  internal `_InvoicesUpdated` / `_SummaryUpdated` events (can't `emit` outside a
  handler); a filter change or `LoadMoreEvent` (`_kPageSize = 30`) re-subscribes.
  Invoice line items lazy-load + cache for `/history/detail/:id` →
  `InvoiceDetailPage`; reprint reuses `PrinterRepository.printReceipt`.

### ✅ Cashbox — cash drawer  *(Drift schema v9)*
- New `features/cashbox/` — a **single-entry, signed, derived-balance** cash
  ledger (same shape as the debt ledger). One `cashbox_transactions` row per
  movement; balance = `SUM(amount)` (`amount` signed, `+` in / `−` out), never
  stored. Money `double`, rounded 2dp at write time. Additive **schema v8 → v9**
  (`createTable` + `_createCashboxIndexes()`); no existing table touched.
- Extensible `CashTransactionType` enum, persisted **by name** (never index),
  each with a `defaultDirection`. `purchasePayment` / `supplierPayment` are
  **reserved** for the not-yet-built purchases/suppliers modules — they can post
  here with no migration when those ship.
- **Auto-posting, source-owned**: a **cash sale** posts a `cashSale` inflow inside
  the sale's transaction (`SalesDao.insertInvoiceWithItems`); a **debt repayment**
  posts a `customerDebtPayment` inflow inside the payment's transaction
  (`LedgerRepositoryDriftImpl` — `LedgerRepository` now also depends on
  `CashboxDao`). Both link via `relatedId`, are `isSystemGenerated` (not
  user-deletable), and are **reversed** when their source invoice / ledger entry
  is deleted (`CashboxDao.deleteByRelatedId`) so the balance stays honest.
- Reachable from **Settings → Cashbox** (`/settings/cashbox` → `/history`), not a
  new tab (shell stays 5 tabs). `CashboxBloc` is app-wide (`LoadCashbox` at
  startup). Shared `core/utils/money_display.dart` formatting with the ledger.

### ✅ Ledger — customer duplicate-name guard
- Adding/editing a customer with a name another customer already uses now returns
  `Left(DuplicateFailure)` (new `Failure` subtype), mapped to
  `CustomerMessage.duplicateName` → the localized `duplicateCustomerName` string.
  The add/edit form also validates inline (`CustomersDao.nameExists(exceptId:)`).

### ✅ Build — Android release-build fix
- `flutter build apk` failed on `flutter_vibrate` (discontinued): it links its
  resources against an SDK older than API 31 → `android:attr/lStar not found`.
  `android/build.gradle.kts` now bumps any stale subproject's `compileSdkVersion`
  to 34 via a `subprojects { afterEvaluate { … } }` block, registered **before**
  the `evaluationDependsOn(":app")` block (you can't `afterEvaluate` an
  already-evaluated project). Verified: `--split-per-abi` produces all three APKs.

---

### ✅ Plan 001 — Cloud backup & restore  *(Google Drive)*
- Backs up the **entire live SQLite file** (`VACUUM INTO`), not a row/JSON
  export — every table captured with no per-feature serialization, but restore
  is **all-or-nothing**. `drive.file` scope only, chosen so Google requires no
  app-verification review. No client-side encryption.
- **Three independent restore guards**: schema-downgrade refusal, SHA-256
  integrity check *before* the live DB is touched, and a rollback-safe swap
  (`.pre-restore` copy, `-wal`/`-shm` deleted first). A restore **kills the app**
  — there's no in-Dart reinit of `AppDatabase`/`sl`.
- `AutoBackupService` fires on launch/resume, skipping under 24 h (no
  WorkManager). Drive account is recorded server-side and hinted back on
  reinstall. No new table.

### ✅ Plan 003 — Dual currency  *(schema v10)*
- SP is the **one book currency**; USD is a *pricing label* on a product,
  resolved to SP at the moment of sale. The rule held: nothing downstream
  (history, ledger, cashbox, reports) needed changing.
- Rate lives in two `AppSettings` rows, **not a table**. `usdToSp` rounds to a
  whole pound and returns `null` when unset, so callers must guard —
  `CartItem.isUnpriced` blocks checkout. Old invoices are immune to rate edits
  (`priceCurrency`/`fxRate`/`priceOriginal` snapshotted per line).

### ✅ Plan 005 — Manual discounts  *(schema v12)*
- Per-line + one whole-cart discount, both stored as **resolved SP amounts**.
  Percent-vs-amount is a UI affordance only — **no `isPercentage` flag is
  stored**. Cart discount **stacks on top of** line discounts.
- Clamping is deliberately redundant in three places; that's load-bearing, since
  discounts aren't re-validated when quantity changes.

### ✅ Plan 006 — Free trial
- One plain `isTrial` display flag — **no new endpoint, no new `LicenseStatus`
  state, no migration**, and **zero trial branching in `LicenseGuards`**. The
  gate, grace and tamper checks treat trial and paid identically.
- Anti-abuse is **server-side only**, keyed on device id. A local first-launch
  date was explicitly rejected (trivially reset by clearing app data).
- Guards have since moved: offline grace **7 days** (warning banner from day 3),
  clock-rollback threshold **48 h**. A guard-blocked-but-valid license routes to
  `/activation/verify`, not the plans page.

### ✅ Plan 007 — Sharing / WhatsApp  *(PNG cards)*
- One transport (`share_plus`) + pluggable renderers, so WhatsApp / Telegram /
  email / Drive all work with **no per-channel code**.
- `captureWidgetToPng` mounts the card off-screen in the app's *real* `Overlay`
  — deliberate, so it inherits `Directionality`/`Localizations`/`Theme`, which
  is what makes Arabic/RTL render correctly. **Not the same technique as the
  thermal receipts** (monochrome 384px `dart:ui` raster); the two don't
  generalize to each other.

### ✅ Plan 008 — Analytics dashboard  *(zero new tables)*
- `DashboardDao` is a read-only `@DriftAccessor` over six existing tables; every
  aggregate is computed **in SQL**, never by summing rows in Dart.
- Not a route or a tab — it's the default sub-view *inside* the Reports tab.
- Live via a **change-ticker** (`SELECT 1` with `readsFrom:`), so any
  sale/cash/debt/stock write re-runs all 10 aggregates.
- ⚠️ Profit SQL is **duplicated by design** with `SalesDao.watchAuditSummary` —
  change one, change the other or the two screens disagree.

### ✅ Plan 010 — Dynamic product attributes  *(bucket A complete, schema v13)*
- Owner-defined custom fields: definitions in `attribute_definitions`, per-product
  values as a JSON map. **No index table** — search/filter runs in Dart over the
  in-memory product list (deliberately dropped for simple shops).
- **V1.1** receipt printing of `showOnReceipt` fields (snapshotted at sale time,
  reprint-immune). **V1.2** search-by-any-attribute-value + filter chips.
  **V1.3** "Sales by field" report group-by via `json_extract` in SQL (JSON path
  is a **bound parameter**). **V1.4** thermal product labels with Code128/QR.
- **Not built (separate future plans):** bucket B (Size×Color variants) and
  bucket C (IMEI/serial per-unit tracking). Seams left additive.

### ✅ Plan 011 — V1 field-feedback fixes  *(all 11 items, schema v14)*
Source: a shopkeeper's notes after real use. Shipped in four waves —
**A** (empty add-product defaults, scanned item jumps to top, newest-first
product list, faster snackbars); **B** (out-of-stock visibility, invoice-as-table
6-column layout); **C** (app-wide font size, print-button toggle); **D** (scanner
overhaul).
- **The scanner story is the notable one.** A product that "couldn't be read"
  turned out to be an **inverted barcode** — white bars on a red tin — which ML
  Kit cannot decode natively at any angle. The rival app ships ML Kit too, so
  the engine was never the difference; **frame preprocessing** was. Fixed by
  upgrading `mobile_scanner` 5.2.3 → 7.4.0 for `invertImage` and shipping a
  "باركود فاتح" toggle. **Confirmed reading on-device.**
- Also layered in: a `formats:` whitelist, 1280×720 analysis resolution with a
  **self-healing fallback** (a hard-pinned 1920×1080 had latched "camera
  unavailable"), **multi-frame confirmation** (2 consecutive identical decodes)
  to reject checksum-valid-but-wrong misreads, real tap-to-focus and zoom.
- **Auto-alternating polarity was investigated and rejected**: `invertImage` is
  construction-time, so each flip rebinds the camera (~0.3–0.6 s blind). Ships a
  6-second no-decode hint chip instead — the toggle already worked, but nothing
  told the cashier *when* to reach for it.
- **Follow-up:** `sales_items.saleType` snapshot (v13→v14) — found while scoping
  it that **reprints dropped the unit entirely** (original ≠ reprint of the same
  invoice). Verified on-device by `integration_test/migration_v14_test.dart`.

### ✅ Navigation — Android back button
- Back on any tab root used to bubble to the system and **kill the app
  instantly** (a shop reported one stray thumb tap closing the till mid-sale).
  `AppShell` now holds a `PopScope(canPop: false)`: from a non-POS tab it goes
  home, on POS it needs a confirming second press.
- Safe because Flutter asks the **innermost navigator first** — a pushed page
  still pops on its own branch navigator and never reaches the shell.

---

## Deferred by decision — *not* a backlog

These are closed decisions, not unfinished work. Re-opening any of them should
start from the plan doc, which records why.

- ⏸️ **Plan 002 — multi-device sync** (V2). Genuine distributed-systems
  territory; the plan is phased to ship the conflict-free half first.
- ⏸️ **Plan 009 — smart assistant / alerts** (V2). Plan 008 already ships the
  *passive* version of the top-3 alerts (low-stock list, top-debtors list, KPI
  delta arrows); 009 converts pull → push, which is polish on something that
  exists rather than a missing capability.
- ❌ **Plan 004 — historical price recalculation. Rejected permanently.** A
  completed sale is a finished fact. Do not build this.
- 🔒 **Plan 005** — standing per-product sale price (V1.5) and the automatic
  rules engine (V2).
- 🔒 **Plan 007** — PDF renderer (the `pdf` dep is still deliberately unadded).
- 🔒 **Plan 008 V1.5+** — hourly sales, inventory turnover, slow-moving products,
  customer top-buyers, dashboard-as-image share.
- 🔒 **Plan 010** — bucket B (Size×Color variants), bucket C (IMEI/serial).
- ⬜ **Larger modules** — purchase invoices, suppliers, expenses, multi-store.
  Architecture was kept scalable for these; `CashTransactionType` already
  reserves `purchasePayment`/`supplierPayment` so they can post to the cashbox
  with no migration.

---

## Before shipping — verification debt

**This is the real next step, and it has grown rather than shrunk.**

`flutter test` **now runs fine** (the old websocket-503 blocker is gone) —
**108 tests pass**, `flutter analyze` clean. But those tests drive BLoCs against
**hand-written fakes** by design: they never touch Drift, native SQLite, the
printer, the camera, or the network. That's the right test architecture, and it
structurally cannot tell you whether the app works on a phone.

**Confirmed on real hardware — the complete list:**
- the **v13→v14 migration** (`integration_test/migration_v14_test.dart`)
- **Sales-by-field** group-by SQL (`integration_test/sales_by_field_test.dart`)
- the **inverted-barcode** fix, on the actual failing red-tin product

**Never exercised on a device:**
- 🔴 **Backup *restore*** — three guards and a rollback swap, none of which has
  ever run against a real Drive snapshot. Highest blast radius in the app: it
  deletes and swaps the live database, and its failure mode is a shop losing
  their books. **Verify this first.**
- 🔴 **Migrations over a real shop's pre-existing DB** — v8→v9 (cashbox) and
  v10→v14. Only v13→v14 has a device test.
- 🟠 The **printer / Arabic-raster** path (receipts, statements, product labels).
- 🟠 **Cashbox** auto-post + reversal and the derived-balance math.
- 🟠 The **licensing HTTP calls** and the **FCM live-unlock** end-to-end.
- 🟡 Sell-by-weight entry, editable-account sync, the in-app update dialog, the
  sales audit centre over real data, and the **Android back-button fix**
  (shipped 2026-07-26, still unverified).

**Recommendation: a device smoke-test pass before any further feature work**,
starting with restore and the migrations.

### Operational items that gate selling, not building

- **The backend is still Smart-Agent's** (`harrypotter.foodsalebot.com/api`,
  keyed `app_name: 'Fawateer'`). Always a placeholder; subscriptions currently
  run on another app's server. Swapping it is a one-line
  `ApiConfig.defaultBaseUrl` change *plus* a server-side migration.
- **The remote-config JSON is hosted on Google Drive**, which Plan 001's own
  author flagged as fragile and recommended moving to the server that already
  serves the APKs. That file controls the API base URL and the update prompt —
  if Drive changes its download-URL scheme, you lose the ability to repoint the
  server without shipping a build.
- ✅ **FCM is no longer dormant** — `google-services.json` is in place (project
  `fawateer-4c9bc`) and the Gradle plugin line is committed, so live-unlock is
  real. Note the file is gitignored: a fresh clone **will fail to build** until
  it's restored. See `android/README-fcm.md`.
- 🔑 **Losing the release keystore is unrecoverable** — Android refuses updates
  signed with a different key. It lives outside the repo, pointed at by the
  gitignored `android/key.properties`. See `docs/android-release-signing.md`.

---

## Commit history (this effort)

| Commit | What |
|--------|------|
| `681bcbc` | Licensing gate + debt ledger |
| `589c4d2` | Account statement (share) + Android net fixes |
| `9a8e10f` | Subscription management screen |
| `8d843b7` | Copyable device ID |
| `d51d465` | Customers bottom-nav tab |
| `8a4c6a6` | Thermal-printed statement |
| `18edcf1` | FCM live-unlock (dormant by default) |
| `3ff2fe8` | Add ROADMAP.md tracking commercialization progress |
| `728c342` | iOS device-id via `identifierForVendor` |
| `d71ab8f` | Foreground in-app banner on live subscription unlock |
| `b05c357` | Remote config (dynamic base URL + support) + in-app update check + splash-freeze fix |
| `9927e82` | Product picker — live list + tap-add feedback |
| `abba223` | Sale type: sell products by weight/amount (schema v8) |
| `f02617d` | Editable account name/phone in Settings (+ new l10n strings) |
| `1c2d765` | docs: record weight sales, remote config, editable account, picker UX |
| `4f2a774` | Cashbox transactions table + localization (schema v9) |
| `9bf5378` | Cash transaction model + repository |
| `0c69c32` | Customer select/add localization |
| `b9e41b8` | Customer duplicate-name validation + localization |
| `3e1e961` | Sales history & audit center |
| `f6b5e82` | Android release-build fix (`flutter_vibrate` lStar / compileSdk 34) |

### Since 2026-07-11 (grouped — 50 commits)

| Commits | What |
|--------|------|
| `933300f`, `a3bea68`, `34dbe87` | **Plan 001** — Drive backup/restore, account hint on reinstall, auto-backup toggle |
| `6571bac` | Plan 002 architecture revision (design only, still V2) |
| `66d74d5`, `e788adf`, `1f06a4b` | **Plan 003** — dual currency, `ل.س` default, exchange-rate modal |
| `166cb1b` | **Plan 005** — manual line + whole-cart discounts |
| `895a6c4`, `7b69b35`, `ac33f7d`, `f337daf` | **Plan 006** — free trial, expiry notices, verification screen + offline banner |
| `169ad46` | **Plan 007** — styled PNG share cards |
| `15debe0` | **Plan 008** — analytics dashboard |
| `8f4b4dd` | Plan 009 deferred to V2 with rationale |
| `92ddd57`, `a20c1ef`, `a9fcb5c`, `4ad8e3a`, `86af86b`, `1b4c289` | **Plan 010** — dynamic attributes V1 → V1.4 (fields, receipt print, search/filter, report group-by, labels) |
| `159496b`, `b19d83c`, `a006531`, `481df9c`, `7523f5d`, `fcb5380` | **Plan 011** — waves A–D |
| `f03e8cf`, `e210349`, `5256c79`, `b8c31f6`, `41068db` | Scanner hardening — resolution fallback, multi-frame confirmation, mobile_scanner 7.4.0 + invert toggle, hint chip |
| `854ccb7` | `sales_items.saleType` snapshot (**schema v13→v14**) |
| `48c6fb2` | Android back button no longer closes the app from a tab root |
| `ebc1fbe` | Strict inventory mode (opt-in block-oversell) |
| `84d1992` | Release signing with an owned keystore + per-ABI APKs |
| `069e49a`, `9c0c325`, `00e4966` | Branding — Cairo bundled offline, themed button roles, ribbon-ف adaptive icon |
| `1d9c14c`, `9aafc22`, `487991a`, `b3c7e15`, `0305b19` | FCM foreground handling, update check + prompt hardening, per-ABI download URLs, API config |
| `ca7c2ad`, `606a171`, `4c86dd2`, `60f2332`, `f808cf9` | Product uniqueness + barcode-not-found search, snackbar dismissal, settings/support polish |
| `dc388fd`, `1778abc` | Housekeeping — stray tracked files, CLAUDE.md drift corrections |
