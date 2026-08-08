# Plan 013 — V1 Field-Feedback Fixes, Round 2

> **Status:** 📋 **PROPOSED — awaiting owner sign-off.** Source:
> `docs/v1-fixes-2.txt`, 11 items from the shop after more real use. Successor to
> Plan 011 (round 1), same spirit: **mostly papercuts, not new features.**
>
> **But three items are not papercuts** and each has its own plan, because each
> one changes a rule the rest of the app is built on:
>
> | Item | Why it needs its own plan | Plan |
> |---|---|---|
> | #3 delete/edit an order, manager-gated | Invoices are **immutable** today, and half the app depends on that | [016](016-manager-lock-and-invoice-edit.md) |
> | #9 product categories | New data shape; may or may not need a table | [014](014-product-categories.md) |
> | #11 shared barcodes / flavour variants | Removes a **UNIQUE index** the schema relies on | [015](015-shared-barcodes.md) |
>
> The owner's own note on #11 — *"this last problem needs study of the best
> options and suggestions before any decision"* — applies to all three.

---

## Summary table

| # | Item | Size | Schema? | Notes |
|---|---|---|---|---|
| 1 | Reports: "show all low stock" + status filters | S | no | `lowStockProducts` is already capped at 5 |
| 2 | Search box on the Customers page | S | no | page has no search at all today |
| 3 | Delete / edit an order, manager-gated | **L** | maybe | → Plan 016 |
| 4 | "Edit product" straight from the POS scan | S | no | |
| 5 | Delete button instead of `−`, and clear-cart | S | no | |
| 6 | **Bug:** QR wins over barcode on the same item | **S — but a real bug** | no | confirmed in code, see below |
| 7 | Smaller camera window in POS | S | no | pure layout |
| 8 | Share a customer statement as an image | S | no | infrastructure already exists |
| 9 | Product categories | **M/L** | likely | → Plan 014 |
| 10 | Low-stock notifications | M | no | **cannot fire while the app is closed** — see below |
| 11 | Two prices/one barcode; many barcodes/one price | **L** | **yes** | → Plan 015 |

Suggested order: **#6 first** (it is a bug, and it makes the shop distrust every
scan), then the small UX batch (1, 2, 4, 5, 7, 8), then 10, then the three
design items.

---

## #6 — QR is read instead of the barcode (a real bug, confirmed)

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

**Fix.** Inside one capture, prefer a **1D retail symbology** over a 2D one:

```dart
// One frame can hold both a printed barcode and a QR label. Retail 1D codes
// identify the *product*; a QR on the same package is usually a marketing or
// warranty link that means nothing to this shop. So 1D wins, always — and
// only when the frame has no 1D code at all do we fall back to the QR, which
// is what the app's own printed QR labels need.
```

- Keep the multi-frame confirmation exactly as it is — it runs *after* the pick.
- QR must still work alone: the app prints its own product QR labels
  (`LabelImage`), and the sync join code is a QR.
- Cost: about 10 lines in `_onDetect`, plus the same pick in `ScannerPage` so
  the add-product scan behaves identically.

**Test:** a fake `BarcodeCapture` holding `[qrCode, ean13]` in that order must
produce the EAN-13. That ordering is the whole bug, so the list order in the
fixture is the point of the test.

---

## #1 — Reports: all low stock, and status filters

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

## #2 — Search on the Customers page

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

## #10 — Low-stock notifications

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
