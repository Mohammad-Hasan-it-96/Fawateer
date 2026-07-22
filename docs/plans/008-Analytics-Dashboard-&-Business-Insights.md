# Plan 008 — Analytics Dashboard & Business Insights

> **Status:** ✅ **Lean V1 IMPLEMENTED** (owner picked "lean"; placement +
> chart-lib were the recommended defaults, built as-is).
> **Decisions (as built):**
> 1. **Placement** → folded into the History tab, **renamed "Reports"**, with a
>    top **Dashboard | Sales** segmented toggle (no 6th bottom-nav tab).
> 2. **Charts** → **`fl_chart`** for the sales-trend bars only; top-products are
>    hand-drawn proportional bars, KPIs/lists are plain widgets.
> 3. **Scope** → **Lean V1**: business-health KPIs + sales trend + top products
>    + cash in/out + low-stock & top-debtor mini-lists. Everything else deferred.
>
> **How it's built:** new `DashboardDao` (schema untouched — read-only aggregates
> via `customSelect`; build_runner regenerated) → `DashboardRepository` (composes
> all aggregates in one `Future.wait`; buckets sales into **local** days in Dart)
> → route-scoped `DashboardBloc` (reloads live off a `watchChanges()` ticker) →
> `DashboardView`. Reuses the Plan 007 `estimatedProfit` correlated subquery,
> `SalesFilter` presets (added rolling **Last 7 / Last 30**), and `currencyOf`.
> KPI deltas = current vs previous equal-length period (revenue & profit only —
> the point-in-time stock figures show no arrow). `flutter analyze` clean; **35
> tests** pass (+4 dashboard). **Deferred (V1.5+):** hourly sales, inventory
> turnover / stock-movements, slow-moving products, customer top-buyers/recent-
> payments, dashboard-as-image share (the Sales tab already shares its summary
> via Plan 007). AI insights → Plan 009.
> **Reuses:** `SalesSummary` (incl. `profit`), `SalesFilter` presets, cashbox
> derived balance + per-type breakdown (Plan 007), ledger derived balances,
> `Product.isLowStock`, and — for chart export/share — `captureWidgetToPng` +
> `ShareService` (Plan 007). **Boundary:** 008 is *descriptive* analytics only;
> *prescriptive*/AI insights & alerts are **Plan 009**.

---

## ⭐ The reframe: the job is subtraction

The brief lists ~20 metrics across six domains **and** demands "extremely
simple, 5–7 charts max, owners with little accounting knowledge." Those pull
opposite ways. A shopkeeper who won't read a report won't read a six-section BI
console either. So the design is defined by what we **leave out**, not what we
can compute.

Anchor the whole screen to the four questions in the brief:

| Owner's question | Answer on screen |
|---|---|
| Is my business improving? / better than yesterday? | **KPI cards with a vs-previous delta** + one **sales-trend chart** |
| Which products sell the most? | **Top-5 products** (ranked bars) |
| Where is my money going? | **Cash in vs out** (+ expenses) |

That's one KPI row + three visuals + two mini-lists. Anything not serving those
questions is deferred or already lives in another screen (the History/audit
list, the Cashbox page, the Customers ledger).

## 1. Product — what the owner experiences

One scrollable screen, top to bottom:

1. **Time filter bar** (Today · Yesterday · Last 7 · Last 30 · This Month ·
   Custom) — every widget below recomputes on change.
2. **Business-health KPI row** — the hero: 4–5 cards, each a big number with a
   small **green/red delta arrow vs the previous equal period** (today vs
   yesterday, this-week vs last-week). Cards: **Revenue**, **Estimated profit**,
   **Cash balance**, **Outstanding debts**, **Inventory value**.
