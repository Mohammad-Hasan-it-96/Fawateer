# Plan 007 — WhatsApp Integration & Business Sharing

> **Status:** Design plan (no code). Prepared by CTO / Product Architect / UX review.
> **Decision (locked with the owner):** **One transport — `share_plus` native
> share sheet — with pluggable content renderers.** Default artifact = a **styled
> PNG** (receipt / summary card); **plain text** for quick reminders. PDF, QR,
> Telegram, Email, SMS arrive as future renderers / free share-sheet channels
> with no architecture change.
> **Related:** reuses `share_plus`, `url_launcher`, `buildCustomerStatement`
> (Feature 4 already ships as text-via-share_plus), `SalesSummary`, and the
> cashbox/ledger derived balances.

---

## ⭐ The reframe: separate *content format* from *transport*

The five "approaches" in the brief are two orthogonal questions:

- **Transport** — how it leaves the app (deep link / share_plus / native sheet).
- **Content format** — the artifact produced (text / image / PDF).

**Pick one transport; make formats pluggable.** That single decision is the whole
architecture and satisfies "future exports without redesigning."

---

## 1. Product (what the shop owner experiences)

- After any sale: a one-tap **Share** action sends a clean invoice (image) to a
  customer over WhatsApp (or anything else in the share sheet).
- End of day: one tap shares a **professional cashbox summary** and a **sales
  summary** to the owner's own WhatsApp / notes / accountant.
- From a customer: one tap shares their **account statement** (already exists).
- The owner never configures channels — they tap **Share**, the phone's share
  sheet offers WhatsApp (top), Telegram, email, SMS, Drive… whatever's installed.

## 2. UX (placement, ≤2 taps, anti-clutter)

**Anti-clutter principle:** **one Share icon per screen** — never a row of
WhatsApp/Telegram/Email buttons. Channel choice happens in the OS share sheet, not
in the app. This is both cleaner and future-proof.

