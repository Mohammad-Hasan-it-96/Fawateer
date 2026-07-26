# Plan 003 — Dual Currency Pricing (SP base, USD sticker)

> **Status:** ✅ **SHIPPED** — schema **v9→v10** (additive: `products.priceCurrency`
> plus the per-line FX snapshot `salesItems.priceCurrency`/`fxRate`/`priceOriginal`;
> all `addColumn` with defaults, so existing rows decode as SP-native).
> **As built:** the golden rule below held — the feature stayed confined to the
> two touch-points and *nothing* downstream (history, ledger, cashbox, reports)
> needed changing. `PriceCurrency` is persisted **by name** (`fromName` falls
> back to `sp`). The rate is **not a table**: `ExchangeRateService`
> (`core/currency/`) keeps SP-per-USD in two `AppSettings` rows, parsing
> defensively (non-finite or `<= 0` reads as *unset*). `usdToSp` rounds to a
> whole pound at the conversion boundary and returns `null` when the rate is
> missing, so callers must guard — `CartItem.isUnpriced` is that guard and it
> blocks checkout. Historical invoices are immune to later rate edits.
> **Rule for future work:** never use a raw `product.price` downstream — read
> the resolved `unitPriceSp` / `salesItems.price`.
> **Scope decision (locked with the owner):** SP (Syrian Pound) is the single
> **book** currency. USD is a **pricing label** on individual products only. Every
> stored amount — invoice, debt, cashbox, report — is in **SP**. USD is resolved
> to SP at the moment of sale and never lives in the ledger.

---

## ⭐ The golden rule (everything follows from this)

> **One base currency (SP) for everything that is stored/posted. Foreign currency
> (USD) is a pricing *input* only — resolved to SP at the transaction boundary,
> snapshotted with the rate that was used, and never reinterpreted later.**

This single rule confines the whole dual-currency feature to **two touch-points**:
1. a currency flag on the **product**, and
2. the **conversion** that runs when a line enters the cart / invoice.

Everything downstream — sales history, the debt ledger, the cashbox, and all
reports — stays **single-currency (SP) and needs no change**. That containment is
the entire value of this design and the reason it avoids future accounting
problems.

---

## 1. Product (what the user experiences)

- Some products are priced in **USD** (imported/durable goods — phones, cosmetics,
  clothing), because the pound is volatile and owners sticker those in dollars.
  Most products stay in **SP**.
- The owner sets **one exchange rate** ("SP per $1") in Settings.
- When a USD-priced product is sold, its SP price is computed **automatically** at
  the current rate. The cashier never does mental math.
- **The customer always pays in SP. The invoice is in SP. Debts are in SP.**
  Reports and profit are in SP. USD is only how *some price tags* are written.

**UX surface:**
- **Product form:** an SP/USD toggle beside the price (and cost).
- **Settings:** "USD exchange rate (SP per $1)" + a last-updated stamp.
- **Cart / checkout:** USD lines show both — `$10 ≈ 142,500 SP` — but the cart
  total and everything stored are SP.
- **Formatting:** SP shown with **no decimals** (piastres are effectively dead);
  USD with 2 decimals.

## 2. UX (flow & guardrails)

- **Rate-missing / stale guard (critical):** if the cart contains any USD-priced
  item and no exchange rate is set — or it's older than N days — **block or loudly
  warn before checkout**. A missing/stale rate is the single failure mode that can
  corrupt a day's takings, and the fast-moving pound makes staleness common.
- **Live dual display** on USD lines (money + SP-equivalent), consistent with the
  app's existing "show both, don't make the user toggle" pattern (cf. the
  sell-by-weight measured-entry dialog).
- Changing the rate later is a normal settings edit; it affects only **future**
  sales (see §3, historical immutability).

## 3. Technical (the cleanest architecture)

### Database design (additive only — no rebuilds)

**`products`** — add one field, same pattern as `saleType` (v7→v8):
- `priceCurrency` — extensible enum persisted **by name** (`'SP'` | `'USD'`),
  default `'SP'`. Every existing product decodes as SP; no data touched.
