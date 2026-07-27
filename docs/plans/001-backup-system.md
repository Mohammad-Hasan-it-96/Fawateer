# Plan 001 — Cloud Backup System

> **Status:** ✅ **SHIPPED** (design below built as specified). Lives in
> `features/backup/`, reached at Settings → `/settings/backup`.
> **As built:** `BackupEngine.createSnapshot` uses `VACUUM INTO ?` — the whole
> live SQLite file, not a row/JSON export, so every table is captured with no
> per-feature serialization (and restore is **all-or-nothing**).
> `GoogleDriveBackupTarget` holds the `drive.file` scope exactly as decided, so
> no Google verification review is triggered. Restore has **three independent
> guards**, all load-bearing: a schema-downgrade refusal, a SHA-256 integrity
> check *before* the live DB is touched, and a rollback-safe swap
> (`.pre-restore` copy + `-wal`/`-shm` deletion); both rejections surface as
> `IncompatibleFailure`. A restore **kills the app** (`SystemNavigator.pop()`)
> — there is no in-Dart reinit of `AppDatabase`/`sl`. `AutoBackupService` fires
> on launch/resume, skipping if the last backup is under 24 h old (no
> WorkManager, foreground-triggered by design). `BackupExportRequested` is the
> Phase-0 fallback, still present. No new table — `SettingsDao` holds
> `backup_last_at` / `backup_account_email` / `backup_auto_enabled`.
> **Not built (deliberate):** client-side encryption — the `.sqlite` goes up
> as-is, protected only by the user's Drive account.
> **⚠️ Never device-verified:** the restore path (guards + rollback swap) has
> never run against a real Drive snapshot on hardware. See `docs/google-drive-api-setup.md`.
> **DECISION (locked):** Primary engine = **Google Drive** via a **free Google
> *Cloud* Console** project (`drive.file` scope). This is NOT the paid Google
> *Play* Console — see the callout below. Local export + share is the Phase-0
> safety net / permanent fallback.
> **Context:** Offline-first Flutter POS, Drift/SQLite, no Google Play Console,
> operator-driven subscription, Arabic-first small shops, `double` money,
> reuses Smart-Agent PHP backend, `share_plus` already a dependency, Firebase
> partially wired (FCM, dormant).

---

## Original brief

Design a cloud backup system for an offline-first Flutter POS application.

* App works completely offline. Local DB: Drift (SQLite).
* **Google Play Console account is NOT available.**
* Need automatic **and** manual backups.
* Goals: very simple for the user, one-click restore, minimal support requests.
* Study all providers (Google Drive API / App Folder, Firebase, Dropbox,
  OneDrive, Supabase Storage, WebDAV, self-hosted, others).
* Recommend the best solution for a small startup with a limited budget.

---

## 1. Product Perspective

**Why it must exist.** For a small shop, the phone/tablet *is* the business ledger.
A lost, stolen, factory-reset, or water-damaged device today means **total,
unrecoverable loss** of every invoice, product, customer debt, and cash record.
This is the single highest-severity risk in the entire product — worse than any
bug, because it is silent and permanent. A subscription product that can lose all
of a customer's data on a dropped phone is not commercially defensible.

**Real problem solved.** "My phone broke and I lost all my customers' debts and my
sales." Backup converts a catastrophic, business-ending event into a 2-minute
recovery on a new device.

**Simpler solution?** The genuinely simplest safety net is a **manual local export
that the user shares to their own WhatsApp/Drive/email** via the native share
sheet (`share_plus`, already present) — zero infrastructure, zero cost, works
today. That is real, and it is **Phase 0** of this plan. But "very simple" and
"minimal support" ultimately require *automatic* backup, because a manual step
the shopkeeper forgets to do is worthless the day the phone breaks. So the
simplest *sufficient* solution is: automatic backup with a manual fallback.

---

## 2. UX Perspective

