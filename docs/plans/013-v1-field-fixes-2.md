# Plan 013 — V1 Field-Feedback Fixes, Round 2

> **Status:** 🚧 **IN PROGRESS.** ✅ Wave A shipped and device-verified — items
> **1, 2, 4, 5, 6, 7, 8**. ✅ The **multi-select building block** is shipped too,
> with its first action (bulk price/cost = Plan 015 B2.2); the second action
> (bulk category = Plan 014 step 2) plugs into the same bar. ✅ **#9 categories
> is built** — all three steps of Plan 014, no schema change. ✅ **#11 Case B is
> complete** (duplicate product + bulk price). Remaining: #3, #10, and #11
> **Case A** — the barcode index, still gated on the branch-merge order.
> Source:
> `docs/v1-fixes-2.txt`, 11 items from the shop after more real use. Successor to
> Plan 011 (round 1), same spirit: **mostly papercuts, not new features.**
>
> **But three items are not papercuts** and each has its own plan, because each
> one changes a rule the rest of the app is built on:
>
> | Item | Why it needs its own plan | Plan | Status |
> |---|---|---|---|
> | #3 delete/edit an order, manager-gated | Invoices are **immutable** today, and half the app depends on that | [016](016-manager-lock-and-invoice-edit.md) | ✅ decided |
> | #9 product categories | New data shape; may or may not need a table | [014](014-product-categories.md) | ✅ decided |
> | #11 shared barcodes / flavour variants | Removes a **UNIQUE index** the schema relies on | [015](015-shared-barcodes.md) | ✅ decided |
> | — PIN reset / email accounts | Raised while reviewing #3; changes how a shop is identified | [017](017-accounts-and-pin-reset.md) | 🔬 study |
>
> **Owner's answers (this round), which settled all three:**
> 1. Cigarettes are **two piles** on the shelf → two products sharing a barcode.
> 2. Reports should show **one line per flavour** → separate products, made cheap
>    to create and re-price.
> 3. "Edit order" means **wrong quantity**, or **wrong customer / cash-vs-credit**
>    → build the second as a narrow action; delete-and-re-enter for the first.
> 4. **One category** per product, but **renaming a category must move the
>    products with it**.
> 5. PIN reset → studied in 017; **accounts are not the answer**.
>
> **One shared building block came out of it:** #9 needs multi-select on the
> product list for *bulk category assign*, and #11 needs the same thing for *bulk
> price edit* (ten juice flavours, one price change). **Build the selection once,
> give it two actions.**

---

## Summary table

| # | Item | Size | Schema? | Notes |
|---|---|---|---|---|
| 1 | Reports: "show all low stock" + status filters | S | no | ✅ **SHIPPED** |
| 2 | Search box on the Customers page | S | no | ✅ **SHIPPED** (+ Arabic-aware matching) |
| 3 | Delete order + change payment/customer, PIN-gated | **M** | no | → Plan 016 (quantity edit **rejected**) |
| 4 | "Edit product" straight from the POS scan | S | no | ✅ **SHIPPED** |
| 5 | Delete button instead of `−`, and clear-cart | S | no | ✅ **SHIPPED** (`−` kept, trash added) |
| 6 | **Bug:** QR wins over barcode on the same item | **S — but a real bug** | no | ✅ **SHIPPED** — see below |
| 7 | Smaller camera window in POS | S | no | ✅ **SHIPPED** (0.40 → 0.32) |
| 8 | Share a customer statement as an image | S | no | ✅ **SHIPPED** (image *and* text) |
| 9 | Product categories | **M** | **no** | ✅ **SHIPPED** — Plan 014, all three steps |
| 10 | Low-stock notifications | M | no | **cannot fire while the app is closed** — see below |
| 11 | Two prices/one barcode; many barcodes/one price | **M/L** | **yes (index only)** | Plan 015 — ✅ **Case B shipped**; Case A (index) pending merge order |

**Suggested order**

