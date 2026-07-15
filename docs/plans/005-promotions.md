# Plan 005 — Promotions / Discounts

> **Status:** Design plan (no code). Prepared by CTO/Architect + accounting review.
> **Decision (locked with the owner):** **V1 = manual line discounts + one
> whole-cart (invoice) discount only.** No automatic promotion rules (no auto Buy
> X Get Y, no auto free gift, no scheduled/category promos). No standing
> per-product sale price. Both a **whole-cart discount** and a **per-product sale
> price** are *designed* here, but only the whole-cart discount ships in V1; the
> standing per-product sale price is deferred.
> **Related:** builds on Plan 003 (SP is the book; apply discounts on SP-resolved
> prices) and Plan 004 (history immutable; discounts are snapshotted, never
> recomputed). See `docs/plans/003-dual-currency.md`, `docs/plans/004-price-recalculation.md`.

---

## ⭐ The unifying idea: every promotion is just a *discount* on a line

Five different-sounding promo types collapse to **one** concept — *original price
snapshot + a discount amount* — applied at the SP boundary. Deciding the **data
model** first is what keeps accounting honest and the feature lightweight.

| Promo type | How it maps to "discount" |
|---|---|
| **Percentage discount** | line discount = `price × qty × pct` |
| **Fixed discount** | line discount = a fixed SP amount (per line, or whole-cart) |
| **Bundle price** ("3 for 5000") | set the group's line discounts so the lines sum to 5000 |
| **Buy X Get Y** ("buy 2 get 1") | the free unit is a **real line**, `qty 1`, with a 100% line discount |
| **Free gift** | the gift is a **real line**, `qty 1`, discounted to 0 |

So storage is **one thing**: keep the existing `price`/`cost` snapshot on
`sales_items`, add a per-line `discount` (default 0) and a whole-invoice discount
on `sales_invoices` (default 0). Line total derives as `price × qty − discount`;
invoice total = `Σ line totals − invoiceDiscount`. Additive, no table rebuild, and
consistent with the existing "no stored line-total column, derive it" model.

Everything else is UI now and (maybe, later) automation — all feeding this **one**
field.

## 1. Product (what the shop owner experiences)

- At checkout the cashier can apply a **discount to a line** (percentage or fixed
  SP amount) and **one discount to the whole cart** (percentage or fixed).
- A **free item / gift** is added as a normal cart line, then discounted 100% — it
  still leaves inventory (correct) and shows on the receipt as "0".
- The receipt and the history detail show the **original price and the markdown**
  (e.g. "5000 − 500 = 4500"), because the original price stays snapshotted.
- Promotions are **ad hoc at the counter** — which is how these shops (0–3 staff)
  actually run them. No rules to configure, nothing to schedule, works fully
  offline, one or two taps.

## 2. UX (flow & guardrails)

- **Per-line discount:** a small "discount" affordance on each cart line → enter %
  or a fixed SP amount. Line total updates live.
- **Whole-cart discount:** one control on the checkout total → % or fixed SP off
  the whole order. Applied after line discounts, on the running SP subtotal.
- **Clamp at zero:** a line total and the invoice total can never go negative.
- **Show the markdown:** display original → discounted so the customer sees the
  saving and the cashier can't hide it.
- **Round once:** compute the discount, then round to **whole SP** at the line /
  total boundary (per Plan 003) — no double rounding.

## 3. Technical (lightweight, scalable architecture)

### Data model (additive — no rebuild)
- `sales_items.discount` — REAL, default 0. Resolved **SP** discount for that
  line. `price`/`cost` continue to be snapshotted (original, pre-discount).
- `sales_invoices.invoiceDiscount` — REAL, default 0. Resolved **SP** whole-cart
  discount.
- (Optional, for reporting) `sales_items.discountKind` / a note — skip for V1;
  the amount is what the books need.
- Migration: bump `schemaVersion`, append one `if (from < N)` block with additive
  `addColumn`s. Every existing row decodes as "no discount".

### Cart / checkout
- `CartItem` gains a resolved SP `discount` (0 default); `total = unitPriceSp ×
  quantity − discount`. Whole-cart discount lives on billing state; the grand
  total subtracts it after summing lines.
- At confirm, snapshot each line's `discount` onto `sales_items` and the
  whole-cart discount onto `sales_invoices`, exactly like `price`/`cost`/`fxRate`
  today.

### Everything downstream is automatically correct
- **Cashbox / ledger:** both post the invoice total, which is now the *discounted*
  total — no change needed.
- **Profit:** revenue = discounted total; cost = snapshotted cost sum → margin
  reflects the discount, and a free gift correctly shows as **pure cost** (a real
  promotional expense the owner can see).
- **Audit / history / reprints:** original price + discount are snapshotted, so
  past invoices show the exact markdown forever and never recompute.

### Layering (why it's "scalable but lightweight")
The **record** is the general "discount" concept. A future rules engine (V2) would
merely *compute* the same `discount` fields the manual UI enters today — so
automation is an **additive layer with no data migration**, and V1 stays tiny.