Design principle: **the shopkeeper should never have to think about backup.** The
only two moments backup is allowed to demand attention are (a) first setup and
(b) restore on a new device.

**Interaction model (target):**
- **Setup once:** Settings → "Backup & Restore" → "Turn on automatic backup" →
  pick/confirm a Google account → done. One screen, one sign-in.
- **Ongoing:** invisible. A single status line: *"Last backup: today 14:30 ✓"*
  (green) / *"3 days ago ⚠"* (amber) / *"Never — your data is not protected"* (red).
- **Manual:** one "Backup now" button for reassurance.
- **Restore:** fresh install → onboarding shows *"Restore my data"* → sign in →
  pick the most-recent backup (pre-selected) → one tap → restored.

**Fewer steps.** Restore is intentionally *one meaningful tap* after account
sign-in (we pre-select the newest backup and show its date + record counts so the
user just confirms). No file browsing, no passwords by default, no schema talk.

**Simplification decisions:**
- **No user-chosen backup password by default.** Lost passphrase = lost backup =
  a support catastrophe worse than the one we're solving. Security comes from the
  user's own Google account, not a password we can't reset.
- **Arabic-first copy**, plain language ("نسخة احتياطية" / restore), no jargon
  like "sync", "cloud storage quota", or "OAuth".

---

## 3. Technical Perspective

### What we back up (and what we deliberately don't)
- **Back up:** the single Drift database file `fawateer` (invoices, items,
  products, customers, ledger, cashbox, shop settings, `AppSettings` KV). This is
  the entire business state.
- **Do NOT back up / restore:** the licensing state in `SharedPreferences`. It is
  **device-bound** — `DeviceIdentityService` hashes a per-device raw id, so a
  restored device has a *different* device id and must re-validate the license
  against the server anyway. Restoring stale license cache would only cause
  confusion. License recovery is already handled by the operator-driven gate.

### Snapshot method (consistency)
Drift runs SQLite in WAL mode; you cannot just copy the `.sqlite` file mid-write.
Use **`VACUUM INTO '<path>'`** to produce a **transactionally consistent,
defragmented single-file copy** while the DB is open. This avoids WAL/`-shm`/`-wal`
sidecar handling and gives the smallest possible file. Expose one method on
`AppDatabase` to run it.

### Backup container & manifest
A backup is a small file (`.fawateer` — a zip) containing:
- `data.sqlite` — the `VACUUM INTO` snapshot.
- `manifest.json` — `{ appVersion, schemaVersion, createdAt, deviceId,
  rowCounts:{invoices,customers,...}, sha256(data.sqlite) }`.

The manifest powers the **three critical guards**:
1. **Downgrade guard (data-consistency, the biggest risk).** Restoring works by
   dropping in an old SQLite file and letting Drift's forward-only, append-only
   `onUpgrade` migrate it up — that is safe *upward*. Restoring a **newer**
   backup into an **older** app is a silent-corruption trap. Rule: **refuse
   restore when `manifest.schemaVersion > app.schemaVersion`** and tell the user
   to update the app first.
2. **Integrity guard.** Verify `sha256` after download before touching the live
   DB — never restore a truncated/corrupt file.
3. **Provenance / display.** Show date + record counts so the user restores the
   right file with confidence.

### Restore safety (reversibility)
Before overwriting the live DB: close it, copy current file to
`fawateer.pre-restore`, swap in the restored file, reopen. If reopen/validation
fails, roll back to `.pre-restore`. A restore must never be able to destroy the
data that was already on the device.

### Architecture (fits existing Clean-Arch + BLoC + GetIt + fpdart)
New feature `features/backup/`:
- `domain/` — `BackupRepository` (returns `Either<Failure, T>`), and a
  **`BackupTarget` interface** (`upload/list/download/delete`) so the storage
  provider is pluggable (local-share, Google Drive, future self-hosted) without
  touching the engine. Entities: `BackupManifest`, `BackupInfo`.