1. **#6** — it is a bug, and a wrong scan makes the shop distrust everything else.
2. **Small UX batch** — #2, #5, #7, #8, #1, #4. No schema, no decisions left.
3. ✅ **Multi-select on the product list** — the shared building block for #9 and
   #11. **Shipped** with bulk price/cost as its first action. Decisions made
   while building it, so #9 inherits them rather than re-arguing:
   - **Selection is a set of ids, and it survives search/filter changes**
     (Plan 015 B2.3 left this open). Picking six juices under one search and
     four under another is the real job. The cost is that selected rows can be
     off-screen, so the action bar reports how many are hidden.
   - **Select-all means "everything currently visible"**, never the whole
     catalogue — the owner filtered for a reason.
   - Two ways in: long-press (the habit) *and* an app-bar button (long-press is
     invisible to someone who has never tried it).
   - The row's own print/edit/**delete** buttons are hidden while selecting;
     they sit exactly where a finger lands to tick a box.
   - Writes go through a real SQL `UPDATE`, not the usual insert-or-replace:
     replace mints a new rowid, and the list is ordered by rowid, so a bulk edit
     would have shuffled every touched product to the top mid-task.
4. ✅ **#9 categories** (field → tabs → bulk assign → rename propagation) —
   **shipped**; see Plan 014's header for the four decisions taken while
   building that the study had left open.
5. ✅ **#11 Case B** (duplicate product + bulk price) — **shipped**, no schema.
6. **#3** delete invoice → change payment/customer → PIN guard.
7. **#10** notifications, once the "app must be open" limit is agreed.
8. **#11 Case A** (drop the UNIQUE barcode index) — **last**, and only after the
   branch-merge order with `feat/multi-device-sync` is agreed.

---

## #6 — QR is read instead of the barcode ✅ SHIPPED & DEVICE-VERIFIED

> **Verified on a real phone by the owner** — a package with both codes now
> reads the barcode. This is the check that mattered: the whole bug lives in
> what ML Kit hands back per frame, which no host test can reproduce.

**What happens.** Some products carry a printed barcode *and* a QR code on the
same label. The app almost always reads the QR.

**Why.** `HomePage._onDetect` walks `capture.barcodes` and takes the **first**
entry that has a `rawValue`:

```dart
for (final barcode in capture.barcodes) {
  if (barcode.rawValue != null) { … break; }
}
```

One camera frame can contain **both** codes, and ML Kit decides the order of
that list — we never chose. So which code wins is effectively random per frame,
and in practice the QR wins because a QR decodes from more angles and distances
than a 1D barcode does.

**Fix as shipped.** `pickRetailBarcode(List<Barcode>)` in
`core/utils/barcode_formats.dart` — the file that already owns format policy —
picks one code per frame: **the first 1D retail symbology, else the first
usable code of any kind.** Both scanners (`HomePage._onDetect` and
`ScannerPage._onDetect`) now call it instead of walking the list.

- **QR still works alone** — required, not incidental: the app prints its own
  product labels as QR (`LabelImage`) and both screens must read them.
- **Multi-frame confirmation is unchanged**; it runs *after* the pick, on
  whatever was chosen.
- `ScannerPage` matters as much as the POS: it captures the barcode for a **new
  product**, so a wrong pick writes the wrong code into the catalogue
  permanently.
- **`unknown` is a fallback, not a 1D code.** If ML Kit cannot name the
  symbology we cannot claim it identifies a product.
- **`kLinearRetailFormats` must stay a subset of `kRetailBarcodeFormats`** — a
  format preferred but never scanned is a preference that can never fire. The
  test caught exactly that on the first cut (two ITF variants this app does not
  scan); they were removed rather than widening what the scanner decodes, which
  is a separate decision Plan 011 #11 made in the other direction.

**Test** (`test/barcode_pick_test.dart`, 8 cases): the QR is listed **first** in
every fixture, exactly as the failing frames did — that ordering is the bug, so
it is the point of the test.

---

## #1 — Reports: all low stock, and status filters ✅ SHIPPED

> **As shipped:** the low-stock card gained a **"show all"** that navigates to
> the products page **with the filter already applied** (`extra:
> ProductStockFilter.lowStock`), rather than opening a second list — the next
> thing the owner does is reorder or edit, and that lives there. The products
> page gained a chip row (`ProductStockFilter`, a typed enum, not two booleans).
> `lowStock` **excludes** what is already at zero: those have their own chip, and
> a shopkeeper filtering for "running low" wants what to reorder *before* it
> goes. The empty-state warning below was built — an empty low-stock list says
> *"no product has a minimum set yet"* instead of *"no products match"*.

