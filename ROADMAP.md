# Fawateer — Commercialization Roadmap & Progress

Turning **Fawateer** from a plain offline POS into a commercial product with
**online-validated subscriptions** and a **customer debt ledger**.

**Branch:** `refactor/architecture-hardening`
**Last updated:** 2026-07-08 (remote config + in-app updates, editable account, product-picker UX, sell-by-weight)

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
- **Build order:** licensing first, ledger second.

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
| 4+ | Inventory / purchases / expenses / reports / multi-store | ⬜ Future |

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

### ✅ Phase 3 — FCM live-unlock  *(dormant by default)*
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

---

## Not started

- ⬜ **Larger modules** — inventory management, purchase invoices, expenses,
  reports, multi-store. (Architecture was kept scalable for these.)

---

## Before shipping — verification debt

Everything so far is validated by **`flutter analyze` only**:
- `flutter test` can't run in this environment (test-listener **websocket 503**
  at load — affects untouched tests too).
- Nothing has been exercised on a **real device** — especially the printer /
  Arabic-raster path, the licensing HTTP calls, and the FCM flow (which also
  needs a live Firebase project + server-side push).
- **Newly untested on-device flows:** the **v7→v8 migration** (`saleType`
  column) over a real pre-existing DB; the **sell-by-weight** entry + exact-money
  total + weighed receipt line; **editable account** name/phone sync
  (`update_my_data`); and the **in-app update** dialog (needs a bumped
  `latest_version` in the hosted JSON to trigger).

**Recommended:** a device smoke-test pass before further feature work.

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