- `price` and `cost` stay doubles, now *interpreted in* `priceCurrency`. **One
  currency per product governs both** its price and its cost (an imported item is
  bought *and* stickered in USD). The by-name enum can grow (split price/cost
  currencies, EUR, …) with no migration if ever needed.

**Exchange rate** → `AppSettings` KV table (no new typed table, no schema bump for
the rate itself):
- `exchange_rate_usd_sp` — SP per 1 USD (the "today's rate").
- `exchange_rate_updated_at` — drives the staleness nudge.

**`sales_items`** — snapshot the conversion for display + audit (additive columns):
- `price` / `cost` continue to be snapshotted, but store the **resolved SP value**
  (the settlement number the books use).
- add `priceCurrency` (`'SP'`/`'USD'`), `fxRate` (rate used; `0`/`1` ⇒ SP-native),
  and optionally `priceOriginal` (the `$10`). **Snapshot-for-display only — never
  recomputed.**

**Migration:** bump `schemaVersion` **9 → 10**; append one `if (from < 10)` block
that `addColumn`s `products.priceCurrency` and the `sales_items` snapshot columns.
All additive `addColumn`s → **no table rebuild, no index churn**. `ledger_entries`,
`cashbox_transactions`, and `sales_invoices` are **untouched**.

### Conversion & rounding

- At checkout, each USD line converts to SP at the current rate and is **rounded to
  whole SP** (no fractional pound) *at the conversion boundary*, then snapshotted.
  Downstream sums stay clean because rounding happens once, at the edge.
- Money stays **`double`** app-wide (SP magnitudes like 150,000 are well within
  `2^53`); rounding at display and at the FX boundary keeps float noise out.

### Invoice storage

At sale time each USD line is resolved to SP and snapshotted onto `sales_items`
exactly like `cost` is today. The invoice header total, the ledger charge, and the
cashbox inflow are **already SP** and work unchanged. The invoice is stored
**fully-resolved in SP**; the USD origin survives only as the display snapshot.

### Historical invoices + exchange-rate changes

Because every sale snapshots its SP amount **and** the rate it used, changing the
rate tomorrow **can never alter a past invoice, past debt, or past report**. A sale
made at 14,250 SP/$ stays at that rate forever. This reuses the immutability the
codebase already relies on for `cost` snapshots — correct history *for free*, and
it dodges the worst dual-currency bug: **retroactive revaluation**.

## 4. Business (accounting correctness)

