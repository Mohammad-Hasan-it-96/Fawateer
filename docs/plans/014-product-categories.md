# Plan 014 — Product Categories

> **Status:** 🔬 **STUDY + PROPOSAL.** Source: `docs/v1-fixes-2.txt` #9 —
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
- **Renaming a category.** Values are stored as strings in each product's JSON
  bag. Renaming the option in the definition does **not** rewrite the products —
  they would silently fall out of the category. Either block renaming, or write a
  migration pass over the products. **This is the sharpest edge in Option 1/2 and
  must be handled before shipping.**
- **Arabic sorting.** Category chips should be in the owner's chosen order, not
  alphabetical — Arabic alphabetical order will not match how they think about
  their shelves.

## Open questions for the owner

1. Does one product ever need to be in **two** categories at once? (This single
   answer decides Option 2 vs Option 4.)
2. Roughly how many categories — 5, 20, 100?
3. Do you want to see **sales by category** in reports later? (If yes, that
   pushes towards a real table sooner.)
4. Should the category appear on the printed receipt?
