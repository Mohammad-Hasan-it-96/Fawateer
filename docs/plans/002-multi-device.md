# Plan 002 — Multi-Device Support

> **Status:** Design plan (no code). Prepared by CTO/Architect review.
> **Depends on:** 001 backup (Google Drive integration + the "device identity ≠
> durable identity" lesson). This is the **hardest** feature in the roadmap —
> genuine distributed-systems territory — so the plan is deliberately phased to
> ship value early on the *easy* (conflict-free) half of the problem.

---

## ⭐ REVISED RECOMMENDATION (Founder Review — supersedes §7's Firestore rec)

A second review, optimizing for **fastest launch, small team, low maintenance,
high reliability** — not technical impressiveness. **The original §7 Firestore
recommendation is withdrawn.** It was over-built for a capability only ~10% of
customers will use.

### The argument that flips the decision
Firestore's whole selling point is that it *handles sync/merge complexity for
you*. **But Fawateer's data is append-only UUID events (immutable invoices,
append-only ledger & cashbox) — the exact complexity Firestore would save you
from largely doesn't exist here.** So Firestore's main advantage is neutralized,
while all its costs remain: a second backend next to the Laravel/MySQL you already
own, ongoing per-op billing, custody of shops' financial data, vendor lock-in,
and months of work. **Withdrawn for v1.** Because sync here is "collect
append-only rows by UUID," your **existing Laravel backend is the right home** for
it when the time comes.

### Options, scored for THIS project (0–3 employees, mostly 1 device)

| Criterion | A: Single only | B: QR + Backup/Restore handoff | C: QR + periodic Laravel sync (append-only) | D: Firestore real-time | **E: One-way read consolidation (Laravel)** |
|---|---|---|---|---|---|
| Dev time | none | **low** (restore already built) | medium | high | low–medium |
| Complexity | none | low | medium | high | **low (no conflict logic)** |
| Cost | $0 | ~$0 | low (existing infra) | ongoing + new vendor | low |
| UX | fine for 90% | good for *handoff*, not concurrent | real concurrent | best real-time | owner sees all, read-only |
| Offline | perfect | perfect | preserved (queue+push) | good (cache) | preserved |
| Support burden | lowest | low (restore-overwrite mistakes) | moderate | moderate–high | low |
| Maintenance | lowest | low | moderate (you own it, but small) | high (2 backends + custody) | low |
| Scalability | n/a | fine | good (per-business MySQL) | excellent (unneeded) | good |
| Risk | none | data loss if misused as sync | moderate | high (lock-in, cost, months) | low |
| Time to market | now | fast | weeks | slow | fast |

