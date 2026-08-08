# Plan 015 — Shared Barcodes and Flavour Variants

> **Status:** ✅ **DECIDED (owner, this round).** Source: `docs/v1-fixes-2.txt` #11.
> The study below stands as the record of *why*; the two answers that settled it:
>
> | Question | Owner's answer | Consequence |
> |---|---|---|
> | Cigarettes — one pile on the shelf or two? | **Two piles** | separate stock ⇒ **Option A1**, two products sharing a barcode. A2 is dead: it shares one stock count. |
> | Juice — report per flavour or one line? | **One line per flavour** | **Option B2**. Keep separate products, make creating and re-pricing them cheap. **No new table.** |
>
> **So the two cases are solved by two different mechanisms, as expected — and
> only Case A needs a migration.**

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

---

# Build plan (after the owner's answers)

## Case A — two products, one barcode (A1)

**Two piles on the shelf means two stock counts, so it must be two product
rows.** That is the answer the data model has to reflect.

### A1.1 — The index

```sql
DROP INDEX idx_products_barcode;
CREATE INDEX idx_products_barcode ON products (barcode) WHERE barcode != '';
```

Still an index (lookup stays fast), no longer `UNIQUE`.

**The guard does not disappear — it moves.** The unique index was the only thing
catching the common "I added this product twice" mistake, and dropping it without
a replacement would trade a rare problem for a frequent one. After this:

- the **add/edit product form still refuses** a barcode that already exists…
- …**unless** the user arrived through the explicit **"add another price for this
  product"** action on an existing product's page.

That action is the whole safety story. A duplicate barcode becomes something the
owner *chose*, never something they *typed by accident*.

### A1.2 — The migration

Additive to the schema, but it **rewrites an index**, so:

- ⚠️ **`_createIndexes()` runs on `onCreate` too** — the `CREATE UNIQUE` line
  there must change as well, or a fresh install and an upgraded install end up
  with different schemas.
- ⚠️ **Leave the de-dup `UPDATE` in place.** It blanks duplicate barcodes on old
  databases before the index is built. It is harmless once the index is
  non-unique, and removing it would break upgrades from v1–v3.
- ⚠️ **The sync branch rewrites this exact index** in its v16→v17 step (narrowed
  to `deleted_at = ''`). Whoever merges second must redo the change there. **Agree
  the merge order before writing either migration.**

### A1.3 — The POS chooser

`ProductsDao.getByBarcode` returns one row today. It becomes "get all matches":

- **1 match** → behave exactly as now. No popup, no extra tap. This is 99% of scans
  and must not get slower.
- **2+ matches** → a compact bottom sheet: product name + price, big tap targets.
  The transient `BillingState` pattern (`measuredPrompt`, `outOfStockScan`) is the
  precedent — **the BLoC never opens UI**, it publishes a prompt and the page
  reacts.
- Show **price and on-hand** in each row. "Which cigarette?" is answered by the
  price, and the count tells the cashier which pile is empty.

### A1.4 — Watch out

- **`getBySerial` fallback** (Plan 012) runs after a barcode miss. Order stays:
  barcode matches → chooser or direct add → else serial → else not found.
- **Label printing** (`LabelImage`) prints the barcode. Two products printing the
  same code is now legal and correct — no change needed, but do not "fix" it.
- **Reports** already group by product id, so the two rows stay separate
  naturally. Nothing to do.

## Case B — one line per flavour (B2)

**No schema change at all.** Two UI additions, and the second one matters more
than it looks.

### B2.1 — "Duplicate this product"

An action on the product list / detail: copy name, price, cost, currency, sale
type, attributes, `minStockAlert`; ask only for the **new name** and **new
barcode**; start `quantity` at 0.

Ten flavours become ten quick confirmations instead of ten full forms.

### B2.2 — Bulk price edit (the real fix)

The owner accepted per-flavour rows knowing the cost: **changing the price means
changing ten products.** That cost has to be paid down, or B2 becomes a daily
annoyance.

Add **multi-select on the product list** → *set price* / *set cost* for all
selected, with a preview of how many rows will change.

> 🔗 **This is the same multi-select mechanism Plan 014 needs for bulk category
> assign.** Build it once, use it for both. Doing it twice would be the mistake.

### B2.3 — Watch out

- Multi-select must not fight the existing search/filter. Selecting *while
  filtered* then clearing the filter should keep the selection — or explicitly
  drop it and say so.
- A bulk price change on the sync branch stamps every touched row with a new HLC
  and pushes them all. Correct, but it means "change 200 prices" is a 200-row
  push. Fine at this scale; worth knowing.

## Order of work

1. **B2.1 duplicate product** — no schema, immediate relief, zero risk.
2. **B2.2 multi-select + bulk price** — shared with Plan 014.
3. **A1** — after the branch-merge order is agreed, because of the index.