Today `DashboardDao.lowStockProducts({int limit = 5})` shows the worst five and
there is no way to see the rest. Two parts:

1. **"Show all" on the low-stock card** → a full list page (or a bottom sheet)
   with no limit. Reuse `MiniListCard`'s row for consistency.
2. **Quick status filters on the products page** — chips for *all / out of stock
   / low stock*. `Product.isOutOfStock` (`quantity <= 0`) and `Product.isLowStock`
   already exist, so this is a Dart-side filter over the in-memory product list,
   exactly like the attribute filter sheet from Plan 010 V1.2.

**Watch out:** "low stock" only means something when `minStockAlert > 0`, and
most shops never set it. So the *low stock* chip may look empty and broken. The
"out of stock" chip works for everything. Consider showing a one-line hint on an
empty low-stock result: *"no product has a minimum set yet."*

---

## #2 — Search on the Customers page ✅ SHIPPED

> **As shipped:** matching on name **and** phone, and the Arabic note below
> turned out to matter more than the search box. `productMatchesSearch` did
> **not** normalise — it only lower-cased — so the same bug was already shipped
> on the products page: a product saved as `مياه معدنيّة` was unreachable by
> anyone typing `مياه معدنية`. Both now share `normalizeForSearch`
> (`core/utils/arabic_search.dart`), which also maps Arabic-Indic digits to
> Latin so a phone number survives a keyboard change.

The page has no search field. A shop with 200 debt customers scrolls.

- Add a search field in the app bar (the products page pattern).
- Match on **name and phone**, case-insensitive, Dart-side over the existing
  `CustomerBloc` stream — do not add a query.
- Arabic note: matching must ignore the difference between **أ إ آ ا** and
  between **ة / ه**, or half the searches fail. `productMatchesSearch`
  (`features/product/domain/product_search.dart`) is the precedent — check
  whether it already normalises those, and share one helper if it does.

---

## #4 — Edit product from the POS scan

After a scan the cashier sees the line in the cart. If the price or quantity on
the product is wrong, they must leave POS, find the product, edit, come back.

- Add a small edit (pencil) action on the cart line, opening
  `/products/edit/:id` with the `Product` as `extra` (the route already exists).
- On return, the product stream refreshes the catalogue — **but the cart line
  holds a snapshot**. Decide: does the open line pick up the new price?
  Recommended: **yes, re-price the open line**, because the cashier edited it
  *in order to* fix this sale. Anything else looks broken.
- Serialized products: the quantity field is read-only there (Plan 012) — the
  edit page already handles that, no extra work.

---

## #5 — Delete button in the cart, and clear the whole cart

- Replace `−` with a delete action on each cart line, or keep `−` and add a
  trash icon. **Recommendation: keep `−`, add trash.** A `−` that deletes on the
  last unit is a different behaviour than the button says.
- Add "clear cart" in the POS app bar. **Must confirm** — a mis-tap that erases a
  30-line invoice mid-queue is the worst possible outcome in this app.
- `ClearCartEvent` already exists and correctly preserves `exchangeRate` /
  `blockOversell` / `printEnabled`; reuse it, do not emit a bare `BillingState()`.

---

## #7 — Smaller camera window in POS

Pure layout, no logic:

- Reduce the scanner's height so more cart lines are visible while scanning.
- Move or shrink the "review order" (مراجعة الطلب) button — a bottom bar with the
  total and a compact button, instead of a full-width block.
- Keep the inverted-barcode hint chip and the "camera unavailable" card working
  in the smaller box; both are overlays on the scanner and must not overflow.

---

## #8 — Share the customer statement as an image

`CustomerDetailPage` currently shares **text** (`ShareService.shareText`). Make
it an image, like the invoice and cashbox cards.

Everything needed already exists:
- `core/share/widget_capture.dart` (`captureWidgetToPng`),
- `core/share/cards/` — three cards to copy from,
- `ShareService.shareXFiles`.