3. **Sales-trend chart** — daily sales bars for the selected range ("is it
   going up?").
4. **Top-5 products** — horizontal ranked bars; a small toggle switches the
   metric (revenue / quantity / profit).
5. **Cash in vs out** — two figures + a paired bar (sales/deposits in, expenses/
   withdrawals out), reusing Plan 007's per-type breakdown.
6. **Two mini-lists** — **Low-stock products** and **Top debtors** (compact
   ranked rows, not charts; each row taps through to the existing detail page).
7. **Share** icon (app-bar) → captures the dashboard as a PNG via Plan 007's
   `captureWidgetToPng` and hands it to the share sheet.

No drill-downs, no configuration, no "build your own report." Tapping a
low-stock row or a debtor opens the screen that already exists for it.

## 2. UX requirements

- **≤ 7 visual blocks**, one column, big touch targets, thumb-reachable filter.
- **Arabic-first RTL** throughout; charts mirrored (bars grow right-to-left,
  axis on the right). `fl_chart` needs explicit RTL handling — see §5.
- **KPI cards are the star** — large value, tiny label, a colored delta chip
  (▲ green / ▼ red / – grey). This alone answers "better than yesterday" at a
  glance without reading anything.
- **Fast first paint** — show cached/last values instantly, refine when the
  reactive query emits (no full-screen spinner on a tab the owner opens often).
- **Empty states** — a new shop with no sales sees friendly guidance, not blank
  axes.
- **No jargon** — "الربح التقديري / Estimated profit", "الديون المستحقة /
  Outstanding debts"; never "margin", "turnover ratio", "COGS".

## 3. Metrics & chart-type recommendations (BI)

Per-domain, with the **V1 / deferred** line drawn explicitly.

### Sales analytics
- **Sales trend** → **bar chart** for ≤ ~14 buckets (discrete days read better
  as bars, and bars are RTL-trivial); **line** only for 30-day+ ranges. **V1:
  bars.**
- Daily / monthly sales → same widget, just a coarser bucket (day vs month) —
  driven by the range length. **V1: daily buckets.**
- **Hourly sales → deferred** (needs time-of-day bucketing; low value for a
  small shop). Marked "future" in the brief too.

### Cashbox analytics
- Cash In / Out / Expenses / Withdrawals / Closing balance → **two big number
  cards (in, out) + a paired bar**, plus the per-type breakdown rows.
  **Avoid a pie** — pies are poor for comparison on a phone. **V1.**

### Product analytics
- **Best-selling products** → **horizontal ranked bars, top 5** (this is the
  top-N query deferred from Plan 007). **V1.**
- **Highest-profit products** → same widget, metric toggle. **V1 (toggle).**
- **Low-stock products** → **mini-list** (reuses `isLowStock`). **V1.**
- **Slow-moving products** → **deferred** (needs "days since last sale" per
  product — a heavier query; marginal for a small catalog). **V1.5.**

### Customer analytics
- **Top debtors** → **mini-list** (reuses derived ledger balances). **V1.**
- **Highest purchases / recent payments** → **deferred to V1.5** (new
  per-customer purchase aggregate; the ledger detail page already covers a
  single customer).

### Inventory analytics
- **Inventory value** = `Σ(quantity × cost)` → a **KPI card**. **V1.**
- **Low-stock** → the mini-list above. **V1.**
- **Stock movements / inventory turnover → deferred** (turnover needs average
  inventory over time; we don't snapshot stock history — would need a new
  movements ledger). **Later.**

### Business health
- **KPI cards** (revenue, estimated profit, cash balance, outstanding debts,
  inventory value) with vs-previous deltas — the core of the screen. **V1.**

**General viz rule:** bars and number-cards only in V1. No pies, no dual-axis,
no legends-to-decode. Comparison beats decoration for this audience.

## 4. Data — reuse vs. new work

**Free (already exists):**
- `SalesSummary` over any `SalesFilter` → count/total/cash/credit/**profit**
  (the profit aggregate shipped in Plan 007).
- `SalesFilter.resolveRange` → correct **local-day** bounds for all presets +
  custom (add *Last 7* / *Last 30* presets).
- Cashbox derived balance + the in-memory per-type breakdown (Plan 007).
- Ledger derived per-customer balances; `Product.isLowStock`.
- `captureWidgetToPng` + `ShareService` for image export / WhatsApp share.

**New Drift aggregates** (each a `customSelect` + `.watch()`, same pattern as
`watchAuditSummary`):
- **Sales-per-bucket trend** over a range (one row per day/month bucket).
- **Top-N products** by revenue / qty / profit over a range
  (`GROUP BY product_id`, snapshotted `price/cost/quantity/discount`).
- **Inventory value** = `SELECT SUM(quantity * cost) FROM products`.
- **KPI deltas** — the same summary run twice (current period + previous equal
  period) and differenced in Dart.

**New UI:** the dashboard screen + KPI card / trend-bar / ranked-bar / mini-list
widgets.

## 5. Technical

### Chart library
- **`fl_chart`** — mature, pure-Dart, **offline**, no native deps, actively
  maintained; renders bars/lines/pies. Used **only** for the trend bars and
  top-product bars; KPI cards and mini-lists are plain Flutter widgets.
- **RTL caveat:** `fl_chart` doesn't auto-mirror. Wrap in explicit
  `Directionality`, reverse the bar/group order, and put labels on the right.
  Test with long Arabic product names (truncate/ellipsize).
- **Alternative considered:** hand-drawn bars via sized `Container`s /
  `CustomPainter` (zero deps, full RTL control) — viable, but more code and
  weaker footing for future chart types. Recommend `fl_chart`.

### Data aggregation & the day-bucketing gotcha
- All aggregation in **SQL** (Drift `customSelect`) — never load rows into Dart
  to sum. A small shop's tables are tiny and the indexes already exist
  (`idx_sales_invoices_created_at`, `idx_sales_items_product_id`,
  `idx_cashbox_occurred_at`).
- **Local-day boundaries, not UTC.** `created_at` is `DateTime.local →
  millisecondsSinceEpoch`. Do **not** bucket with `created_at / 86400000`
  (that's UTC days and will mis-assign evening sales). Instead compute each
  bucket's `[fromMs, toMs)` **local** bounds in Dart (like `SalesFilter` already
  does) and either run one `CASE`-bucketed `GROUP BY` or N cheap `SUM` queries
  (N ≤ 30 — negligible).

### Reactive, offline, caching
- **Reactive:** back each widget with a `.watch()` stream keyed to the current
  range, exactly like the audit center — the dashboard updates live after a
  sale/payment with no manual refresh.
- **Offline:** 100% local SQLite; no network anywhere in this feature.
- **Caching / perf:** none needed for V1 given the data size. Keep the last
  emitted values in the BLoC state so re-opening the tab paints instantly while
  the fresh query resolves. If a very large shop ever stutters, add
  pre-aggregated daily-rollup rows later (not now).
- **Architecture fit:** a `DashboardRepository` (interface + Drift impl) → a
  `DashboardBloc` (app-wide or route-scoped) → the screen. Typed failures →
  ARB, per the no-English-in-BLoC rule.

## 6. Future compatibility (no redesign)

- **Weekly / monthly reports** → the trend widget already buckets by range;
  a "month" bucket + a saved date-range is a thin addition.
- **Export charts as images / share via WhatsApp** → **already solved** by
  Plan 007 (`captureWidgetToPng` + `ShareService`); the dashboard captures the
  same way. No new transport.
- **AI insights / business recommendations** → **out of scope here by design**;
  they're **Plan 009** (Smart Business Assistant). 008 produces the clean
  descriptive layer 009 reasons over.
- **Best-sellers in the Plan 007 share summary** → once the top-N query exists
  here, the sales-summary share card can include it (the V1.5 item deferred in
  Plan 007).

## 7. Risks & mitigations

| Risk | Mitigation |
|---|---|
| Feature creep back to a BI console | Hard cap: 4 questions, ≤7 blocks; defer aggressively (§3) |
| RTL charts mirrored wrong | Explicit `Directionality`, reversed bar order, right-side labels; test Arabic |
| UTC vs local day mis-bucketing | Compute local bucket bounds in Dart (§5) — never naive epoch division |
| Slow first paint on a hot tab | Keep last values in BLoC state; refine on stream emit; no blocking spinner |
| Profit read as exact/authoritative | Label **"estimated"**; it's snapshot-based like the Plan 007 card |
| New chart dep bloats app | One small pure-Dart package (`fl_chart`); used in two places only |

## 8. Roadmap

**V1 — the lean dashboard (Reports tab)**
- Time filter bar (+ Last 7 / Last 30 presets).
- Business-health KPI row (revenue, profit, cash, debts, inventory value) with
  vs-previous deltas.
- Sales-trend bar chart.
- Top-5 products (ranked bars, metric toggle revenue/qty/profit).
- Cash in vs out + expense/withdrawal breakdown.
- Low-stock & top-debtor mini-lists.
- Share dashboard as image (reuse Plan 007).

**V1.5**
- Slow-moving products; top-buyer & recent-payment customer analytics; monthly
  bucketing / saved weekly-monthly report views.

**Later**
- Hourly sales; inventory turnover & a stock-movements ledger; pre-aggregated
  rollups if scale ever demands; hand-off of the descriptive layer to Plan 009
  (AI insights & alerts).

---

## 9. Open decisions for sign-off

1. **Placement** — ✅ **Recommended: fold into History, renamed "Reports"** (no
   6th tab; History already carries summary cards). Alternatives: a new 6th
   bottom-nav tab (more discoverable, crowds the shell) or a Settings/POS entry
   (keeps 5 tabs, less discoverable).
2. **Chart library** — ✅ **Recommended: `fl_chart`, used sparingly.**
   Alternative: no dependency, hand-drawn bars (`CustomPainter`/Containers).
3. **V1 scope** — ✅ **Recommended: Lean** (health + sales + products + cash +
   two mini-lists). Alternative: Fuller (add dedicated customer & inventory
   sections) — bigger surface, later ship.
4. **KPI comparison** — each card shows **current vs previous equal period**
   with a colored delta arrow (confirm this is the "better than yesterday"
   behavior you want).
