# Plan 010 — Dynamic Product Attributes & Business Customization Platform

> **Status:** ✅ **APPROVED — LEAN V1 (in build).** Owner approved: bucket **A
> only** (descriptive attributes), **curated templates**, **single-attribute
> search**. Explicit steer: *"I don't need a complex application — this app is for
> all simple shops."* So V1 is built as lean as possible.
> **Decisions (as approved):**
> 1. **Scope → bucket A only.** IMEI/Serial (bucket C) and Size×Color variants
>    (bucket B) are **not** built — separate later plans, seams left additive.
> 2. **No `product_attribute_index` table in V1.** Simple shops have small
>    catalogs; attribute **search/filter runs in Dart** over the product list
>    `ProductBloc` already streams into memory. The derived index is a
>    scale-only optimization deferred to V1.5+ (only if a shop runs 10k+ SKUs).
> 3. **Lean `AttributeType` set:** `text`, `number`, `select`, `boolean`, `date`
>    (drop `multiSelect` from V1 — add later, by-name, no migration).
> 4. **Curated seed templates** as a const Dart map, fully editable after seeding.
> 5. **Snapshot printed attributes** on `sales_items` (reprint-eternal rule).
>
> **As built (V1 shipped):** schema **v12→v13** (additive: `products.attributes`
> JSON, `sales_items.attributes_snapshot`, new `attribute_definitions` table);
> `AttributeType` enum + `ProductAttributes` value object + `AttributeDefinition`
> entity; `AttributesDao` + `AttributeDefinitionRepository`; app-wide
> `AttributeDefinitionBloc` (stream-backed, loaded at startup); Settings →
> **Product fields** page (add/edit/archive/delete + template picker); 8 curated
> templates (const map); dynamic add/edit product form; product-list subtitle
> (`showInList`). `flutter analyze` clean; **70 tests** pass (+9 attribute).
> **V1.1 shipped — receipt printing** of `showOnReceipt` attributes: `BillingBloc`
> subscribes to the definitions stream (`_receiptDefs`, always fresh), snapshots
> the resolved `{label: value}` pairs (unit baked in) onto
> `sales_items.attributes_snapshot` in the sale transaction, renders them as
> small RTL sub-lines under each item via `ReceiptImage`, and **reprints** them
> from the frozen snapshot (`HistoryBloc._decodeAttributeSnapshot`) so an old
> receipt is immune to later product/definition edits. Covered by a
> snapshot-flows-and-excludes-non-receipt-fields test.
> **Still deferred:** attribute **search/filter** UI (values are queryable in
> Dart already), report group-by, product labels.
>
> **One-line design:** Hybrid — *typed core columns stay fixed; owner-defined
> descriptive attributes live in a JSON map on the product row, driven by an
> `attribute_definitions` metadata table.* Serialized units and variants are
> explicitly NOT attributes.
>
> Everything below is the full analysis of record; §17 lists the approved answers.

---

## ⭐ The reframe: "custom fields" is three different problems wearing one coat