| Feature | Where the Share action lives | Taps |
|---|---|---|
| **F1 Invoice** | Checkout success screen (beside Print / New Sale) **and** History → invoice detail (reprint row) | confirm → **Share** → WhatsApp |
| **F2 Cashbox daily summary** | Cashbox page app-bar action | **Share** → WhatsApp |
| **F3 Daily sales summary** | History / audit page app-bar action (shares the current filter's totals) | **Share** → WhatsApp |
| **F4 Customer statement** | Customer detail (already there) — folded into the new service | **Share** → WhatsApp |

All meet the ≤2-tap rule. WhatsApp surfaces as the top share target on Android, so
it's effectively one tap to WhatsApp while staying universal.

## 3. Technical — one architecture

### The `ShareService` = pluggable renderers → one transport
- **Renderers** (content → artifact), format-agnostic:
  - `InvoiceRenderer` (image + text), `CashboxSummaryRenderer`,
    `SalesSummaryRenderer`, `StatementRenderer` (reuses `buildCustomerStatement`).
- **Transport**: `share_plus` (`Share.shareXFiles` for images, `Share.share` for
  text). Optional `wa.me/<phone>?text=` deep link (via `url_launcher`) as a
  **second transport** only for targeted **text** reminders where a customer phone
  is known.

### Content format decision

| Format | Verdict |
|---|---|
| **Image (PNG)** | ✅ **Primary** for invoices + summaries. Professional, branded, non-editable (trust), views **inline** in WhatsApp, renders Arabic/RTL perfectly. Built by capturing a styled Flutter card via `RepaintBoundary → toImage → PNG`. **Do NOT reuse the monochrome thermal `ReceiptImage`** (that's a low-res printer bitmap) — render a fresh colored card. |
| **Plain text** | ✅ **Secondary** — quick editable reminders (debt nudge); reuse `buildCustomerStatement`. |
| **Rich text** | ❌ WhatsApp supports only `*bold*`/`_italic_`; item tables misalign in a bubble. |
| **PDF** | 🕒 **Deferred** — adds `pdf`/`printing` deps and shows as an attachment (worse than an inline image). Add later as just another renderer. |

### Why share_plus is the transport (comparison)

| | WhatsApp deep link | **share_plus (native sheet)** |
|---|---|---|
| Send image / PDF | ❌ text only | ✅ any file |
| Target a contact | ✅ `wa.me/<phone>` (text) | ⚠️ user picks in WhatsApp |
| Future channels | ❌ one per channel | ✅ **free** (Telegram/email/SMS/Drive) |
| Offline | ✅ | ✅ (compose is local) |
| Maintenance | ⚠️ fragile URL API | ✅ stable plugin |

### Offline support
All rendering (text + image capture) is **fully local** — no network. share_plus
and deep links compose offline; only the actual send uses the messaging app's own
connectivity. Consistent with the offline-first product.

## 4. Data — reuse vs. new work

The *sharing* is uniform; the real work is a few **aggregate queries**:

- **Free (exists):** `share_plus`, `url_launcher`, `buildCustomerStatement`,
  `SalesSummary` (count/total/cash/credit), cashbox/ledger derived balances,
  snapshotted `sales_items` (price/cost/discount).
- **New queries:**
  - **F2** daily cashbox breakdown (opening/closing + per-`CashTransactionType`
    sums) over `cashbox_transactions`.
  - **F3** estimated profit = Σ(price − cost) × qty − discounts from
    `sales_items` (data exists; new aggregate). **Best-selling products** = a new
    top-N query (**deferred to V1.5**, see §8).
- **New UI:** the styled invoice/summary **card widgets** captured to PNG.

## 5. Future compatibility (no redesign)

Because transport is fixed and renderers are pluggable:
- **PDF** → add a `PdfInvoiceRenderer`; same `Share.shareXFiles`.
- **QR code** → a renderer that outputs a QR PNG; shared identically.
- **Telegram / Email / SMS** → **already free** — they're just targets in the
  share sheet. No per-channel code, ever.
- **Image** → the V1 default already.

## 6. Risks & mitigations

| Risk | Mitigation |
|---|---|
| Arabic/RTL wrong in the captured image | Render the card with explicit `Directionality.rtl`; test long product names |
| Long invoices → very tall image | Cap rows / paginate the card; summarize beyond N items |
| Off-screen widget capture is fiddly | Render in an offstage `RepaintBoundary`/overlay before `toImage`; standard technique |
| WhatsApp not installed | Share sheet degrades gracefully (other apps show); a `wa.me` deep link needs a canLaunch fallback |
| Image file cleanup | Write PNG to a temp/cache dir; share_plus handles the handoff; clear on next run |

## 7. Final recommendation

**Build a `ShareService` with pluggable renderers over a single `share_plus`
transport.** Default artifact = a **styled PNG** receipt / summary card captured
from a Flutter widget; **plain text** for quick debt reminders (optionally via a
`wa.me/<phone>` deep link). One **Share** icon per screen (checkout success,
invoice detail, cashbox, history, customer detail); the OS sheet handles channels.
PDF / QR / Telegram / Email / SMS are future renderers or free share-sheet targets
— no architecture change. This is the simplest, most compatible, offline-friendly,
lowest-maintenance design and directly meets the ≤2-tap, no-clutter, future-proof
requirements.

## 8. Roadmap

**V1 — core sharing (image + text over share_plus)**
- `ShareService` + transport (share_plus; `wa.me` text deep link helper).
- Widget→PNG capture helper (offstage `RepaintBoundary`).
- **F1 Invoice image** (+ text option) on checkout success & invoice detail.
- **F4 Customer statement** folded into the service (keep text; add image variant).
- **F2 Cashbox daily summary** — new daily-breakdown query + card.
- **F3 Sales summary** (invoices / total / cash / credit / estimated profit) —
  reuse `SalesSummary` + a profit aggregate + card. **Best-sellers excluded.**

**V1.5**
- **Best-selling products** in F3 (new top-N query).
- Optional **PDF** renderer (add `pdf` dep) for formal invoices.

**Later**
- QR-code renderer; explicit Telegram/Email/SMS shortcuts if the generic sheet
  ever proves insufficient (unlikely).

---

### Open decisions for sign-off
1. **Default invoice artifact** — ✅ **RESOLVED (recommended): image (PNG)
   primary + text secondary.** (Alternative: text-only V1, images in V1.5 — flag
   if you prefer the lighter start.)
2. **Best-selling products in F3** — ✅ **RESOLVED: deferred to V1.5** (new top-N
   query); ship the core summary first.
3. **PDF** — ✅ **RESOLVED: deferred** (avoid the `pdf` dep until asked); the
   architecture already supports adding it as a renderer.
4. **Targeted `wa.me` deep link** — include for the debt-reminder text path (phone
   known); everything else goes through the share sheet.