- `data/` — `BackupRepositoryImpl` (VACUUM/zip/manifest/checksum/restore-swap) +
  `LocalShareTarget` and `GoogleDriveTarget` implementations.
- `presentation/` — `BackupBloc` + a "Backup & Restore" settings page and a
  restore entry in onboarding.
- **DI order** (per `service_locator.dart` convention): `AppDatabase` → target(s)
  → `BackupRepository` → `BackupBloc` (factory). Failures reuse the typed
  taxonomy (`NetworkFailure`, `ServerFailure`, `CacheFailure`) plus a small
  `BackupError` enum mapped to ARB in the page (no English in the BLoC).
- **Drift impact:** none to the schema. Backup bookkeeping (`last_backup_at`,
  `last_backup_target`, `drive_account_email`) lives in the existing `AppSettings`
  KV table — **no `schemaVersion` bump.**

### Offline behavior (this is an offline-first app)
- Backup **generation** works fully offline (VACUUM+zip locally). We always keep
  the newest local snapshot on-device.
- Backup **upload** is opportunistic: run on app-resume/launch when *online* and
  the last successful cloud backup is older than the cadence (default daily), plus
  after every confirmed sale increment a counter and force a backup every N sales.
- **No background service / WorkManager** in v1 — Android background limits +
  battery + OEM killers are a large support surface for marginal benefit in an app
  the shop opens every day. Foreground-triggered cadence is simpler and enough.

### Performance
DB is small (thousands of invoices ≈ a few MB). VACUUM+zip+hash is sub-second;
upload is a few hundred KB. Negligible. Do it off the UI isolate if needed.

### Future maintenance
The `BackupTarget` seam means adding self-hosted or Dropbox later is one class, no
engine change. The manifest+schemaVersion contract makes every future migration
automatically backup-compatible **as long as migrations stay forward-only and
append-only** (already a locked rule in CLAUDE.md). This plan adds no new
migration debt.

---

## 4. Business Perspective