**Option E is mine (the alternative the brief invited).** One-way push of the
append-only events to Laravel → a **read-only owner view** ("see every device's
sales/debts/cash in one place"). It nails the *most common* real multi-device need
(owner oversight) using only the conflict-free half of sync — no merge engine, no
oversell risk.

### The trap inside Option B (must be stated)
B ("second device restores the latest backup") is **device handoff/replacement,
NOT concurrent multi-device.** If two devices are both selling and one "restores
the latest backup," it **silently overwrites** the other device's local sales.
B is safe only as: got-a-new-phone migration, or a strictly non-selling second
device. Never wire restore to run periodically/automatically. Guard it as an
explicit, loudly-warned "replace THIS device's data" action.

### Verdict on your proposed roadmap
**V1 (single + QR registration + backup + restore) → V2 (optional live sync) is
the correct, disciplined call — decisively smarter than sync-from-day-one.** But
sharpen it honestly:
1. **Rename V1's capability "device continuity / handoff," not "multi-device."**
   Marketing it as "use two phones together" will generate refunds and support
   tickets the day two cashiers overwrite each other.
2. **Give QR a real job in V1 or cut it.** With no sync, QR moves no data — its
   only honest V1 purpose is **licensing a 2nd device as a paid seat under the
   same subscription** (a small Laravel change). If you're not selling seats yet,
   V1 needs no QR at all; backup/restore already uses the Google account as the
   cross-device identity.
3. **Insert Option E as V1.5** (one-way read consolidation) *before* "optional
   live sync." It's most of the perceived value for a fraction of the effort.
4. **When you build V2 sync, it's Option C on Laravel (append-only), not
   Firestore.**

### If I were investing my own money — the ONE recommendation
**Launch on Option A + the Backup/Restore you already built (001), reframed as
"device continuity." Add QR only as a Laravel *seat-licensing* feature if you want
to sell 2-device plans at launch. Ship. Then, only when paying customers ask,
build Option E (one-way consolidation on Laravel), and evolve it into Option C
bidirectional. Reject Firestore (D) outright, and reject restore-as-sync for
concurrent devices.**

- **Build first:** nothing heavy — your continuity story is already done. Optional
  small QR seat-licensing on Laravel. **Get to market now.**
- **Postpone:** all real sync (Option C) until demand is proven; when you do it,
  start read-only (Option E).
- **Reject completely:** Firestore/real-time (D) — new infra, cost, custody, and
  lock-in to solve a problem your append-only design mostly doesn't have; and
  automatic restore-as-sync (the B data-loss trap).

**Why:** the highest-value, lowest-risk "multi-device" outcome for a small shop —
"my data survives a lost/broken/replaced phone" — is *already shipped* by backup.
Everything beyond that serves ~10% of users and should be earned by real demand,
built cheaply on the backend you already run, and never at the cost of your launch
date.

---

## Original brief

Design a secure multi-device system.

- **Manager Mode:** full access, activated through subscription.
- **User Mode:** scan a QR from the Manager device, auto-join the same business,
  share the same account data.
- Study critically: Is QR pairing best? Better alternatives? How should sync,
  permissions, and offline behave? What if two devices edit the same invoice?
- Analyze architecture, sync, security, database, UX, support. No code.

---

## 0. The one finding that reshapes this plan

**Fawateer's data model is already ~95% multi-device-ready, and its dominant data
is conflict-free.** From the current schema:

- `products`, `sales_invoices`, `customers`, `ledger_entries`,
  `cashbox_transactions` all use **UUID text primary keys** → no cross-device id
  collisions. Only `sales_items` uses an autoincrement int, and it is always
  written as a child of a UUID invoice (trivially fixable).
- **Sales invoices are immutable** once created (the app only creates or deletes
  them, never edits). **Debt-ledger and cashbox rows are append-only single
  entries** with derived balances. That means **the vast majority of the data is
  an append-only event stream** — and append-only streams merge across devices by
  simple *union*, with **zero conflict logic**.

The genuinely hard, mutable, conflict-prone state is small: **product stock**
(concurrent decrements), product price/name, shop settings, and customer edits.
The whole plan is built around this asymmetry: **sync the easy 95% first, quarantine
the hard 5%.**

---

## 1. Product Perspective

**Why it should exist.** A growing small shop adds a second till, a helper, or an
owner who wants to watch sales from the back office or from home. Today each
Fawateer install is an island: separate catalog, separate sales, no consolidated
picture. Multi-device turns "three phones running three businesses" into "one
business on three phones."

**Real problem solved.** (1) *Consolidated truth* — the owner sees every sale,
debt, and cash movement across all tills in one place. (2) *Shared catalog* — add
a product once, it appears on every device. (3) *Division of labor* — cashiers
ring sales while the manager keeps control of pricing, deletes, and reports.

**Is there a simpler solution?** For many shops, yes — and we should offer it
*first*: a **read-only consolidated view** (cashiers keep selling independently;
the manager device just *receives* everyone's sales/debts/cash for reporting).
That alone solves the #1 request ("let me see everything") using only the
conflict-free append-only data — no two-way merge, no stock races. Full
bidirectional catalog/stock sync is a later, harder tier. **Do not build the hard
thing to deliver the easy value.**

---

## 2. UX Perspective

**Roles (keep it to two).**
- **Manager** — the device holding the subscription. Full access: settings,
  product create/edit/delete, price changes, reports across all devices, cashbox,
  customer management, and **device management** (invite/revoke seats).
- **Cashier** — a joined device. Can: sell, scan, take payments, add customers,
  record debt repayments. Cannot: change prices, delete invoices/products, edit
  settings, or manage devices. (A third "supervisor" role can come later — resist
  it for v1.)

**Enrollment (the QR flow, done right).**
1. Manager: Settings → "Devices" → "Add a device" → shows a **QR containing a
   short-lived, single-use, signed join token** (+ business id + sync endpoint).
2. Cashier: fresh install → "Join a business" → scans the QR (the app already
   ships `mobile_scanner`) → device registers as a Cashier seat under the
   manager's subscription → initial data pulls down.
3. The QR/token **expires in minutes and is single-use** — it is an *invitation*,
   never a durable secret.

**Ongoing UX = invisible, with one honest status line.** Like backup: a persistent
"Synced 2 min ago ✓ / Offline — 3 changes pending ⚠" indicator, plus a manual
"Sync now". The single biggest UX debt in multi-device POS is *silent divergence*
("my two phones show different totals"); the antidote is always-visible sync state
and an obvious re-sync.

**Fewer steps.** Enrollment is one scan. No accounts to create, no passwords —
the QR carries the trust. (This is also the main UX argument *for* QR; see §Q1.)

---

## 3. Technical Perspective

### Architecture
Keep Clean-Arch. Sync is a **new data-source concern behind the existing
repository interfaces** — BLoCs and domain don't change. Add:
- A **`SyncEngine`** that captures local writes as a change-log and reconciles
  with a relay.
- A **`SyncTarget`** interface (mirrors 001's `BackupTarget`) so the transport is
  swappable — the concrete implementation is your **existing Laravel backend**
  (a small set of sync endpoints), never a second cloud vendor.
- **Business/tenant + role** context injected app-wide (gates the UI and the
  repositories).

### The sync model (answering "how should sync work?")
**Change-based, per-table merge rules, not a naive whole-DB copy:**

1. **Append-only tables** (`sales_invoices`+`sales_items`, `ledger_entries`,
   `cashbox_transactions`): sync as an **insert-only union**. A row, once created,
   is immutable; every device converges by collecting all rows by UUID.
   *Deletes* become **tombstones** (a `deletedAt` marker), never physical
   deletes, so a delete on one device propagates instead of "resurrecting" from
   another.
2. **Mutable entities** (`products`, `customers`, `shopSettings`): **field-aware
   last-write-wins** keyed by a per-row logical clock. Good enough for name/price/
   phone; the shopkeeper edits these rarely and rarely concurrently.
3. **Inventory (the hard one)** — do **not** store `quantity` as a
   last-write-wins scalar (two devices each selling 1 of 5 would converge to "4",
   losing a unit). Instead reframe stock as an **append-only stock-movement log**
   (exactly like the cashbox/ledger pattern the app already uses): each sale/
   restock writes a signed movement; on-hand = `SUM(movements)`. Movements are
   append-only ⇒ they **merge by union with no conflict**, and concurrent sales
   both count. (See §Q6 for the oversell caveat.)

### Required schema groundwork (additive, but real)
Every synced table needs sync metadata: `updatedAt` (a **Hybrid Logical Clock**,
not raw wall-clock — see Risks), `deletedAt` (tombstone), and `originDevice`.
Plus give `sales_items` a UUID id. These are **additive migrations** (append new
`onUpgrade` blocks; bump `schemaVersion`), consistent with the app's forward-only
rule. The UUID-PK head start means **no destructive rebuild** of the big tables.

### Offline behavior (answering "what if devices go offline?")
Each device keeps its **full local Drift DB and works 100% offline** (the app's
core promise is preserved). Local writes append to an outbound change-queue;
inbound changes apply idempotently by UUID. On reconnect, the engine exchanges
change-logs with the relay and converges. **No device ever depends on another
being reachable to make a sale.**

### Performance
Sync payloads are tiny deltas (new rows since last cursor), not full tables. The
append-only union is O(new rows). Sync is a lightweight **poll** against Laravel
(every N seconds while active, and on app-resume) — no persistent socket needed at
small-shop volume. A "data changed" push can be layered on later through the **FCM
channel already wired for licensing** (a ping that triggers a pull), but polling is
enough to launch.

### Future maintenance
The `SyncTarget` seam means the substrate can change without touching features.
The append-only-first design keeps the permanently-hard part (conflict logic)
confined to 3 mutable tables. This is the difference between a maintainable sync
and a career-ending one.

---

## 4. Business Perspective

- **Subscription impact (major upside).** Multi-device is the natural **premium/
  seat-based tier**: a Manager subscription includes *K* device seats; extra seats
  are add-on revenue. This requires the backend to model a **business owning
  multiple devices** and enforce seat limits — today one device = one
  subscription, so this is a **real change in your Laravel backend** (new
  "business/tenant" concept, join-token issuance, seat counting).
- **Customer-support impact (the biggest risk to cost).** Sync bugs are the #1
  support driver in every multi-device POS: "my two phones don't match." Budget
  for it with **observability** (per-device last-sync, pending-change count,
  a "resend everything" repair tool) baked in from Phase 1, not bolted on.
- **Cost.** Sync runs on the **Laravel/MySQL backend you already operate** — no
  new vendor, no per-operation billing, no separate data-custody surface. Marginal
  cost is a little more storage/bandwidth on infrastructure you already pay for;
  tiny at small-shop scale.
- **Scalability.** Per-business data is small and isolated (natural sharding by
  business id). Scales horizontally with number of shops.

---

## 5. Risks

**Data consistency (highest severity)**
- **Clock skew / device-time tampering.** Last-write-wins on raw device clocks is
  unsafe — and Fawateer *already distrusts device time* (the license tamper
  check). **Mitigation:** Hybrid Logical Clocks (HLC) or relay-assigned
  timestamps; never order writes by bare `DateTime.now()`.
- **Lost deletes / resurrection.** Physical deletes re-appear from another device.
  **Mitigation:** tombstones everywhere; never hard-delete synced rows.
- **`sales_items` int id collision.** Two devices mint the same autoincrement id.
  **Mitigation:** migrate to UUID (Phase 0); it's always created with its parent
  invoice so the change is contained.
- **Stock oversell (CAP trade-off, unavoidable).** You cannot have *both* fully
  offline-independent devices *and* a guaranteed "never sell the last unit twice."
  **Mitigation/decision:** choose availability — tolerate transient negative
  on-hand (via the movement log), surface it as a low-stock/negative flag, and
  reconcile. This matches physical reality (a shop sells what's on the shelf).

**Security**
- QR join token must be **single-use, short-TTL, signed**, and bound to the
  business — a leaked long-lived QR = an intruder joins the shop's data.
- Revocation: revoking a seat must **invalidate that device's sync access**
  server-side (not just hide UI).
- Trust model: same-shop, low-threat; enforce roles client-side but also **gate
  writes at the relay** where feasible (a Cashier device shouldn't be able to
  push settings/price changes even if tampered).

**Migration impact**
- Additive sync-metadata columns across ~6 tables + `sales_items` UUID + the
  stock-movement reframe. Sizable but forward-only; no destructive rebuilds
  thanks to existing UUID PKs.

**Backend/licensing**
- The "one device = one subscription" model must become "one business = N seats."
  This is the critical-path dependency and lives in **your Laravel backend**.

---

## 6. Alternative Solutions

The **option-level** comparison (A single / B backup-handoff / C Laravel sync /
D Firestore / E one-way consolidation) is scored in the **Revised Recommendation**
table at the top of this document — that table is authoritative. This section
records only the **substrate decision**, now locked.

**Substrate: your existing Laravel + MySQL backend. Firestore is rejected.**

| Substrate | Verdict |
|---|---|
| **Laravel + MySQL (existing)** | ✅ **Chosen.** You already run it for subscriptions/activation/customer management. Sync here is "collect append-only rows by UUID" + last-write-wins on 3 mutable tables — plain REST endpoints + a cursor, no distributed-systems engine. One backend, one bill, one place to look when support calls. |
| Firestore / Firebase | ❌ **Rejected.** Its value is handling merge complexity that your append-only model mostly doesn't have; in exchange it adds a *second* backend beside Laravel, per-op billing, custody of shops' financial data, and vendor lock-in. Wrong trade for this team. |
| LAN host-client | ❌ Cashiers can't work when the manager device is off/away — breaks offline autonomy. |
| Google Drive relay (reuse 001) | ⚠️ Free but a poor sync medium (polling, no push, concurrent-write races). Fallback idea only, not chosen. |

Why Laravel is genuinely low-risk here: the **append-only + UUID** data design (see
§0) removes the exact complexity that would otherwise make a hand-built sync
dangerous. You are not writing a general sync engine — you are writing
"insert-if-absent by UUID" plus a `updated_at` tiebreak for three small tables.

---

## 7. Final Recommendation

**See the Revised Recommendation at the top of this document — it is the binding
recommendation and supersedes any earlier Firestore-based text.** In short:

> **Launch on device *continuity* (the Backup/Restore from Plan 001, already
> built), plus optional QR *seat-licensing* on Laravel if you want to sell
> 2-device plans day one. Postpone real sync until paying demand appears; when it
> does, build it on Laravel, append-only-first, starting read-only (Option E) and
> evolving to bidirectional (Option C). Reject Firestore and restore-as-sync.**

### Direct answers to the brief's questions
- **Q1 — Is QR pairing best?** For *enrollment*, yes: in-person, one scan, no
  accounts/passwords, and the scanner already exists. Make the QR a **single-use,
  short-TTL, signed invite issued by Laravel**, not a durable secret. (QR solves
  *pairing*, not *sync* — don't conflate them.) In V1 its only real job is
  licensing a second device as a seat; if you're not selling seats yet, V1 needs
  no QR at all.
- **Q2 — Better alternatives?** Numeric code / deep link / account login. QR wins
  for a physical shop; keep it, add a typed fallback code for camera-less cases.
- **Q3 — How should sync work?** Change-based over Laravel REST: append-only
  *union* (insert-if-absent by UUID) for immutable events, tombstoned
  *last-write-wins* (server-assigned or HLC timestamp) for the 3 mutable tables,
  and stock as an append-only *movement log*. Poll + optional FCM "changed" ping.
- **Q4 — Permissions?** Two roles. Manager = full + device management; Cashier =
  sell/collect/add-customer only. Enforced in the UI **and** gated by Laravel on
  push (a Cashier token can't write settings/prices even if the client is tampered).
- **Q5 — Offline?** Every device runs fully on its local Drift DB and queues
  changes; converges on reconnect; no device depends on another to sell.
- **Q6 — Two devices edit the same invoice?** Invoices are immutable, so this
  rarely arises: creates never collide (UUIDs), deletes use tombstones. The *real*
  concurrent case is stock — solved by the movement log, with negative on-hand
  **tolerated and flagged** (the honest CAP trade-off: availability over a lock).

---

## 8. Roadmap (phased, no coding yet — Laravel substrate)

Sequenced by business value, not technical ambition. **V1 ships with no data-sync
engine at all.**

**V1 — Launch (device continuity; mostly already done)**
- **Continuity = Backup/Restore (Plan 001, built).** Marketed as "your data
  survives a lost/broken/replaced phone," NOT "two phones together."
- *Optional* **QR seat-licensing** — only if selling 2-device plans at launch:
  Laravel models a **business owning N device seats**; the Manager shows a QR
  (single-use signed invite); a second device registers as a seat under the same
  subscription. No business-data sync yet. (If not selling seats day one, skip
  this — ship single-device.)
- Guard Restore as an explicit, loudly-warned **"replace THIS device's data"**
  action; never automatic/periodic (avoids the Option-B overwrite trap).

**Phase 0 — Sync foundations (do only when starting V1.5, not before)**
- Additive sync metadata on synced tables (`updated_at`, `deleted_at` tombstone,
  `origin_device`); `sales_items` → UUID id; soft-delete everywhere synced.
- Laravel: sync endpoints (`push` deltas, `pull` since-cursor) scoped by business,
  authorized by device token + role.

**V1.5 — One-way consolidation (Option E; build when owners ask)**
- Devices **push** their append-only events (sales, ledger, cashbox) to Laravel;
  the Manager **pulls the union** → a **read-only "all my devices" report.**
  Conflict-free by construction. Highest value-per-effort; answers "let me see
  everything" without any merge risk.

**V2 — Bidirectional catalog (Option C; when concurrent editing is demanded)**
- Two-way sync of `products`/`customers`/`shop_settings` via tombstoned
  last-write-wins. Add a product once → it appears on every device.

**V2.1 — Distributed inventory**
- Reframe stock as an append-only **stock-movement log**; on-hand = SUM(movements)
  so concurrent sales merge; negative on-hand tolerated + flagged.

**Ongoing — Trust & observability**
- Per-device sync-status UI, pending-change counts, manual "Sync now" + "Resend
  everything" repair, seat management, Laravel-side write authorization by role.

---

### Open decisions for sign-off
1. **Substrate** — ✅ **RESOLVED: your existing Laravel + MySQL.** Firestore
   rejected.
2. **V1 shape** — ship pure single-device continuity, or include **QR
   seat-licensing** at launch (i.e. are you selling 2-device plans day one)?
3. **First sync increment** — confirm **V1.5 one-way consolidation (read-only)**
   before any bidirectional sync. (Recommendation: yes.)
4. **Subscription shape** — ✅ **RESOLVED (see Decision 04 below): sell duration
   in V1 (one business, one device); add a per-device add-on in V2.**
5. **Inventory stance** — accept the offline oversell trade-off (tolerate/flag
   negative stock)? (Recommendation: yes.)

---

## 9. Decision sign-off — Open Decisions 02 & 04

Two product-strategy questions resolved. Both land the same way: **V1 = one
device + backup/restore, sold by duration; seats and per-device pricing arrive in
V2, bundled with the sync that gives them value.**

### Open Decision 02 — QR Seat Licensing in V1?

**✅ RESOLVED: Option B — Single device + Backup + Restore. Cut QR Seat Licensing
from V1; revisit in V2 bundled with sync.** (This overrides the "optional QR
seat-licensing" hedge in §8's V1 bullet — V1 ships pure single-device.)

**The question that settles it:** when a shopkeeper licenses a *second* device,
they expect *their shop to be there* — same products, prices, today's sales. QR
seat-licensing without sync gives them a **blank, unlocked POS** that, once they
Restore onto it, **immediately diverges** from device #1 (a sale on A never reaches
B). We'd be shipping *"pay more to unlock a second empty register that silently
drifts out of sync."* That is a refund magnet and a support-ticket generator.

| Dimension | Option B (Backup/Restore) | Option C (+ QR Seat Licensing) |
|---|---|---|
| Dev effort | Already built | Needs a Laravel seat model (count/cap/transfer) — not "lightweight" |
| Customer value | Real ("never lose your data / replace a broken phone") | **Negative** once they discover no sync |
| Marketing | Honest: "Cloud Backup & Restore" | Only sells if mis-marketed as "multi-device" (a lie by omission) |
| Support | Low | High, recurring: "why don't my two phones match?" has no good answer |
| Simplicity | One device = one source of truth | Introduces the hardest idea (multi-device) before the machinery for it |
| Risk | Low | Reputation + churn: early "data doesn't sync" reviews poison a new product |
| Future compat | Clean (orthogonal to sync) | Likely-throwaway seat/enforcement work, rebuilt for V2 roles/HLC |
| Time to market | Ship today | Adds server work to V1's critical path for a feature that hurts |

- **"Licensed devices" vs "live sync" — do customers get the difference?** No, and
  that's structural. To an owner there's one question: *"is my shop on both phones
  and does it stay the same?"* "Licensed but not synced" is a category that doesn't
  exist in their mind. Shipping it confuses then disappoints. **It creates
  confusion by design.**
- **Revenue is protected without it:** Backup/Restore already tells the honest
  "second phone" story (replace your phone, keep your shop). Seats are worth paying
  for only when they buy *sync* — ship the price *with* the value in V2, not a year
  early and hollow. V1 subscription server stays simple: one subscription = one
  active device (enforced at activation, already built).
- **Nothing wasted:** when sync ships (V2), QR enrollment gets a real job (bind a
  Cashier device to a live-syncing business) and the seat model built then is the
  *permanent* one, matched to roles + sync.

### Open Decision 04 — Subscription & Seat Pricing Strategy

**✅ RESOLVED: Model D — "one business, duration-priced" in V1, with a per-device
add-on layered on in V2. Enforce the limit at the subscription (business account)
level.** (Model D is Model B, *staged* so V1 never sells a seat it can't deliver.)

**Governing constraint (from Decision 02):** in V1 a second device has no value
(no sync), so the *seat* dimension must not appear on the price list until V2.
V1 sells **time**, not seats.

| | Simplicity | Understands | Revenue | Support | V2 compat | Impl |
|---|---|---|---|---|---|---|
| A – one sub, one device | Highest | Total | Flat, no lever | Low | No path to charge for 2nd device | Trivial |
| B – business + 1 device, buy extras | High | "Shop + extra phones" | Grows | Low | Add-on maps 1:1 to a sync seat | Needs a device counter |
| C – Starter/Business/Pro tiers | Low (3 axes) | Must self-diagnose tier | High *if* seats needed | High ("which plan?") | OK | Most server work + rebuild risk |
| **D – B staged (duration now, add-on in V2)** | **High** | **One number now, one add-on later** | **Time now, seats later** | **Low** | **Cleanest** | **V1 = what you already have** |

- **Why not C:** rigid seat tiers force a zero-to-three-staff grocer to
  self-classify ("Business vs Pro?") — they freeze or pick wrong and churn. They
  also force guessing seat breakpoints before you have a single multi-device
  customer; you'd re-cut them after V2 and break existing subscribers. A V3
  optimization, not a launch structure.
- **Why not A:** safe for V1 but no clean place to attach per-device pricing later
  without repricing everyone.
- **Why D:** it *is* Model A today (all V1 can honestly sell) but with the billing
  entity shaped so a device add-on snaps on in V2 with zero migration.

**Enforce at the Subscription (business account) — not device, not user.** A device
is disposable hardware (per-device entitlement = a lockout ticket on every phone
swap). There are no user accounts in V1 and shops share one owner login (per-user
= needless scope). **The subscription *is* the business:** an entitlement record
carrying a `device_allowance` (1 in V1) + activated device IDs; activation checks
for a free slot. Already have device-ID activation + a Laravel backend → one
integer column + a small activation table. It survives for a decade because
hardware, staff, and app versions churn *underneath* a stable business record.
**Easiest to maintain long-term: the business record owns the allowance.**

**Example plans**

*V1 — duration only, one business, one device (the 3 billing periods licensing
already supports):*

| Plan | Billing | Price (illustrative — localize) | Devices |
|---|---|---|---|
| Monthly | 1 month | $X /mo | 1 |
| 6-Month | 6 months | ~5 × $X (one month free) | 1 |
| Annual | 12 months | ~10 × $X (two months free) | 1 |

*V2 — same base plans, add one line:*

| Add-on | Price | Effect |
|---|---|---|
| **+1 Synced Device** | +$Y /mo per device | Raises `device_allowance` by 1; extra device enrolls via QR and **live-syncs** |

The base always includes 1 device; the add-on is the *only* thing unlocking
multi-device — and it unlocks **sync**, so the customer pays for obvious value.

**Upgrade scenarios**
1. *Monthly → Annual (V1):* same allowance, cheaper per month. Pure billing swap.
2. *Shop grows a counter (V2):* buy +1 Synced Device; allowance 1→2; new phone
   scans QR, joins the live shop. No re-subscription, no data migration.
3. *Staff leaves (V2):* drop the add-on at renewal; allowance → 1; extra device
   deactivates at period end.
4. *Phone replacement (any version):* not an upgrade — Backup/Restore + re-activate
   the *same* single slot. **Free and frictionless**, or it reads as a cash grab.

**V1 → V2 migration path (no painful migration by design)**
1. V1 ships with every subscription carrying `device_allowance = 1`. Nobody sees
   the word "seat."
2. V2 ships sync. The *same* records now merely *permit* allowance > 1. Existing
   customers untouched — still 1 device, working as before.
3. The add-on becomes purchasable; buying it ticks allowance to 2; QR enrollment
   (now with a real job) binds the phone.
4. No repricing, no plan re-selection, no data reshape. Seats were always latent;
   V2 just turns the knob from 1. Optional Starter/Business/Pro later = mere
   presets of `device_allowance`, never a re-architecture.