- **Profit:** margin = SP revenue − SP cost, both snapshotted in SP at sale time
  (a USD-costed product's cost is resolved to SP at the same moment), so margin is
  computed consistently in one currency.
  - **Known, deliberate limitation:** true FX-on-inventory (the pound moving
    between *buying* stock and *selling* it — a holding gain/loss) requires a real
    purchases module, which doesn't exist yet. V1 snapshots cost→SP at sale time;
    that is accurate *in SP terms*. Recorded as out-of-scope, not an oversight.
- **Reports:** all in SP (base currency). **No cross-currency aggregation problem
  exists** because nothing foreign is ever stored. A report may optionally *show* a
  USD-equivalent of an SP total "at today's rate" as a labeled display
  convenience — never stored.
- **Debt handling (the one real judgment call):** **debts are SP, fixed at the
  sale-time rate.** A credit sale posts an SP `charge`; repayments are SP. **Zero
  changes to the ledger.** This is the simplest, lowest-support choice and — by
  design — **avoids realized/unrealized FX gain-loss accounting entirely**, which
  is exactly the "future accounting problem" this plan is meant to prevent.

## 5. Risks & mitigations

| Risk | Mitigation |
|---|---|
| **Stale/missing rate corrupts takings** | Hard checkout guard when a USD item is in the cart and the rate is absent/old; `exchange_rate_updated_at` nudge. |
| **Retroactive revaluation of history** | Impossible by construction — SP amount + `fxRate` snapshotted per line; nothing recomputes from the current rate. |
| **Float drift in SP totals** | Round to whole SP once, at the FX boundary; SP displayed with 0 decimals. |
| **Owner mentally holds credit in USD** | Documented trade-off (§6). SP-fixed debt chosen for V1; upgrade path is additive if demanded. |
| **FX-on-inventory ignored** | Explicitly out of scope until a purchases module; margin stated as SP-at-sale-time. |

## 6. Alternatives considered

1. **True multi-currency ledger** (store amounts in their native currency, revalue
   on read). ❌ Requires realized/unrealized FX gain-loss accounting, multi-currency
   balances, and revaluation — massive complexity for a 0–3-employee shop. Rejected.
2. **USD-denominated debt, revalued at each payment** (owner's mental model: "he
   owes me $100"). Honest to the street reality — if the pound falls, an SP-fixed
   debt loses value — **but** it needs FX gain/loss handling on every repayment,
   confusing and heavy. ❌ Rejected for V1; **possible V2** only on real demand, and
   it's an *additive* change (a currency + original-amount snapshot on
   `ledger_entries`), so today's design doesn't foreclose it.
3. **No stored rate, always convert at the current rate.** ❌ Breaks all history the
   moment the rate changes. Rejected outright — this is the classic trap.
4. **✅ Chosen: SP base + USD product sticker, resolve-to-SP-at-sale, snapshot the
   rate.** Contains complexity at the product + checkout boundary; leaves ledger,
   cashbox, history, and reports single-currency and untouched.

## 7. Final recommendation

Ship the **SP-base / USD-sticker** model:

- Product carries a `priceCurrency` (SP default, USD opt-in), governing price+cost.
- A single owner-set `exchange_rate_usd_sp` in `AppSettings`, with a staleness stamp.
- At checkout, USD lines resolve to SP, round to whole SP, and snapshot
  `priceCurrency` + `fxRate` + resolved SP amounts onto `sales_items`.
- Invoices, debts, cashbox, profit, and reports are **all SP** — no changes.
- **Debt stays SP, fixed at sale-time rate.** USD-denominated debt is out of scope
  (additive V2 if ever demanded).
- FX-on-inventory is out of scope until a purchases module exists.

*One base currency for the books; foreign currency is a sticker resolved at the
sale boundary.* This is the cleanest architecture and it structurally avoids the
dual-currency accounting traps.

## 8. Roadmap (phased, no coding yet)

**V1 — Dual pricing (this plan)**
- Schema **v9 → v10**: additive `products.priceCurrency` + `sales_items` snapshot
  columns (`priceCurrency`, `fxRate`, optional `priceOriginal`).
- `AppSettings`: `exchange_rate_usd_sp` + `exchange_rate_updated_at`.
- Product form currency toggle; Settings rate field; cart/checkout dual display +
  the stale-rate checkout guard.
- Conversion + whole-SP rounding at the checkout boundary; SP/USD-aware formatting
  in `money_display.dart`.
- No changes to ledger, cashbox, history, or reports (they're already SP).

**Later / optional (only on real demand)**
- USD-denominated debt with FX gain/loss at repayment (additive to `ledger_entries`).
- FX-on-inventory holding gain/loss — arrives naturally with a purchases module.
- Multi-rate history table if the owner ever wants scheduled/auto rates (today a
  single current rate + per-sale snapshot is sufficient).

---

### Open decisions for sign-off
1. **Rate scope** — a single global `exchange_rate_usd_sp` (recommended) vs a
   per-product override. (Recommendation: single global rate.)
2. **Stale-rate threshold** — how many days before the checkout guard nags?
   (Suggestion: 3 days, configurable.)
3. **Debt currency** — ✅ **RESOLVED: SP, fixed at sale-time rate.** USD-denominated
   debt deferred to a possible V2.
4. **Show USD-equivalent in reports?** — display-only convenience "at today's
   rate", never stored. (Recommendation: optional, low priority.)
