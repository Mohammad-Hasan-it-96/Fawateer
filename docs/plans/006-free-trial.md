# Plan 006 — Free Trial Subscription

> **Status:** ✅ **SHIPPED** — and it stayed as small as the key idea promised:
> **no new endpoint, no new `LicenseStatus` state, no migration.**
> **As built:** `LicenseStatus` gained one plain `final bool isTrial` (default
> `false`), cached as `lic_is_trial`. Crucially **`isTrial` is not a term in
> `isActive`** (still `isVerified && !isExpired && !timeTampered &&
> !offlineLimitExceeded`) — the server sets `status:'trial'` + a trial expiry on
> the existing `create_device`, and `check_device` returns `is_trial` alongside
> `expires_at` exactly as for a paid device. **`LicenseGuards` has zero trial
> branching — keep it that way.** `isTrial` exists only for UI: `TrialBanner`
> (renders when `isTrial && isActive`, turns red in the last 3 days) and the
> status chip.
> **⚠️ Correction to the "Related" note below:** the guards have since moved —
> the offline grace is **7 days** (soft warning banner from day 3), and the
> clock-rollback threshold is **48 hours**, not 5 minutes (the Smart-Agent
> reference's 5-min window false-positives on flat batteries and manual clock
> fixes). See `LicenseGuards` for the live values.
> **Anti-abuse is server-side only**, keyed on the device id. **Do not add a
> local first-launch date** — a client-tracked trial is trivially reset by
> clearing app data, and was explicitly rejected here.
> **Decision (locked with the owner):** **Server-granted, device-keyed 30-day
> trial that reuses the existing licensing stack.** A trial is just a
> subscription whose `expiresAt` the **server** sets automatically (30 days)
> instead of an operator.
> **Related:** rides the existing licensing feature (`features/licensing/`) —
> `DeviceIdentityService`, `create_device`/`check_device`, cached `expiresAt`,
> `LicenseStatus.isActive`, 72h offline grace, 5-min clock-rollback guard,
> GoRouter gate, FCM live-unlock. Consistent with Plan 002 Decision 04's
> device/business licensing model.

---

## ⭐ The key idea: a trial is a server-issued expiry, not a new system

> **On first device registration, the server records the trial start (keyed by
> device id) and returns `trial_expires_at = now + 30 days`. The app treats that
> expiry exactly like a paid one — same gate, same offline grace, same tamper
> guards.**

Client work is small (a `trial` status for the UI + an upgrade banner); the
server issues the expiry. Nothing about the gate, offline behaviour, or anti-tamper
logic changes.

---

## 1. Product (what the shop owner experiences)

- Install the app → **full application, unlocked, for 30 days**, no operator
  action and no payment up front.
- A clear, non-blocking **"Trial — N days left → Upgrade"** banner throughout, so
  expectations are set and conversion is prompted.
- When the trial ends, the app gates to the activation/subscription screen (the
  existing gate) — the shop's **data is preserved**; they just subscribe to keep
  using it.
- Buying is the **existing operator flow**; activation overwrites the trial expiry
  with the paid one and FCM unlocks it instantly (no reinstall, no data loss).

## 2. UX (flow & guardrails)

- **Start:** first launch registers the device once online; the server stamps the
  30-day trial and returns the expiry. The app caches it and unlocks.
- **During:** identical to a paid subscription, plus the trial banner + a visible
  days-left countdown and an Upgrade CTA (drives conversion as the clock runs).
- **Near end:** intensify the nudge in the last few days (e.g. banner turns
  amber). Optional, low effort.
- **Expiry:** the gate funnels to `/activation` (already built) — never deletes
  data; "subscribe to continue."
- **First-run offline:** the trial *starts* on one online contact (see §3). Until
  then the gate shows splash/activation. Acceptable — activation needs the network
  once anyway.

## 3. Technical (reuse the stack)

### Device identification
- Reuse `DeviceIdentityService` = `SHA-256(ANDROID_ID + salt)`. **Anti-abuse
  anchor:** on Android 8+ `ANDROID_ID` is **stable across uninstall/reinstall**
  (scoped to signing-key + device + user) and only resets on **factory reset**. So
  reinstalling / clearing app data cannot mint a new trial — the server already
  knows the device and returns the same (possibly expired) trial.
- iOS `identifierForVendor` is weaker (resets when all vendor apps are removed) —
  noted, not solved; Android is the primary target.

### Server (minimal change)
- `create_device`: on first registration with no plan, set `trial_expires_at =
  now + 30 days` and `status: 'trial'`.
- `check_device`: return `expiresAt` (+ `status`) as today.
- Conversion: the existing operator activation overwrites the trial expiry with
  the purchased one — no new endpoint.

