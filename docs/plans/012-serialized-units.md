# Plan 012 — Serialized Units (IMEI / Serial Number)

> **Status:** ✅ **V1 SHIPPED** — schema **v14→v15**, purely additive. Picked up
> as the next unfinished plan after Plan 011 closed out.
> **As built:** everything in the "In" scope below. `products.isSerialized` +
> `sales_items.serialSnapshot` + the `product_units` table with a partial-unique
> serial index; `UnitStatus` enum persisted by name; `ProductUnitsDao` (owns the
> quantity↔unit-count invariant), repository, route-scoped `ProductUnitBloc`,
> and a units page (add/scan, status chips, warranty date, serial search) at
> `/products/units/:id`. The POS's second scan path is live, a sold handset
> reports `unitNotAvailable` rather than `productNotFound`, deleting an invoice
> releases its units, and the serial prints on receipts **and reprints** plus
> the invoice detail page.
> **⚠️ The v14→v15 migration test is written but has NOT been run** — no device
> was attached. It is the one thing standing between this and "verified"; see
> `integration_test/migration_v15_test.dart`.
> **Verification:** `flutter analyze` clean; **127 tests** pass (+16 for this
> plan), covering the status enum's by-name fallback, the warranty boundary, the
> scan-order and sold-handset cases, the one-line-per-handset rule, and the
> reprint replaying the serial.
> **Origin:** carved out of Plan 010 as **bucket C**. That plan drew a hard line
> — *"refusing to model IMEI and Size as attributes"* was called its single most
> important decision — and deliberately left the seams additive for this one.
> **Related:** `docs/plans/010-Dynamic-Product-Attributes-&-Business-Customization.md`
> §3.5 ("Where buckets B & C plug in later"), which pre-specified the table name
> (`product_units`), its columns, and the second scan path. This plan honors that
> design rather than re-deciding it.

---

## ⭐ The one idea

> **A `Product` is a SKU. A `ProductUnit` is one physical object.** A phone shop
> holding five "iPhone 15 128GB Black" has **one product row and five unit rows**.
> The SKU carries the name, price and cost; the unit carries the IMEI, its
> status, and — once sold — which invoice sold it.

Everything below follows from that. It is also exactly why Plan 010 refused to
let IMEI be a JSON attribute: an attribute bag gives you **one** IMEI slot for
five phones, so the model is wrong on day one and warranty lookup is impossible.

---

## Why this is worth building now

Plan 010 V1.2 already shipped **search-by-attribute-value**, which the owner
immediately used for IMEI-like data. That is the demand signal — shops are
*already* reaching for per-unit identity and hitting a model that only holds one
value per SKU. Bucket C is the honest version of what they're trying to do.

It also unlocks the question a phone shop is actually asked across the counter:
**"I bought this here — is it still under warranty?"** Today that is
unanswerable. After this it is one scan.

---

## Scope — lean V1

Consistent with the owner's standing steer (*"I don't need a complex application
— this app is for all simple shops"*), V1 is the smallest thing that answers the
warranty question honestly.

### In

