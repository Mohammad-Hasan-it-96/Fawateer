# Plan 015 — Shared Barcodes and Flavour Variants

> **Status:** 🔬 **STUDY — no decision yet.** Source: `docs/v1-fixes-2.txt` #11.
> The owner's own note: *"this last problem needs study of the best options and
> suggestions before any decision."* This document is that study. It ends with a
> recommendation, not an implementation.

---

## The two real cases from the shop

They look like one problem and they are **opposites**.

**Case A — cigarettes: one barcode, two prices.**
The same packet is sold at two prices (old stock vs new stock, or two package
sizes that the factory gave the same code). One code → the app must ask *which
one?*

**Case B — juice: many barcodes, one price.**
Every flavour has its own barcode. All flavours cost the same and, for the
shop's purposes, are the same product. Many codes → the app should ideally treat
them as *one thing*, or at least make entering them cheap.

A single feature cannot solve both. They need separate answers.

---

## What the code says today

`_createIndexes()` in `AppDatabase`:

```sql
CREATE UNIQUE INDEX IF NOT EXISTS idx_products_barcode
  ON products (barcode) WHERE barcode != ''
```

So **two products with the same non-empty barcode are impossible right now.**
That index is not an accident:

- The migration that creates it first **blanks duplicate barcodes**
  (`UPDATE products SET barcode = '' WHERE … rowid NOT IN (SELECT MIN(rowid) …)`),
  because otherwise a legacy database with two identical codes would fail to
  open. Any change here must keep that path safe.
- On the **sync branch** the v16→v17 step *recreates the same index* narrowed to
  live rows (`AND deleted_at = ''`), so a deleted product releases its barcode.
  Whatever we decide here has to be redone there. **Do not write this migration
  on one branch without agreeing the merge order.**

Product lookup is `ProductsDao.getByBarcode` → **one row**, then
`BillingBloc._onScanBarcode` adds it. Serialized products already added a second
lookup path (`getByBarcode` → miss → `getBySerial`), so a "scan resolves to more
than one candidate" idea is not foreign to the code — but today it always ends
in exactly one product.

---

## Case A — one barcode, two prices

### Option A1 — the owner's proposal: two products, same barcode, POS asks

Allow a second product with the same barcode, created **only** from an existing
product's page ("add a variant of this product"), never by typing a duplicate
code by accident. On scan, POS shows a small sheet: *which one?*

- ✅ Matches how the shop actually thinks ("two kinds of the same packet").
- ✅ Each price keeps its own stock, cost and sales history — reports stay right.
- ❌ **Requires dropping the UNIQUE index** → migration, on two branches.
- ❌ Losing the uniqueness guard means a typo can now silently create a duplicate
  product. The guard exists because that mistake is common.
- ❌ Every scan of that code now costs the cashier one extra tap, forever.

**If we take this, the guard must be replaced, not just removed:** keep a plain
(non-unique) index for speed, and make the *add/edit product* form still refuse a
duplicate barcode **unless** the user came through the explicit "add a variant"
button. The uniqueness moves from the database to the flow that creates it.

### Option A2 — one product, two prices on it

Add an optional `priceB` (+ label) to `products`. Scan → the cart line has a
small toggle between the two prices.

- ✅ No index change. One additive column. Smallest possible migration.
- ✅ No duplicate-product risk at all.
- ✅ Fewer taps: the line is already in the cart; the toggle just re-prices it.
- ❌ **One stock count for both**, which is wrong if old and new stock are
  genuinely different quantities.
- ❌ Reports cannot separate "sold at price A" from "sold at price B" unless the
  sale line records which was used. (It can: `salesItems` already snapshots
  `price`, so the *number* is preserved — only the *label* would be missing.)
- ❌ Does not generalise if a third price ever appears.

### Option A3 — do nothing in the data; use the existing "unpriced" flow

The cashier edits the price on the cart line for that sale.

- ✅ Zero work.
- ❌ Manual every single time, and it silently loses the "which price" record.
- Only acceptable if the case is rarer than the shop says.

### Recommendation for Case A

**Start with A2 (two prices on one product), and only go to A1 if the shop says
the two kinds have genuinely separate stock.**

The deciding question for the owner is exactly this: *when you count these
packets on the shelf at night, do you count them as one pile or two?*
- One pile → A2 is right and much cheaper.
- Two piles → A1 is the honest answer and the migration is justified.

---

## Case B — many barcodes, one price (flavours)

### Option B1 — many barcodes per product

A new `product_barcodes` table (`product_id`, `barcode`), so one product can be
reached by ten codes. Lookup becomes: `products.barcode` → miss →
`product_barcodes`.

- ✅ The shop's model exactly: *"this is one product — orange juice — and here
  are its ten codes."*
- ✅ One stock count, one price, one row in reports. Which is what they asked for.
- ❌ New table + migration + a UI to manage the code list.
- ❌ **The receipt loses the flavour.** The customer bought orange, the receipt
  says "juice". Ask whether that matters. (It usually does not for a corner shop
  and very much does for a return.)

### Option B2 — separate products, faster entry

Keep one product per flavour, but make creating the next one nearly free: a
"duplicate this product" action that copies name/price/cost/attributes and asks
only for the new name and barcode.

- ✅ No schema change at all.
- ✅ Flavour shows on the receipt, and per-flavour sales reports work — which is
  real information for reordering.
- ❌ Ten rows in the product list instead of one. Mitigated by categories
  (Plan 014) and by search.
- ❌ A price change must be repeated ten times. **This is the strongest argument
  against B2** and worth asking about: how often does the price change?

### Option B3 — variants (Plan 010's "bucket B")

The full Size × Colour variant model that Plan 010 deliberately deferred.

- ✅ The correct long-term answer.
- ❌ Much larger than this request. Not for now.

### Recommendation for Case B

**B2 (duplicate-product action) first — it is nearly free — and revisit B1 only
if the shop confirms that per-flavour sales numbers are useless to them.**

The deciding question for the owner: *when you look at the sales report, do you
want to see "juice: 40" or "orange 12, apple 15, mango 13"?*
- One line → B1.
- Per flavour → B2, and the pain is only price updates.

---

## What we must not do

- **Do not simply drop the UNIQUE index** and leave the add-product form as it
  is. The duplicate-barcode mistake is common and the index is the only thing
  catching it today.
- **Do not solve both cases with one mechanism.** "Allow duplicate barcodes"
  makes Case B *worse*: ten juice flavours sharing a chooser sheet would mean a
  chooser popup on every juice sale.
- **Do not write the migration before the branch order is agreed.** The sync
  branch already rewrites this exact index.

---

## Open questions for the owner

1. Cigarettes: when you count them on the shelf, **one pile or two?**
2. Cigarettes: is it always exactly **two** prices, or could it be three?
3. Juice: in the sales report, do you want **one line for juice**, or **one line
   per flavour**?
4. Juice: how often does the price of all the flavours change together?
5. If the app asks "which one?" on every scan of a shared barcode — is one extra
   tap acceptable at a busy counter?