### Client (small change)
- Add a `trial` distinction to `LicenseStatus`/state **for the UI only** (banner,
  countdown, Upgrade CTA). The `isActive` gate logic is **unchanged** — trial and
  paid both gate on "verified & not expired & not guard-blocked".
- Trial expiry is enforced by the **existing** `LicenseGuards` (trusted-server-time
  + 5-min rollback check) — clock rollback can't extend it.

### Offline validation
- Once granted, the cached `expiresAt` runs the app **offline within the existing
  72h grace**, re-syncing when online — **identical to paid**, no new path.
- The single trade-off: the trial must be *started* by one online contact (§2).

## 4. Security / abuse analysis

| Vector | Handled by |
|---|---|
| Reinstall / clear app data to reset trial | **Server-side trial record keyed to device id** — returns the same trial |
| Clock rollback to extend trial | Existing `LicenseGuards` (trusted-server-time + 5-min rollback tamper check) |
| Offline forever to dodge expiry | 72h offline grace caps it; must re-sync to keep running |
| Factory reset for a fresh trial | **Accepted** — costs the shopkeeper hours + wipes their phone; immaterial |
| Device-id spoofing (rooted/modified) | Out of scope — negligible in the small-shop market; not worth the friction to defend |

**Honest limit:** no free trial is 100% abuse-proof without payment-card or
identity verification — and adding those would cost more conversions than the
abuse costs. Device-id + server record stops the casual 95% case; that's the right
altitude for this product.

## 5. Customer-support impact

- **Net positive:** trials are **self-serve** — no operator action to let a shop
  evaluate, so the top of the funnel needs zero manual work. Operators engage only
  at conversion (existing flow).
- Support scripts to prepare:
  - "Trial expired, want to buy" → normal operator activation.
  - "Reinstalled, trial gone" → by design (one per device); explain.
  - "New phone starts a new trial" → fine/generous for now; can later be tied to
    the business record (Plan 002 Decision 04's `device_allowance`) if
    phone-hopping ever becomes a problem — not needed at launch.

## 6. Alternatives considered

1. **Client-only trial** (local first-launch date). ❌ Reset by reinstall /
   clear-data. Rejected as the mechanism.
2. **Phone/SMS-verified trial** (one trial per phone number). ❌ Friction + SMS
   cost + support load; deters legitimate shops far more than it stops abuse.
   Rejected.
3. **Payment-card-required trial.** ❌ Kills top-of-funnel for a small-shop tool.
   Rejected.
4. **Device fingerprinting.** ❌ Fragile, privacy-heavy, marginal gain over
   `ANDROID_ID` + server record. Rejected.
5. **✅ Chosen: server-granted, device-keyed 30-day trial** reusing the existing
   licensing stack.

## 7. Final recommendation

Ship the **server-granted, device-keyed 30-day trial**:
- First `create_device` → server sets `trial_expires_at = now + 30d`,
  `status:'trial'`.
- App gates identically (`isActive`); shows a distinct **Trial — N days left →
  Upgrade** banner + countdown.
- Offline grace + clock guard already prevent extension; reinstall/clear-data can't
  reset it (server remembers the device).
- Conversion overwrites the trial expiry via the existing operator flow +
  FCM live-unlock.
- Accept factory-reset abuse as immaterial; no SMS/card/fingerprinting.

## 8. Roadmap

**V1 — server-granted trial**
- **Server:** `create_device` auto-issues 30-day `trial_expires_at` + `status`
  on first registration; `check_device` returns them.
- **Client:** `trial` status in `LicenseStatus`/state (UI only); trial banner +
  days-left countdown + Upgrade CTA on the gated screens and/or a persistent
  slim banner; expiry funnels to the existing `/activation`. No change to the
  gate, offline grace, or tamper guards.

**Later (only if needed)**
- Tie trial to the **business record** (Plan 002 Decision 04) to stop
  phone-hopping, once multi-device/seats exist.
- iOS device-id hardening if/when iOS becomes a target.
- "Extend trial" as an operator action (already possible via activation — just a
  server-set expiry).

---

### Open decisions for sign-off
1. **Trial length** — ✅ **RESOLVED: 30 days** (a full monthly cycle; maximizes
   data-lock-in/stickiness at the cost of a free month).
2. **Distinct trial UI** — ✅ **RESOLVED: yes** (trial banner + countdown +
   Upgrade CTA; drives conversion), gate logic unchanged.
3. **First-run offline** — ✅ **RESOLVED: trial starts on one online contact**
   (simplest, least abusable); brand-new offline installs wait on the existing
   gate until first sync.