- **Subscription impact (positive, and a retention lever).** "Your data is safe,
  automatically" is a top-3 reason a shop keeps paying. Recommendation: gate
  **automatic cloud backup** behind an active subscription, but **never gate the
  user's ability to export/restore their own data** — data portability must
  survive an expired subscription (ethical, and avoids "you're holding my
  business hostage" reviews/chargebacks).
- **Cost.** The recommended path (user's own Google Drive) is **$0 marginal cost
  to the startup, forever** — backups live in each shop's own free 15 GB Google
  quota, not on infrastructure you pay for. This is decisive for a limited budget.
- **Customer support impact.** Biggest driver of *reduced* support ("I lost
  everything" tickets vanish). New support surface = Google sign-in confusion;
  mitigated by clear Arabic UI, showing the signed-in account email, and the
  local-file fallback for users who won't/can't use Google.
- **Scalability.** User-storage model scales to unlimited shops with zero backend
  scaling and zero data-custody liability on your side (shop financial data stays
  in the shop's account, not your server — a privacy/breach advantage).

---

## 5. Risks

**Edge cases**
- Google token expired/revoked → backups silently stop. *Mitigation:* prominent
  "last backup was N days ago" staleness warning; treat stale backup as an alert,
  not a silent state.
- User signs into a *different* Google account after device swap → can't find old
  backups. *Mitigation:* store & display the account email used; guide the user.
- User declines/​has no Google account. *Mitigation:* local export/share fallback
  is always available (Phase 0).
- Device storage full during VACUUM. *Mitigation:* pre-check free space; fail
  gracefully with a clear message.
- Sideloaded app (no Play Console) + Google OAuth → *unverified app* scare screen
  **only** happens with sensitive/restricted scopes. Using **`drive.file`** (or
  `drive.appdata`) avoids restricted scopes entirely → **no Google verification,
  no scary consent screen, no Play Console needed.**

**Data consistency (highest severity)**
- **Schema downgrade on restore** — newer backup into older app. *Mitigation:*
  hard `schemaVersion` guard (§3). This is the one that silently corrupts if
  missed — it is the plan's top guardrail.
- Corrupt/partial upload or download. *Mitigation:* sha256 verify before swap.
- Restore destroying good local data. *Mitigation:* `.pre-restore` rollback copy.

**Synchronization**
- **Multi-device double-write** (two devices, same shop, same account overwriting
  each other's backup). Out of scope now (that is Plan 002), but *forward-guard*
  by namespacing backup filenames per `deviceId` so two devices don't clobber one
  backup. Restore still lists all of them.

**Migration impact**
- None to the DB schema. The only migration-adjacent contract is "restore relies
  on forward-only migrations" — already a locked rule.

---

## 6. Alternative Solutions

Full provider matrix (scored for *this* project's constraints):

| Provider | Cost to startup | Play Console needed | User friction | Data custody / liability | Survives device loss? | Verdict |
|---|---|---|---|---|---|---|
| **Local export + `share_plus`** | $0 | No | Manual (user must remember) | User's own | Only if user actually shared it | ✅ Safety net / fallback |
| **Google Drive `drive.file`** | **$0 (user quota)** | **No** (non-sensitive scope) | Google sign-in once | **User's Google account** | **Yes (account = cross-device identity)** | ⭐ **Recommended primary** |
| Google Drive App Folder (`appdata`) | $0 | No | Google sign-in once | User account, hidden folder | Yes | Good, but user can't see/manage files (harder support) |
| Firebase Storage | **You pay** (Blaze egress/storage) | No | Needs Firebase Auth (app has none) | **You (liability)** | Yes | ❌ Cost + adds an auth system |
| Supabase Storage | You pay (small free tier) | No | Needs account system | **You (liability)** | Yes | ❌ Cost + custody + new backend |
| Self-hosted endpoint (reuse PHP backend) | You pay storage/bandwidth | No | **None** (device id exists) | **You (liability)** | **No** — new device = new hashed device id, can't locate old backups without an added recovery-code/account map | ❌ Fails the core use case |
| Dropbox API | $0 (user 2 GB) | No | Dropbox sign-in | User account | Yes | Fine, but few target users have Dropbox |
| OneDrive (MS Graph) | $0 (user quota) | No | Microsoft sign-in | User account | Yes | Fine, but uncommon in target region |
| WebDAV / Nextcloud | Varies | No | **Too technical** for small shops | Depends | Yes | ❌ Wrong audience |

**Three head-to-head finalists:**

- **A — Local export + share sheet.** *Pros:* zero infra, zero cost, ships in a
  day, no OAuth, works offline, permanent fallback. *Cons:* manual → forgotten →
  useless on the bad day. **Role: Phase 0 safety net, not the whole answer.**
- **B — Google Drive (`drive.file`), user's own account.** *Pros:* $0 to you,
  automatic, no Play Console, no scary consent (non-sensitive scope), **the Google
  account is a natural identity that survives total device loss**, user can see
  their backups in Drive. *Cons:* one-time Google sign-in; token can expire.
- **C — Self-hosted backup on the existing PHP backend, keyed by device id.**
  *Pros:* no third-party login, fully under your control, ties to subscription.
  *Cons:* **you pay + you become custodian of many shops' financial data
  (liability/breach)**, and — decisively — a **new device has a new device id, so
  it cannot find the old device's backups**, which is *exactly* the scenario
  backup exists for. Would require adding a recovery-code/account layer to fix.

---

### ⚠️ Play Console vs. Cloud Console — the false blocker

The brief's "no Google Play Console" does **not** block Google Drive. Two
different products get conflated:

| | **Google Play Console** | **Google Cloud Console** |
|---|---|---|
| Purpose | Publish the app on the Play **Store** | Create API keys / OAuth credentials |
| Cost | **$25 one-time** developer account | **Free** — no card |
| We have it? | No (and don't need it) | Create once with any Gmail |
| Needed for Drive backup? | **No** | **Yes** |

One-time free setup: create a Cloud project → enable **Drive API** → OAuth consent
screen with only the **`drive.file`** scope → Android OAuth client registered with
the app's **package name + release-keystore SHA-1** (the keystore already exists
for sideloading; no Play Console involved).

Because `drive.file` is a **non-sensitive** scope: no Google security assessment,
no annual review, no fee. Publishing the consent screen to *production* (to remove
the 100-test-user cap) is a **self-service toggle with no review**. The only
one-time chore is registering the SHA-1 for Google Sign-In — works fine on a
sideloaded, self-signed release build.

---

## 7. Final Recommendation

**Adopt B (Google Drive, `drive.file`, the user's own account) as the primary
automatic backup, with A (local export + share) as Phase-0 safety net and
permanent fallback.**

Why this is the best *long-term* choice:
1. **It survives the actual disaster.** The whole point is recovering a
   lost/broken device. Our app's own identity (`deviceId`) is device-bound and
   does **not** survive a device swap — so a self-hosted, device-keyed scheme (C)
   fails the primary use case without extra machinery. A **Google account is a
   durable cross-device identity the user already has**; they sign in on the new
   phone and their data is right there.
2. **$0 marginal cost, forever** — data lives in each shop's own 15 GB quota. The
   right economics for a limited-budget startup, and it scales to unlimited shops
   with no backend scaling.
3. **No Google Play Console and no verification pain** — `drive.file` is a
   non-sensitive scope, so there is no restricted-scope security assessment and no
   "unverified app" scare screen. The stated blocker simply doesn't bind here.
4. **Zero data-custody liability** — you never hold shops' financial data; it
   stays in their account. Better privacy posture and no breach exposure.
5. **Simplicity for the user** — invisible after a one-time sign-in, one-tap
   restore. And the local-share fallback covers anyone without/declining Google,
   so no user is ever left unprotected.

This keeps the app "extremely simple," costs the startup nothing, needs nothing
we don't have, and directly defeats the highest-severity risk in the product.

---

## 8. Roadmap (phased, no coding yet)

**Phase 0 — Backup engine + local safety net** *(highest value per effort; kills
the data-loss risk immediately)*
- `AppDatabase.vacuumInto()` snapshot; build the `.fawateer` zip (data + manifest
  + sha256).
- `BackupRepository`, `BackupTarget` interface, `LocalShareTarget` (export via
  `share_plus`; restore via file picker).
- Restore pipeline with `schemaVersion` guard, checksum verify, `.pre-restore`
  rollback.
- Minimal "Backup & Restore" settings page: *Backup now (share)* / *Restore from
  file*. Arabic ARB strings.

**Phase 1 — Google Drive provider**
- `GoogleDriveTarget` (`drive.file` scope): sign-in, upload, list, download,
  delete. Google Cloud OAuth client + release-keystore SHA-1 (no Play Console).
- Provider selection behind the existing `BackupTarget` seam.

**Phase 2 — Automatic backup + status**
- Opportunistic cadence (on resume/launch when online, daily + every N sales).
- "Last backup" status line with green/amber/red staleness states + warnings.
- Per-`deviceId` backup filenames (forward-guard for future multi-device).

**Phase 3 — Commercial polish**
- Gate *automatic cloud* backup behind active subscription; keep manual
  export/restore always free (data portability).
- Retention: keep last K backups, prune older.
- Restore entry in first-run onboarding ("Restore my data").
- Optional (off by default) passphrase encryption toggle for the security-minded.

---

### Open decisions for sign-off
1. ✅ **RESOLVED** — Primary = **Google Drive (`drive.file`, user account)** via a
   free Google Cloud project. Local export/share is the Phase-0 fallback.
2. Confirm **subscription gating** of *automatic* cloud backup (manual stays free).
3. Confirm **default cadence** (proposed: daily + every N sales; N ≈ 20).
4. Confirm **no default backup password** (rely on the Google account).
