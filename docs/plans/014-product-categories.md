# Plan 014 — Product Categories

> **Status:** ✅ **DECIDED (owner, this round) — Option 2.**
>
> | Question | Owner's answer | Consequence |
> |---|---|---|
> | Does a product need **two** categories at once? | **No — one category** | Option 4 (multi-select attribute) is not needed. A plain `select` field is enough. |
> | Renaming a category | **Products must follow the rename** | The sharp edge below is **in scope**, not a warning. It has to be built. |
>
> One category per product means the existing attribute engine already holds the
> data correctly. The work is the **tab UI**, **bulk assign**, and **rename
> propagation** — see the build plan at the end.

> **Original study.** Source: `docs/v1-fixes-2.txt` #9 —
> *"study the possibility of adding categories on the products page … two tabs at
> the top (all / by category) … and an easy way to add an existing product to
> certain categories."*
>
> The owner asked for a study, so this weighs the options first. There is a
> cheap answer that may already be 90% of it.

---

## What the shop actually wants

Three things, in order of how often they will be used:

1. **Find a product faster** — filter the list down to "drinks" instead of
   scrolling 300 rows.
2. **Two tabs at the top of the products page** — *All* and *By category*.
3. **Put an existing product into a category easily** — not by editing each
   product one at a time through a form.

Note what is *not* asked for: category-level reports, category pricing, or a
category on the receipt. Keep it that way unless they ask.

---

## Option 1 — a category is just an existing custom field (`select`)

Plan 010 already shipped **dynamic product attributes**: the owner defines
fields, `select` fields have a fixed option list, values live as JSON in
`products.attributes`, the product list already shows `showInList` fields as a
subtitle, and a **filter sheet already filters by `select` options** (AND across
fields, OR within one).

So today, without writing any code, the shop can create a field called
*القسم* of type `select` with options *مشروبات / تنظيف / ألبان …* and filter by it.

- ✅ **Zero schema change, zero migration.** The strongest argument by far.
- ✅ Search already matches attribute values, so typing "مشروبات" works too.
- ✅ Curated seed templates exist (`data/business_templates.dart`) — we could ship
  a ready-made "القسم" template so the shop does not have to invent it.
- ❌ One product gets **one** category (a `select` holds a single value). The
  request says *"add a product to certain categories"* (plural).
- ❌ No dedicated tab UI — it is inside a filter sheet, which is less discoverable
  than two tabs.
- ❌ Bulk-assigning many products still means opening each product.

**This option is the baseline. Any other option must beat it.**

## Option 2 — Option 1 plus a proper tabbed UI and bulk assign

Keep the data in attributes, but build the UX the owner described on top:

- Two tabs on the products page: **الكل** / **حسب التصنيف**.
- The second tab shows category chips (the `select` field's options); tapping one
  filters the list.
- A **multi-select mode** on the product list ("select 12 products → set category")
  so assigning is bulk, not one-by-one.

- ✅ Still no schema change.
- ✅ Delivers all three of the shop's real wants.
- ❌ Still one category per product.
- ❌ The "category" field is discoverable only if we seed it — otherwise the tab
  is empty on a fresh install and looks broken. **Seeding is required for this
  option to make sense.**

## Option 3 — a real `categories` table, many-to-many

`categories` + `product_categories` join table, so one product can be in several.

- ✅ True multi-category.
- ✅ Room to grow (icons, ordering, category reports).
- ❌ **Two new tables, a migration, and — on the sync branch — two more entries in
  `kSyncTables` with sync metadata, tombstones and indexes.** That is a real cost.
- ❌ Duplicates the attribute system for something the attribute system nearly
  does. Plan 010 was explicit about not adding parallel mechanisms.
- ❌ More UI: manage categories, assign, reorder.

## Option 4 — a multi-select attribute type

Add `AttributeType.multiSelect`, storing several values in the same JSON bag.

- ✅ Multi-category **without** new tables — the value is already free-form JSON.
- ✅ Fits the existing filter/search paths with modest changes.
- ❌ Touches the attribute engine (rendering, filtering, search, receipt
  snapshot), which is shipped and used for other things. Regression risk in code
  that is currently quiet.
- ❌ Only worth it if multi-category is genuinely needed.

---

## Recommendation

**Option 2**, in two steps:

1. **Ship a seeded "القسم" `select` field** plus the two tabs and the category
   chips. No migration, and it answers wants #1 and #2 the same week.
2. **Add bulk assign** (multi-select on the product list) — that is want #3, and
   it is the part that actually saves the owner an afternoon.

Then **wait**. If, after real use, the shop keeps asking to put one product in
two categories, revisit **Option 4** (multi-select attribute) — not Option 3. New
tables should be the last resort, especially while a v18 sync branch is waiting
to merge and every new table means new sync plumbing.

---

## Things to get right

- **Empty state.** A "By category" tab with no categories yet must explain how to
  add one and link straight to Settings → Product fields. Otherwise it reads as a
  broken tab.
- **Uncategorised products.** They must not disappear. Show an "أخرى / no
  category" chip; a shop of 300 products will categorise 40 of them and expect to
  still find the other 260.
- **Do not put the category on the receipt** unless asked — `showOnReceipt` is
  already a per-field flag, so this is just a matter of leaving it off by default.
- **Arabic sorting.** Category chips should be in the owner's chosen order, not
  alphabetical — Arabic alphabetical order will not match how they think about
  their shelves.

---

# Build plan (after the owner's answers)

## Step 1 — a seeded "القسم" field + the two tabs

Ship a ready-made `select` definition so the feature is not invisible on a fresh
install (`data/business_templates.dart` is where the curated seeds live). Then the
products page gets **الكل / حسب التصنيف**, the second tab showing the field's
options as chips.

Uncategorised products get an **"أخرى"** chip. A shop with 300 products will
categorise 40 and must still be able to find the other 260.

## Step 2 — bulk assign (multi-select)

Select many products → set their category in one go. This is the part that saves
the owner an afternoon, and doing it product-by-product through the edit form is
what makes people give up on categories.

> ✅ **The selection mechanism already exists** — it shipped with Plan 015 B2.2
> (bulk price/cost) in `product_list_page.dart`. This step is **one more button
> in the existing action bar**, not a new mode:
>
> - `_selectedIds` + `_selectionMode` hold the selection; `_selectionBar` is the
>   bottom bar to add the button to.
> - The selection is a set of **ids** that survives search/filter changes, and
>   the bar already reports how many selected rows are hidden by the filter.
> - Follow the write rule the price edit set: go through a **real `UPDATE`**
>   (`ProductsDao.updatePriceAndCost` is the precedent), not insert-or-replace —
>   replace mints a new rowid and the list is ordered by rowid, so the products
>   you just categorised would jump to the top of the list.
> - Setting a category writes into the **JSON bag**, so it needs its own DAO
>   method rather than reusing the price one.

## Step 3 — rename propagation ⬅️ **required, not optional**

The owner asked for this explicitly, so it is a feature now.

**The problem.** A category value lives as a **string inside each product's JSON
bag** (`products.attributes`). Renaming the option in the definition changes only
the definition. Every product still holds the old string, so they silently leave
the category — the products are not lost, but they vanish from the tab, which
looks exactly like data loss.

**The fix.** Renaming an option becomes one transaction:

1. update the option in the `attribute_definitions` row, **and**
2. rewrite every product whose bag holds the old value.

SQLite has JSON1 bundled (the report group-by already relies on it), so the
rewrite can be a single statement using `json_set` / `json_extract` with the JSON
path as a **bound parameter** — the rule `DashboardDao.salesByAttribute` already
follows. Do it in a transaction with the definition update: a half-done rename is
worse than no rename.

**Watch out:**

- **It is a bulk write.** On the sync branch every touched product gets a new HLC
  stamp and is pushed. Renaming a category on a 300-product shop is a 300-row
  push. Correct, but the owner should not be surprised by the delay.
- **Deleting an option** is the same problem wearing a different hat. Decide:
  block it while products still use it, or move those products to "أخرى". **Do
  not silently orphan them** — that is the failure this step exists to prevent.
- **Merging two categories** (rename "مشروبات" to an existing "عصائر") must work,
  not create a duplicate option.
- This applies to **every `select` field**, not just the category one. Build it in
  the attribute layer and all custom choice-lists get it for free.

## Not doing

- No `categories` table, no join table. One category per product means the
  attribute bag is the right home, and a new table would mean new sync plumbing.
- No `AttributeType.multiSelect`. Not needed by the answer.
- Category **not** on the receipt (`showOnReceipt` stays off by default).

## Still open (small)

- Roughly how many categories — 5, 20, 100? Only affects whether the chips row
  needs to scroll or wrap.
- **Sales by category** in reports? It already works: the Reports "sales by field"
  section groups by any custom field, so choosing القسم gives it with no new code.