Add `customer_statement_share_card.dart` rendering the same content
`buildCustomerStatement` produces (header, entries, debit/credit totals, final
balance). **Keep the text share too** — WhatsApp text is searchable and copyable,
and some customers prefer it. Offer both in a small menu.

**Watch out:** a statement can be long. The capture mounts the widget off-screen
at `pixelRatio: 3.0`, so a 200-entry statement becomes a very tall PNG that some
apps refuse. Cap the rendered rows (e.g. last 30 + a "…and N more" line) or
paginate.

---

## #10 — Low-stock notifications ✅ SHIPPED

> **The owner accepted the "app must be open" limit and asked for it to be
> built.** It is stated in the setting's own subtitle, not buried in a doc, so
> nobody discovers it by missing an alert.
>
> Built as designed, plus four decisions the study left open:
>
> - **Off by default, with its own toggle** (Settings → Inventory). The study
>   said `minStockAlert > 0` *is* the opt-in, but a shop sets that threshold to
>   colour the product list; inheriting notifications from it would be a
>   surprise. The toggle is also the one honest moment to request the Android 13
>   notification permission — and a refusal leaves the switch **off**, never
>   on-but-silent.
> - **Turning it on seeds the baseline silently.** "Tell me when something runs
>   low" is about the future; a shop with thirty already-low items must not be
>   handed thirty notifications for agreeing. The current list already lives on
>   the Reports page (#1).
> - **One notification, reused id.** Several products crossing at once give a
>   single "3 أصناف أوشكت على النفاد" rather than three tray entries, and a
>   later alert *replaces* the earlier one. Three separate notices per delivery
>   shortfall is how a channel gets muted at the OS level.
> - **The announced set is only rewritten when it actually changes.** That
>   listener runs on every product write in the app, so persisting an identical
>   set would be a database write per scan.
>
> `LocalNotifier` (`core/notifications/`) was extracted while doing this:
> FCM's foreground display and these alerts post to the **same** Android
> channel, and two definitions of one channel id drift apart with no error to
> notice. `PushNotificationService` now posts through it. ⚠️ **Worth re-testing
> one push** after this change — the behaviour is identical by construction, but
> that path is device-only.
>
> Pinned by `test/low_stock_alert_test.dart` (12 — the pure decision) and
> `test/low_stock_notifier_test.dart` (11 — the wiring).

**Set expectations first: this app does no background work, on purpose.** No
`WorkManager`, no background service — the same decision as `AutoBackupService`
and `SyncScheduler`, for the same reasons (Android background limits, OEM
task-killers, support cost). So:

> A low-stock notification can only appear **while the app is open**, or at the
> moment it is opened. It cannot arrive at 9pm with the app closed.

That is still useful — the cashier is in the app all day — but the owner should
agree to it before we build.

Design:
- Fire on the **transition** into low stock (a sale takes the count to/below
  `minStockAlert`), not on every read. Otherwise every sale of an already-low
  product re-notifies.
- Remember what was already announced (an `AppSettings` key, or a per-product
  timestamp) so restarting the app does not repeat yesterday's alerts.
- Render through the existing `flutter_local_notifications` channel
  (`fawateer_general`) that push already sets up.
- Only for products with `minStockAlert > 0` — the shop opted in by setting it.

**If the owner really wants alerts with the app closed,** the honest options are
(a) the multi-device server sending a push, which needs the sync branch and
backend work, or (b) accepting a background service and its support cost. Both
are much bigger than this item looks.

---

## Cross-cutting notes

- **Branch.** This plan is written against `refactor/architecture-hardening`
  (schema **v15**). The sync branch `feat/multi-device-sync` is at **v18** and is
  not merged. Any item here that adds a migration will collide — see Plan 015 and
  Plan 016, both of which touch schema. Agree the merge order **before** writing
  a migration on either branch.
- **No English in BLoCs.** Every new message is a typed error/enum mapped to ARB
  in the page, per the existing rule.
- **Both locales.** Every new string goes into `app_ar.arb` *and* `app_en.arb`,
  then `flutter gen-l10n`.
- **Tests.** Fakes, not Drift, for BLoC tests; real SQLite only where the query
  itself is what is being tested.