## 4. Stock deduction — the one correctness landmine

A free/given physical item is **still inventory leaving the shelf**, so it must be
a **real cart line with `quantity` that deducts stock** — the "free" is a
*discount*, never an absent line. The current sale flow already deducts stock per
line regardless of price, so this is correct by construction. **The failure mode
to avoid:** implementing "free gift" as a magic total reduction with no line →
stock silently drifts. **Rule: giveaways are lines, not total hacks.**

## 5. Dual-currency & immutability fit

- Apply discounts on the **SP-resolved** price (after any USD→SP conversion).
  Percentages are currency-neutral; enter **fixed** discounts in **SP** (the book
  currency) to avoid a second conversion.
- The discount is **snapshotted at sale time** and never recomputed (Plan 004) —
  changing a product price or the exchange rate later never touches a past
  discounted invoice.

## 6. Business analysis, risks & mitigations

| Concern | Take / mitigation |
|---|---|
| **Real practice** | Small shops discount ad hoc at the counter, not via configured rules. Manual discounts match reality; a rules engine is enterprise-flavored and mostly unused. |
| **Discount abuse** (staff discount for friends) | Discount is recorded explicitly on the invoice → visible in the audit center; surface "total discounts" in reports. Low priority for owner-run shops, but the audit trail is free. |
| **Negative totals** | Clamp line and invoice totals at 0. |
| **Rounding drift** | Single rounding to whole SP after the discount. |
| **Free item not deducting stock** | Enforce "giveaway = real line" (§4). |
| **Over-engineering** | The biggest risk is building the rules engine in V1. Rejected — deferred to V2 on demand. |

## 7. Alternatives considered

1. **Full rules engine now** (named promos, auto BXGY, stacking, priority, date
   windows, category eligibility). ❌ Enterprise complexity for a 0–3-staff shop;
   most of it goes unused. Deferred to V2, on real demand only.
2. **Discount as a synthetic negative "Discount" line item.** ❌ Negative
   `sales_items` rows with no product complicate stock, profit, and the snapshot
   model. Rejected in favor of a discount *amount* on the real lines.
3. **Mutate the line's effective price (no original kept).** ❌ Loses the
   original-price/markdown for receipts and audit; can't show "was 5000, now
   4500". Rejected.
4. **Standing per-product sale price** (a markdown set on the product record).
   Owner-friendly ("on sale this week" without re-entering per checkout) **but**
   adds a product field + UI + an "is it on sale / which price applies" evaluation
   and interacts with the currency/immutability rules. **Designed here but deferred
   — not in V1.** When built, it simply pre-fills the line discount at add-to-cart,
   reusing the same `discount` field (additive).
5. **✅ Chosen for V1: manual per-line + one whole-cart discount** (percentage or
   fixed), snapshotted on the invoice. Covers %, fixed, bundle-by-hand, and
   free-gift-as-100%-off — 4 of 5 use cases — with zero rules engine.

## 8. Final recommendation & roadmap

**V1 (build) — manual discounts only**
- Additive `sales_items.discount` + `sales_invoices.invoiceDiscount` (SP), schema
  bump with `addColumn`s.
- Cart line: per-line % / fixed discount, live line-total update, clamp ≥ 0.
- Checkout: one whole-cart % / fixed discount on the SP subtotal, clamp ≥ 0.
- Snapshot discounts at confirm (like `price`/`cost`/`fxRate`); receipts + history
  show original → discounted. Cashbox/ledger/profit inherit the discounted total
  automatically.
- Free gift = a real line discounted 100% (stock still deducts).
- **No** automatic promotion rules. **No** standing per-product sale price.

**V1.5 (deferred, on demand) — standing per-product sale price**
- Optional markdown on the product; pre-fills the line discount at add-to-cart.
  Reuses the V1 `discount` field — additive, no migration of past data.

**V2 (deferred, on real demand only) — rules engine**
- Named promotions: auto Buy X Get Y, auto free gift over a threshold, scheduled /
  category percentage. The engine *computes* the same `discount` fields the manual
  UI writes — an additive layer, no data-model rework.

---

### Open decisions for sign-off
1. **V1 scope** — ✅ **RESOLVED: manual per-line + one whole-cart discount only.
   No auto-rules. No standing product sale price.**
2. **Whole-cart discount in V1** — ✅ **RESOLVED: yes** (in addition to per-line).
3. **Per-product sale price** — ✅ **RESOLVED: designed but deferred** (V1.5,
   additive over the same `discount` field).
4. **Rules engine (auto BXGY / gift / scheduled)** — ✅ **RESOLVED: deferred to
   V2, on demand only.**
5. **Discount representation** — ✅ **RESOLVED: a `discount` *amount* on real lines
   + a whole-invoice discount** (not negative line items, not price mutation);
   original price stays snapshotted.