The brief asks for one thing ("let each business store different product
information") and lists examples that are secretly **three architecturally
distinct problems**. Solving them with one mechanism is the trap. Sort every
example in the brief into these buckets first — the whole design follows from it:

| Kind | Examples from the brief | Cardinality | Right model |
|---|---|---|---|
| **A. Descriptive attribute** (per-SKU) | Color, Storage, Material, CPU Gen, RAM, Voltage, Volume, Concentration, Gender, Brand, Warranty (as a label) | **one value shared by all units** of the product; `quantity` can be > 1 | **JSON attribute bag + definitions** (this plan, V1) |
| **B. Variant-defining attribute** (per-SKU, combinatorial) | Clothing **Size × Color**; shoe size; phone **Storage × Color** *when each combo has its own price/stock/barcode* | each **combination is its own sellable SKU** with its own stock, price, barcode | **Product variants / parent-child SKUs** (later plan — *not* a JSON field) |
| **C. Unit-level serial identity** (per-physical-item) | **IMEI**, **Serial Number**, Battery Health (per handset) | **unique per physical unit**; `quantity` is effectively always 1; you must answer *"which invoice sold this exact IMEI, and is it under warranty?"* | **Serialized inventory (`product_units`)** (later plan — *not* a JSON field) |

Why this matters and why it is non-negotiable:

- **`Product` today is a SKU with a `quantity` and is found by a single unique
  `barcode` (`ProductsDao.getByBarcode` → one row).** IMEI and Serial Number are
  **not descriptions of a SKU** — they identify one physical handset. A phone
  shop selling five "iPhone 15 128GB Black" holds **one SKU, five IMEIs**. If you
  store IMEI as a JSON attribute on the product row you get exactly one IMEI slot
  for five phones — the data model is wrong on day one, and warranty/serial
  lookup (an explicit future requirement) is impossible.
- **Variants** (Size×Color) multiply into a **matrix of SKUs**, each with its own
  stock and barcode. Cramming them into a JSON field means the shop can't answer
  "how many size-L red shirts are left?" or scan a size-specific barcode — the
  two things a clothing shop needs most.
- Everything **else** in the brief — Color (as a label), Storage, Material, CPU
  Gen, Voltage, Volume, Concentration, Gender, Brand — genuinely *is* a per-SKU
  description. **That, and only that, is what a dynamic-attribute system should
  solve.** It is also ~80% of the requested value and ships fast.

**So the honest scope of "Plan 010" is bucket A.** Buckets B and C are named,
designed-for at the seams, and deferred — with the data model shaped so adding
them later is additive, never a rewrite. Pretending one JSON bag covers all
three is the mistake this document exists to prevent.

---

## 1. Problem analysis (first principles)

What must be true for the *real* need (bucket A) to be met:

1. **Zero schema change per business.** A perfume shop adding "Concentration"
   must not require a `flutter` release, a migration, or a `build_runner` run.
2. **Owner-authored, no code.** Definitions are data the shopkeeper edits in-app.
3. **Offline-first & Drift-native.** No server, no exotic SQLite features that
   aren't in `sqlite3_flutter_libs`. Everything works on a plane.
4. **Fast at 10k–50k products.** The product list, barcode scan, and checkout are
   hot paths tapped hundreds of times a day. Attribute storage must not slow the
   universal path (name/price/stock/barcode) *at all*.
5. **Snapshot-honest.** Fawateer's iron rule: a reprinted invoice must look
   identical forever (`sales_items` snapshots `productName`/`price`/`cost`/
   `fxRate`/`discount`). Any attribute printed on a receipt must be **snapshotted
   at sale time**, never re-read from a product that may since be edited/deleted.
6. **Arabic-first RTL**, and every label localizable — but attribute labels are
   **user data** (the owner types "اللون"), so they are *not* ARB strings; only
   the platform chrome around them is.
7. **Search must be honest about cost.** "Search by IMEI/Size/Color" sounds
   uniform but spans all three buckets; only bucket-A search belongs here, and
   only for attributes the owner opts into indexing.

The tension: **flexibility vs. query performance vs. simplicity.** Every option
below is really a different point on that triangle. The current fixed schema
maxes performance+simplicity and zeroes flexibility. Full EAV maxes flexibility
and craters the other two. The winning design refuses to pick one corner.

---

## 2. Architecture comparison

Scored ✅ good / 🟡 tolerable / ❌ bad, against the brief's criteria.

| Criterion | A. Fixed cols | B. Extra1..N | C. Attr defs + **JSON** *(core of pick)* | D. Full EAV | E. Pure JSON (no defs) | F. Templates only |
|---|---|---|---|---|---|---|
| Simplicity (code) | ✅ | ✅ | 🟡 | ❌ | ✅ | 🟡 |
| Add business w/o migration | ❌ | 🟡 (until full) | ✅ | ✅ | ✅ | ❌ |
| Performance — hot path | ✅ | ✅ | ✅ (core cols untouched) | ❌ (joins) | 🟡 | ✅ |
| DB complexity | ✅ | 🟡 | 🟡 (1 col + 2 small tables) | ❌ | ✅ | 🟡 |
| Drift compatibility | ✅ | ✅ | ✅ (TextColumn + normal tables) | 🟡 | ✅ | ✅ |
| Offline | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Searching (indexed) | ✅ | ❌ (opaque cols) | ✅ (via derived index) | ✅ | ❌ (`json_extract` scan) | ✅ |
| Filtering (multi-attr) | ✅ | ❌ | 🟡→✅ (index table) | 🟡 (N self-joins) | ❌ | ✅ |
| Reporting | ✅ | ❌ | 🟡 (index/JSON aware) | 🟡 | ❌ | ✅ |
| Barcode lookup | ✅ (unaffected) | ✅ | ✅ (unaffected) | ✅ | ✅ | ✅ |
| Printing | ✅ | 🟡 | ✅ (JSON → snapshot) | 🟡 | 🟡 | ✅ |
| Inventory | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Future maintenance | ❌ (col creep) | ❌ (opaque) | ✅ | 🟡 | 🟡 (no schema of attrs) | 🟡 |
| Scalability (business types) | ❌ | ❌ | ✅ | ✅ | ✅ | 🟡 |
| Data migration | ❌ (every type) | 🟡 | ✅ (additive once) | ✅ | ✅ | 🟡 |
| UX (dynamic form) | ❌ | ❌ (no metadata) | ✅ (defs drive form) | ✅ | ❌ (no metadata) | ✅ |

**Read of the table.** A and B fail the core requirement (they *are* the current
problem, dressed up). D (full EAV) is the "correct-sounding" academic answer and
the classic senior-engineer trap: it is maximally flexible and **operationally
miserable** — every product read becomes a fan-out join, multi-attribute filters
become N self-joins, and it's the historical #1 cause of slow POS databases.
E (pure JSON, no definitions) can't generate a form or validate — the owner gets
a free-text soup. F (templates only) is rigid the moment a shop wants one field
the template lacks.

**The only option that holds every column without a ❌ is C — but only when you
split JSON's two jobs:**
- **Storage & display** of *all* attributes → **JSON map on the product row**
  (source of truth, trivially printable, zero-migration, one column).
- **Search & filter** of the *few* attributes the owner marks searchable →
  a **derived, disposable index table** (a *scoped* EAV that only ever holds
  opted-in attributes, so it never grows to full-EAV pain).

This is the same shape Shopify (metafields), WooCommerce, and Odoo converged on,
for the same reasons. It's "Option G": **Hybrid = typed core + JSON bag +
definitions + selective derived index.**

---

## 3. Recommended architecture (the Hybrid)

Four pieces. The first two are the whole of V1's data model; the third is the
performance layer; the fourth is onboarding.

### 3.1 `attribute_definitions` — the metadata that drives everything

The owner's "schema," stored as data. One row per custom field:

| field | purpose |
|---|---|
| `id` (text) | stable key, e.g. a slug `storage` / uuid |
| `label` (text) | what the owner typed — **user data, Arabic**, e.g. "السعة" |
| `type` (text, **by name**) | `AttributeType` enum name — see below |
| `unit` (text, nullable) | e.g. `GB`, `ml`, `V` (display suffix) |
| `options` (text JSON array, nullable) | for `select` types: `["أحمر","أزرق"]` |
| `isRequired` (bool) | form validation |
| `isSearchable` (bool) | **opt-in** → feeds the derived index (§3.3) |
| `showOnReceipt` (bool) | printed on invoices/labels (snapshotted) |
| `showInList` (bool) | shown as a subtitle in the product list |
| `sortOrder` (int) | form/field order |
| `isArchived` (bool) | soft-hide without destroying historic values |

`AttributeType` is an **extensible enum persisted by name** (same discipline as
`ProductSaleType`/`PriceCurrency`/`CashTransactionType` — never by index, so
reordering can't remap rows; unknown decodes to `text`). This matches the house
preference for extensible enums over booleans. Cases: `text`, `number`,
`select` (single-choice from `options`), `multiSelect`, `boolean`, `date`.
Room to grow (`color`, `barcodeRef`) with no migration. Each type maps to one
form widget and one validator.

### 3.2 `products.attributes` — the JSON bag (source of truth)

**One additive `TextColumn get attributes` on `Products`**, holding a JSON object
`{ "<definitionId>": <value>, ... }`. Nullable/empty for products with no custom
data (every existing row decodes as "no attributes" — additive, no backfill).

- Values are stored **keyed by definition id**, not label, so renaming a label
  ("Colour"→"Color") never orphans data.
- Numbers stored as JSON numbers, dates as ISO-8601 strings, selects as the
  option string, multiSelect as a JSON array. Parsing is centralized in one
  `ProductAttributes` value object (`core/attributes/`), so `null`/legacy/garbled
  JSON decodes to empty and never throws — same defensive posture as
  `NumInput.parseFlexibleNumber` and the by-name enum `fromName` fallbacks.
- **The hot path is untouched.** `name`, `price`, `cost`, `quantity`, `barcode`,
  `saleType`, `priceCurrency` stay as typed columns. The product list, checkout,
  and `getByBarcode` never read `attributes` unless a screen asks for it. This is
  the whole performance argument: EAV's cost is that *every* read pays for
  attributes; here only attribute-aware screens do.

### 3.3 `product_attribute_index` — the derived search layer (the clever bit)

The one real weakness of JSON is that `json_extract(...)` can't use a normal
index, so filtering 50k products by an attribute is a full scan. We fix that
**without** paying full-EAV cost by indexing **only** attributes flagged
`isSearchable`:

| field | notes |
|---|---|
| `productId` (text) | FK-ish link to the product |
| `definitionId` (text) | which attribute |
| `valueText` (text, nullable, **collated/normalized**) | for text/select search |
| `valueNum` (real, nullable) | for number/date-range filters |

- Populated/updated **in the same transaction** as any product write, derived
  purely from the JSON + definitions. It is **disposable**: it can be dropped and
  fully rebuilt from the JSON at any time (e.g. after a restore, or when an
  attribute is newly marked searchable). Single source of truth stays the JSON.
- Indexed by `(definitionId, valueText)` and `(definitionId, valueNum)` →
  indexed equality and range queries. A shop typically marks 1–3 attributes
  searchable (Size, Color), so this table stays a small fraction of full EAV.
- Text is stored normalized (Arabic-digit-folded, trimmed, lower-cased) so search
  matches the way `parseFlexibleNumber` already normalizes input.

**Why not skip the index and use `json_extract`?** Fine at a few hundred
products; a visible stutter at 20k when you filter. Building the index is cheap
insurance and keeps the "fast even with tens of thousands of products"
requirement honest. **Why not expression/generated columns per attribute?**
Because that reintroduces per-attribute migrations — the exact thing we're
eliminating.

### 3.4 Templates = seed data, not a type system (see §7)

A one-time onboarding picker that **inserts a starter set of
`attribute_definitions`**. After that, everything is fully editable. Templates
are convenience, never a constraint.

### 3.5 Where buckets B & C plug in later (designed-for, not built)

- **Serialized units (C):** a future `product_units` table (`productId`, `serial`
  /`imei`, `status`, `soldInvoiceId`, `warrantyUntil`). Barcode/IMEI scan gains a
  second lookup path (`getByBarcode` → falls through to `getUnitBySerial`). The
  sale line references the *unit*, not just the SKU. **Nothing in the Hybrid
  blocks this**; `attributes` and `product_units` coexist.
- **Variants (B):** a future `parentProductId` on `Products` (self-reference) +
  a variant-matrix editor; each variant is a normal product row (own stock/
  barcode/price) that *reuses* the same attribute machinery for its defining
  axes. Again additive.

---

## 4. Database proposal (Drift, schema v12 → v13)

Fully additive — fits the "addColumn + new tables, no table rebuild" history.

- **New column:** `Products.attributes` — `TextColumn get attributes =>
  text().withDefault(const Constant(''))()`. `addColumn` in `onUpgrade`; every
  existing row decodes as empty.
- **New tables:** `AttributeDefinitions`, `ProductAttributeIndex`. Created in
  `onCreate` and in the `if (from < 13)` block. Purely additive — no existing
  table touched (same pattern as ledger v6→v7, cashbox v8→v9).
- **New indexes** via a new idempotent `_createAttributeIndexes()`
  (`CREATE INDEX IF NOT EXISTS` on `product_attribute_index(definition_id,
  value_text)` and `(definition_id, value_num)`), called from `onCreate` and the
  v13 step — mirroring `_createLedgerIndexes()`/`_createCashboxIndexes()`.
- **Snapshot column on `sales_items`:** add `attributesSnapshot` (`TextColumn`,
  JSON, default `''`) holding the *printed* attributes resolved at sale time.
  Additive; old rows decode as none. This is what keeps reprints eternal.
- **Bump `schemaVersion` 12 → 13**, append **one** `if (from < 13)` block. No
  `TableMigration`/rebuild. `PRAGMA foreign_keys` guidance unchanged (we keep the
  index link as a plain column, no declared FK, matching current practice).
- **`AppSettings` key** `attributes_template_applied` (or store the chosen
  template id) so onboarding runs once — reuses the existing key-value table, no
  new table for a one-shot flag (house pattern).

DAO surface: a new `AttributesDao` (`@DriftAccessor` over the two new tables +
`Products` so it can maintain the index in the product write transaction),
alongside the existing `ProductsDao` (which stays lean).

---

## 5. Clean Architecture changes

Follows the existing per-feature layout; **no new use-case layer** (house rule —
BLoCs call repositories directly).

- **Entities** (`core/attributes/` for shared value objects; a small
  `features/attributes/` for definition CRUD):
  - `AttributeDefinition` (Equatable), `AttributeType` (extensible enum, by-name).
  - `ProductAttributes` — a value object wrapping `Map<String, dynamic>` with
    typed getters, `toJson`/`fromJson`, and defensive parsing. **`Product` gains
    one field:** `final ProductAttributes attributes` (default empty). Keeps
    `Product` immutable/Equatable; `copyWith`/`props` extended.
- **Repositories** (`Either<Failure, T>`):
  - `AttributeDefinitionRepository` — watch/add/update/archive/reorder defs.
  - `ProductRepository` — extended so writes persist JSON **and** refresh the
    derived index in one transaction; adds `searchByAttribute(defId, value)` /
    `filter(criteria)` returning products.
- **BLoCs** (factories via GetIt, registered after their repos — strict DI order):
  - `AttributeDefinitionBloc` (manage the schema; Settings → "Product Fields").
  - `ProductBloc` extended: the add/edit form loads definitions to render fields;
    list/search gains an attribute filter. No new app-wide BLoC needed if we
    scope definition-management to its settings route (precedent: `BackupBloc`).
- **DI order** (`service_locator.dart`): `AppDatabase` → `AttributesDao` →
  `AttributeDefinitionRepository` (+ extended `ProductRepository`) → BLoCs.
- **Failures:** reuse `CacheFailure`; add `ValidationFailure` only if a typed
  validation error must reach the UI (else keep validation in the form layer per
  the existing `AppValidators` pattern). **No user-facing English in BLoCs** —
  typed errors → ARB via a mapper, as everywhere else.

---

## 6. UX proposal (must feel like *fewer* decisions, not more)

The risk of any customization feature is that it turns a 30-second "add product"
into a config project. The design is defensive about that.

**6.1 Onboarding (once).** First run (or Settings → Business Type): a friendly
picker — *"What kind of shop is this?"* → Mobile / Laptop / Clothing / Grocery /
Pharmacy / Hardware / Perfume / **General**. Picking one seeds
`attribute_definitions`. "General" seeds nothing. **Skippable**, **reversible**,
never blocks selling. Grocery/General owners never see an attribute in their life.

**6.2 Managing fields (Settings → "Product Fields / حقول المنتج").** A simple
list: each row = label + type + toggles (Required / Searchable / On receipt / In
list). Add/edit/reorder/archive. This is the only "advanced" screen and most
owners open it zero times after onboarding.

**6.3 Add/Edit Product — the dynamic form.** Below the fixed fields (name, price,
cost, qty, barcode) render one widget per **active** definition, ordered by
`sortOrder`:
- `text`→`TextFormField`; `number`→numeric field reusing `NumInput` formatters +
  `parseFlexibleNumber`; `select`→dropdown/chips from `options`;
  `multiSelect`→chip multiselect; `boolean`→switch; `date`→date picker.
- Required-field validation reuses `AppValidators`. Empty optional fields simply
  aren't written to the JSON (no null pollution).
- **Collapsible "Details" section** so a phone shop with 6 fields doesn't bury
  the price. Fixed commercial fields always sit above the fold.

**6.4 Product detail & list.** Detail page shows attributes as a clean label/
value list. The product list shows only `showInList` attributes as a subtitle
(e.g. "128GB · أسود") — keeps the list scannable.

**6.5 Guardrails.** Deleting a definition with historic values is **soft-archive**
(hidden from forms, preserved on old products/receipts) — same philosophy as the
customer delete-guard and cashbox source-owned reversal. Hard delete only when no
product uses it.

---

## 7. Business templates — yes, as seeds only

**Recommendation: ship templates, but they are pure seed data.** They lower the
blank-page cost (a phone-shop owner shouldn't have to invent "IMEI/Storage/Color"
from nothing) *without* becoming a rigid taxonomy. After seeding, the owner
adds/removes/renames freely; there is no "type lock." Ship ~6–8 curated templates
(Mobile, Laptop, Clothing, Grocery=empty, Pharmacy, Hardware, Perfume, General)
as a **const Dart map**, not a table — they're app assets, versionable, no
migration. Re-picking a template *offers to merge* new suggested fields, never
wipes the owner's edits.

**Note the seams:** the *Mobile* template will *want* IMEI, and *Pharmacy* will
want batch/expiry — but IMEI is bucket C and expiry is a per-batch concern. V1
templates seed the **descriptive** fields (Color, Storage, Warranty-as-label) and
we hold IMEI/Serial/Expiry for the serialized/batch plan so we don't ship a
half-working IMEI field that can't do warranty lookup.

---

## 8. Search & filtering

Honest, per bucket:

- **Product search (in-app):** searchable text/select attributes join through
  `product_attribute_index` → indexed. Number/date attributes get range filters.
  A "Filters" sheet on the product list exposes only `isSearchable` attributes.
- **Barcode search:** **unchanged** — still `getByBarcode` on the typed column.
  (IMEI/serial scanning is bucket C and arrives with `product_units`; until then,
  scanning an IMEI is out of scope — say so, don't fake it with a JSON scan.)
- **Invoice/audit search:** the audit center currently searches invoice id +
  customer name (`sales_dao` `i.id LIKE ? OR c.name LIKE ?`). We can extend it to
  match `sales_items.attributesSnapshot` (e.g. find the invoice that sold a given
  serial *once C lands*), but **V1 leaves audit search as-is** — attribute
  invoice search is a V1.5 nicety, and doing it right needs the snapshot column
  we're adding now.
- **Reports/inventory:** dashboard aggregates stay on typed columns; grouping a
  report *by* an attribute (e.g. revenue by Brand) is a clean V1.5 extension of
  `DashboardDao` using the index table — **explicitly deferred** so V1 dashboard
  math is untouched (keep the profit-SQL parity rule intact).

**Rule:** an attribute participates in search **only** if the owner flags it
`isSearchable`. No silent full-table `json_extract` scans on the hot path.

---

## 9. Printing

- **Configurable, not always-on.** Only `showOnReceipt` attributes print — a
  cashier doesn't want "Battery Health: 87%" on every grocery receipt.
- **Snapshot discipline (load-bearing).** At sale time, resolve the printed
  attributes into `sales_items.attributesSnapshot` (JSON of label:value pairs,
  in the sale transaction, alongside `price`/`cost`/`discount`). Reprints read the
  snapshot, **never** the live product — so a receipt reprints identically even
  after the product/definition is edited or archived. This is the same rule that
  already governs `productName`/`fxRate`/`discount`.
- **Rendering:** attributes are Arabic → they must ship as **pixels** through the
  existing `ReceiptImage.buildTextEscPosBytes` raster path (the plain-text ESC/POS
  path renders Arabic as `?`). `ReceiptLine` gains an optional attribute block;
  no new print technique.
- **Labels/QR (future):** product **labels** (barcode + a couple of attributes)
  and QR are a natural V1.5 using the same raster path + `captureWidgetToPng` for
  richer labels. Deferred.

---

## 10. Future compatibility — where each future feature lands

| Future ask (from brief) | Lands as | Needs redesign? |
|---|---|---|
| IMEI warranty tracking | Bucket **C** `product_units` (+ `warrantyUntil`) | No — additive table |
| Serial number lookup | Bucket **C** second scan path | No |
| Product variants | Bucket **B** `parentProductId` + matrix editor | No — reuses attributes |
| Batch numbers | `product_batches` table (per-batch qty) | No |
| Expiration dates | per-batch date (with batches), or a `date` attribute for simple cases | No |
| QR codes | render path already exists; label plan | No |
| AI search | index table + JSON already give structured, queryable data | No |
| Advanced reports | group-by over `product_attribute_index` | No |

The Hybrid is deliberately the substrate all of these sit on top of, additively.

---

## 11. Business rules

1. **Attributes never affect money.** They are descriptive metadata; `price`/
   `cost`/`quantity`/discounts/FX are untouched. (Money stays `double`, house rule.)
2. **Definition ids are immutable and by-key**; labels are editable free text.
3. **By-name enum persistence** for `AttributeType`; unknown → `text`.
4. **Derived index is disposable**; JSON is the single source of truth; both are
   written in one transaction.
5. **Snapshot printed attributes**; reprints never read live product data.
6. **Soft-archive** definitions with history; hard-delete only when unused.
7. **Selling never blocks on attributes** — a required attribute blocks *saving a
   product*, never *making a sale* (the checkout path stays untouched, consistent
   with "overselling allowed by default").
8. **No PII/regulated data as a casual attribute** — templates won't seed fields
   that invite storing customer IDs on products.

---

## 12. Migration plan

1. Schema **v12→v13**: add `Products.attributes`, `SalesItems.attributesSnapshot`,
   two new tables, `_createAttributeIndexes()`. One additive `onUpgrade` block.
2. **No data backfill** — existing products decode as "no attributes." The index
   table starts empty and is populated lazily as products are edited (or by a
   one-time background rebuild if an attribute is marked searchable).
3. `build_runner` regenerate (`*.g.dart`) — the only reason this needs codegen.
4. **Restore-safe:** after a Drive restore, the index rebuilds from JSON (it's
   derived), so a restored DB with a different searchable set self-heals.
5. Rollout behind onboarding: existing installs see the business-type picker once;
   choosing "General"/skipping is a complete no-op — **zero disruption** to
   current grocery-style users.

---

## 13. Risks & mitigations

| Risk | Severity | Mitigation |
|---|---|---|
| Owners try to store IMEI/Size as attributes → wrong model, no warranty/variant support | **High** | The reframe (§0): don't seed IMEI/Serial as attributes in V1; ship buckets B/C properly rather than a broken JSON stand-in |
| JSON search slow at scale | Med | Derived index table for searchable attrs; hot path never touches JSON |
| Index drifts out of sync with JSON | Med | Write both in one transaction; index is disposable & rebuildable |
| Receipt shows stale attribute after edit | Med | Snapshot on `sales_items` (same rule as price/name) |
| Feature bloat / form complexity scares grocery owners | Med | "General"=empty; collapsible Details; attributes fully optional |
| Definition delete destroys history | Med | Soft-archive; preserve on old products/receipts |
| Migration adds a table rebuild | Low | Design is `addColumn` + new tables only — no `TableMigration` |
| Localization of user-typed labels | Low | Labels are user data, not ARB; only chrome is localized |
| Scope creep into variants/serial during V1 | **High** | Hard scope line in this doc; B & C are separate approved plans |

---

## 14. Alternatives considered & rejected

- **Full EAV (D):** rejected as the primary store — join-heavy reads, N-self-join
  filters, the canonical slow-POS pattern. We use a *scoped, derived* slice of it
  only for opted-in search, which is where EAV is actually fine.
- **Pure JSON, no definitions (E):** rejected — can't generate a form, validate,
  or drive search; degrades to free-text soup.
- **Extra1..Extra10 columns (B):** rejected — opaque, unsearchable, still a
  ceiling; it's the current problem with a fig leaf.
- **Per-attribute generated/expression columns:** rejected — reintroduces
  per-attribute migrations, defeating the goal.
- **Templates-only, no free fields (F):** rejected — rigid the instant a shop
  wants one field the template lacks.
- **Server-driven schema:** rejected — violates offline-first; app has exactly
  one network feature (licensing) and this must not become the second.

---

## 15. Final recommendation

Ship the **Hybrid**: **`attribute_definitions` (metadata) + `products.attributes`
(JSON source of truth) + `product_attribute_index` (derived, opt-in search) +
curated seed templates**, with **serialized units (IMEI/Serial) and variants
(Size×Color) explicitly carved out into their own later plans.** It is the only
option that satisfies every criterion without a hard ❌, stays Drift-native and
offline, keeps the hot path at fixed-column speed, migrates additively (v12→v13,
no rebuild), and — most importantly — is the correct *substrate* for the future
serial/variant/batch/report features rather than a dead-end that fights them.

**What makes this the 5–10-year answer** is not the JSON column (that's the easy
part) — it's **refusing to model IMEI and Size as attributes**. That single
boundary is what prevents a v2 rewrite.

---

## 16. Implementation roadmap

**V1 — "Custom Product Fields" (ships fast, ~the size of Plan 007/008):**
1. Schema v13 (column + 2 tables + snapshot col + indexes) + `build_runner`.
2. `AttributeType` enum, `ProductAttributes` value object, `AttributeDefinition`
   entity, `AttributesDao`, repositories.
3. Settings → "Product Fields" CRUD (`AttributeDefinitionBloc`).
4. Onboarding business-type picker + seed templates (const map).
5. Dynamic add/edit form; product detail + list subtitle.
6. Single-attribute indexed search + product-list filter sheet.
7. `showOnReceipt` snapshot + raster receipt rendering.
8. Tests: attribute parse/validate (pure, like `num_input_test`), and a
   `ProductBloc`/repo test against a fake repo (house testing rule).

**V1.5 — extensions (no schema pain):** multi-attribute filters, report group-by
attribute, attribute-aware audit/invoice search, product labels + QR.

**V2 — the carved-out buckets (separate approved plans):**
- **Plan 011? Serialized inventory (bucket C):** `product_units`, IMEI/serial
  scan path, warranty tracking, "which invoice sold this unit."
- **Plan 012? Product variants (bucket B):** `parentProductId`, variant matrix,
  per-variant stock/barcode/price.
- Batch numbers & expiry (pharmacy/bakery) ride on the serialized/batch work.

---

## 17. Open decisions for sign-off (before any code)

1. **V1 scope line:** confirm bucket A only (descriptive attributes), with IMEI/
   Serial (C) and Size×Color variants (B) as separate later plans. *(Strong
   recommend: yes — this is the core thesis.)*
2. **Templates:** ship curated seed templates vs. blank-canvas only. *(Recommend:
   curated seeds, fully editable.)*
3. **Onboarding placement:** first-run picker vs. purely Settings-driven.
   *(Recommend: gentle first-run picker, skippable.)*
4. **Search in V1:** single-attribute indexed search now, or defer all attribute
   search to V1.5? *(Recommend: single-attribute now — it's cheap given the index
   table and is the headline "search by Color/Size" ask.)*
```