1. **`products.isSerialized`** — an opt-in flag. A product is either a normal
   SKU (today's behavior, untouched) or serialized. Nothing changes for the
   thousands of shops that never turn it on.
2. **`product_units`** — one row per physical item: serial, status, the invoice
   that sold it, warranty expiry.
3. **Unit management** — on a serialized product, add units (typed or scanned),
   see them listed by status, delete an unsold one.
4. **Second scan path** — a barcode miss falls through to a serial lookup. Scan
   an IMEI at the POS and *that unit* goes into the cart.
5. **Sale wiring** — selling a serialized product consumes a specific unit:
   marks it `sold`, links the invoice, and **snapshots the serial onto the sale
   line** so a reprint shows it forever.
6. **Warranty lookup** — search a serial, get: which invoice, what date, and
   whether the warranty is still live.

### Out (deliberately)

- **Bucket B variants** (Size×Color) — still a separate plan. Do not let it
  creep in here; Plan 010 flagged scope creep between B and C as a **high** risk.
- **Batch/expiry** (pharmacy) — rides on this machinery later, but a batch is
  *many* units sharing an expiry, not one unit. Different model, different plan.
- **Per-unit cost.** A unit inherits its SKU's cost. Real per-unit purchase cost
  belongs with a purchases module that doesn't exist yet.
- **Bulk serial import** (CSV/paste). Wait for a shop to ask.
- **Returns / RMA workflow.** The `status` enum leaves room (`returned`), but no
  UI drives it in V1.

---

## Decisions taken

### D1. `quantity` stays authoritative; units are the truth that maintains it

A serialized product has **two** representations of on-hand: `products.quantity`
(a number) and the count of `inStock` unit rows.

**Decision: keep `quantity` as the number every existing screen reads, and
update it in the same transaction as every unit mutation.**

Rejected: deriving `quantity` from the units table for serialized products.
It is the purer model — and it is how this app already treats the ledger and
cashbox balances — but `quantity` is not a display value here. It is read by the
POS, the oversell guard, the low-stock chip, the dashboard's inventory-value
aggregate and several SQL joins. Deriving it would mean touching all of them to
add a "unless serialized" branch, which is a large blast radius for a V1 flag
almost nobody has switched on.

**The mitigation is that unit mutations are funnelled through one repository, and
each one writes both sides in a single transaction** — the same discipline the
sale path already uses for invoice + stock + cashbox. Units remain the *source of
truth*; `quantity` is a maintained cache of `COUNT(status = 'inStock')`.

### D2. The serial is snapshotted on the sale line

`sales_items.serialSnapshot`, frozen at sale time — the same reprint-eternal rule
that already governs `price`, `cost`, `fxRate`, `discount`, `attributesSnapshot`
and `saleType`. A receipt reprinted in two years must still show the IMEI it was
sold with, even if the unit row is later edited or deleted.

The unit row *also* stores `soldInvoiceId`, but that is the **lookup** direction
(serial → invoice). The two are not redundant: the snapshot survives unit
deletion, and the link survives invoice-line edits.

### D3. `UnitStatus` is an extensible enum persisted by name

`inStock` | `sold` | `returned` | `defective`. Persisted by **name**, never
index — the same rule as `ProductSaleType`, `PriceCurrency` and
`CashTransactionType`, so reordering cases can never remap existing rows. V1
only drives `inStock` and `sold`; the other two exist so a returns flow is
additive later.

### D4. Serial uniqueness is global, not per-product

An IMEI identifies one handset on earth. A **partial-unique index** over
non-empty serials (mirroring the existing `idx_products_barcode` trick) enforces
it, so a shop cannot enter the same IMEI twice and silently sell one phone twice.

### D5. A serialized sale is quantity-1 per unit

Selling two identical phones means two cart lines, each bound to its own unit —
not one line with quantity 2. That falls out of the model, keeps the serial
snapshot one-to-one with the line, and matches how the cashier physically scans:
one IMEI at a time.

### D6. The scan fallback order is barcode → serial

Barcode first, because it is the overwhelmingly common case and already indexed.
Only on a miss do we try the serial. This ordering also means a serialized
product's *SKU* barcode still behaves normally — scanning the box barcode adds
the SKU (and then asks which unit), while scanning the IMEI on the label picks
the unit directly.

---

## Schema — v14 → v15 (purely additive)

Three additive changes, no table rebuild — keeping the streak Plan 011 noted
(v5→v6 remains the only rebuild in the app's history).

```
addColumn  products.isSerialized      BOOL  DEFAULT 0    -- opt-in flag
addColumn  sales_items.serialSnapshot TEXT  DEFAULT ''   -- reprint-eternal
createTable product_units
createIndex idx_product_units_product_id
createIndex idx_product_units_serial   UNIQUE WHERE serial != ''
createIndex idx_product_units_invoice  -- warranty lookup by invoice
```

Every existing row decodes unchanged: no product is serialized, no sale line has
a serial.

---

## Verification bar

- Host tests (fakes) for: the status enum's by-name round-trip and unknown-value
  fallback, the scan fallback order, the quantity↔unit-count invariant across
  add/sell/delete, and the warranty date boundary.
- **A device migration test** (`integration_test/`) for v14→v15 over a populated
  database — same bar Plan 011 set for v13→v14, and the reason that one is
  trusted.
