# Fawateer — Commercialization Roadmap & Progress

Turning **Fawateer** from a plain offline POS into a commercial product with
**online-validated subscriptions** and a **customer debt ledger**.

**Branch:** `refactor/architecture-hardening`
**Last updated:** 2026-07-06 (iOS device-id + foreground push banner)

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
