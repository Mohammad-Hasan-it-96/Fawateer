# Plan 011 — V1 Field-Feedback Fixes Roadmap

> **Status:** 📋 **PROPOSED — awaiting owner sign-off.** Source: a shopkeeper's
> field notes after real use (`docs/v1-fixes.txt`, 11 items) plus two reference
> photos (a rival barcode app *Super CodeReader*; a printed wholesale invoice
> whose column layout is the target for item #10). This is a **polish/UX batch**,
> not a new feature — every item is a small, mostly self-contained change on top
> of shipped code. No schema migration is required for 10 of the 11 items
> (item #5 optionally adds one).
>
> **One-line framing:** *the app works; these are the papercuts a real cashier
> hit in the first week.* Speed-of-checkout and "don't make me hunt the shelf"
> dominate the list — treat those as the priority signal.
>
> **✅ Wave A shipped** (items 3, 4, 5, 7): empty add-product defaults; scanned/
> added item jumps to the top of the cart (re-scan bumps qty + moves up);
> products list is newest-first (`rowId desc`, no migration); notification
> durations halved via a shared `AppSnackDuration` (`core/utils/app_snack.dart`).
> Decision taken on #4: a re-scan of an existing line **does** move it to the top.
>
> **✅ Wave B shipped** (items 8, 10 — which subsumes 2):
> - **#8 out-of-stock visibility.** `Product.isOutOfStock` = `quantity <= 0`
>   (not gated on `minStockAlert` — the shop wants zero flagged for every
>   product). The product-list stock row is shown for every row (a `Wrap`, so the
>   badge can't overflow a narrow card) with a red "out of stock" chip that
>   supersedes the amber low-stock one; scanning a finished item still adds it
>   (overselling stays allowed) but fires a red notice via a transient
>   `BillingState.outOfStockScan` + `ClearOutOfStockScanEvent`.
> - **#10 invoice-as-table.** Both the checkout review and the invoice detail page
>   now render the 6-column layout from the owner's wholesale-invoice photo:
>   م / الصنف / الكمية / الوحدة / الإفرادي / الإجمالي. *(Unit fidelity was
>   initially inferred; **resolved** by the v13→v14 snapshot below.)*
>
> `flutter analyze` clean; **95 tests** pass (+2 cart-order, +2 out-of-stock).
> New ARB keys: `colSerial/colQty/colUnit/colUnitPrice/unitPiece`,
> `outOfStockBadge`, `outOfStockScanNotice`.
>
> **✅ Wave C shipped** (items 1, 6):
> - **#1 app-wide font size.** `FontScaleController` (mirrors `ThemeController`) +
>   `AppFontScale` enum (small 0.9 / normal 1.0 / large 1.15 / extraLarge 1.3),
>   persisted by name in one `AppSettings` row. Applied globally by overriding
>   `MediaQuery.textScaler` in `_ThemedApp`'s builder; Settings → Appearance →
>   "Font size" sheet (each option previewed at its own size).
> - **#6 print-button toggle + no-printer skip.** `PrintSettingsService` (KV
>   `show_print_button`, default on) → `BillingState.printEnabled` via
>   `LoadPrintSettingsEvent`. When off, checkout hides the print button ("New
>   Sale" spans full width) **and** `_onConfirmSale` skips auto-print — so a
>   printerless shop isn't nagged with the "printer not connected" red notice.
>   When on, the existing auto-print already reports `printerUnavailable` (red
>   snackbar) if the printer is unreachable at sale finish. Settings → Hardware →
>   "Print receipts" switch.
>
> `flutter analyze` clean; **97 tests** pass (+1 auto-print-gating). New ARB keys:
> `fontSizeTitle/Small/Normal/Large/ExtraLarge`,
> `showPrintButtonTitle/Subtitle`.
>
> **✅ Wave D shipped** (items 11, 9) — landed in several rounds as the failing
> product was diagnosed on-device; final state:
> - **The failing product was an INVERTED barcode** — white bars on a red tin
>   (EAN-13 `6213295315252`, misread once as the *checksum-valid* `1108009445972`).
>   ML Kit cannot decode inverted codes natively; the reference SuperCodeReader
>   app ships ML Kit too (`barcode-scanning*.properties` in its APK), so the
>   engine was never the difference — frame preprocessing was.
> - **Upgraded `mobile_scanner` 5.2.3 → 7.4.0** (an earlier note here claimed no
>   version has a focus API — wrong: 7.x added `tapToFocus`/`setFocusPoint`,
>   `invertImage`, and `autoZoom`). Only code change forced by the upgrade:
>   2-arg `errorBuilder`, `BarcodeFormat.itf` → `itf14`.
> - **#11 reliability, layered:** (1) `formats:` whitelist
>   (`core/utils/barcode_formats.dart`); (2) analysis resolution 1280×720 with a
>   **self-healing fallback** (`_highRes` drops on first camera error — a
>   hard-pinned 1920×1080 had latched "camera unavailable" on-device);
>   (3) **multi-frame confirmation** (`_kScanConfirmations = 2` consecutive
>   identical decodes) so a one-off valid-but-wrong read can't enter the cart —
>   ScannerPage switched `noDuplicates` → `normal` to allow the re-fires;
>   (4) an **inverted-barcode toggle** ("باركود فاتح" overlay button on the POS,
>   app-bar action on ScannerPage) that rebuilds the controller with
>   `invertImage: true` — a toggle, not a default, because inversion breaks
>   normal dark-on-light codes; (5) `autoZoom: true`.
> - **#9:** real **tap-to-focus** (`tapToFocus: true` on both scanners) plus
>   pinch-to-zoom / double-tap with a live zoom-% pill.
>
> `flutter analyze` clean; **97 tests** pass. **All 11 items now addressed**, and
> the red-tin product was **confirmed reading on-device** with the invert toggle.
>
> **✅ Follow-up 1 — unit fidelity (schema v13→v14).** `sales_items.saleType`
> now snapshots the `ProductSaleType` name at sale time. This fixed a real
> inconsistency found while scoping it: **reprints dropped the unit entirely**
> (`HistoryBloc` never passed `ReceiptLine.unit`), so the original receipt
> printed `0.333 كغ × رز` and its reprint printed `0.333 × رز`. Column defaults
> to `''` (unknown) rather than `'piece'` so legacy rows keep falling back to the
> old fractional-quantity guess (`InvoiceItem.isMeasured`) instead of being
> confidently mislabelled. **104 tests** pass (+7); the v13→v14 upgrade is
> verified on a real device by `integration_test/migration_v14_test.dart` (data
> survives, legacy rows read `''`, new rows store `'weight'`).

---

## How to read this doc

Each item keeps the **owner's original number** (1–11) so it maps 1:1 to
`docs/v1-fixes.txt`. For each: the ask (with the Arabic original), where it lives
in the code, the proposed approach, effort, and any decision/risk to flag before
building. A suggested **build order** (by impact ÷ effort) is at the end.

Established precedent reused across several items — a **KV-backed settings
toggle**: `InventorySettingsService` (`core/settings/`) → `SettingsDao.getValue/
setValue` → a Switch/sheet tile in `settings_page.dart` → pushed into the BLoC
via an event (mirror `blockOversell` / `LoadInventorySettingsEvent`). Items 1, 6
follow this pattern.

---

## 1. App-wide font-size setting

> *«إضافة إعداد في صفحة الإعدادات للتحكم بحجم الخط في كامل التطبيق»*
> Add a Settings control for text size across the whole app.

**Why:** older shopkeepers; small thermal-era habits. Accessibility win, low risk.

**Where**
- Apply globally at `main.dart:276` (`MaterialApp.router`'s `builder:`, already
  wrapping every route with `_UpdateChecker`) — wrap its child in a `MediaQuery`
  with `textScaler: TextScaler.linear(factor)`.
- Persist with a `FontScaleController` that **mirrors** `theme_controller.dart`
  exactly (a `ChangeNotifier` over one `AppSettings` KV row, `.load()`ed
  pre-`runApp` at `main.dart:58`, listened via the existing `AnimatedBuilder` in
  `_ThemedApp`). Register in `service_locator.dart`.
- UI: a "Font size" tile in the **appearance** group of `settings_page.dart`
  (~lines 322-333), opening a sheet like `_showThemeSheet` (lines 714-750) —
  offer 3–4 discrete steps (Small / Normal / Large / Extra), not a raw slider.

**Approach:** clamp the scale (e.g. `0.85–1.35`) so layouts don't break; ship
discrete presets. **Effort:** S. **Migration:** none (KV row).

---

## 2. Piece-/item-count column in invoice review

> *«إضافة عمود عدد القطع في مراجعة الفاتورة»*
> Add a quantity column when reviewing an invoice.

**Where**
- Checkout review `Table`: `checkout_page.dart:160-220` — today quantity is
  glued into the product cell (`'${formatQty(item.quantity)} x ${name}'`, line
  199). Give it its **own column** via `_headerCell` (546) + `_dataCell` (561).
- Invoice detail: `invoice_detail_page.dart:196-254` — same, add a qty column to
  the `Row`/`Expanded(flex:)` layout (qty currently a sub-line at 223).

**Note:** this overlaps heavily with **item #10** (full table). Build #10 and #2
falls out of it for free — see the merge note under #10. **Effort:** S (or free
if #10 is done). **Migration:** none.

---

## 3. Empty (not "0") defaults on the add-product page

> *«حذف الأصفار من صفحة إضافة منتج في الحقول التي يجب ملؤها... يجب أن تكون الخانة
> فارغة لأنها تُربك المستخدم»*
> Stop pre-filling `0`; blank fields are clearer.

**Where** — `add_product_page.dart`: remove `initialValue: '0'` on **cost**
(220), **quantity/stock** (241), and **low-stock alert** (259). Keep `hintText:
'0'` (238, 256) as a placeholder. Safe because `onSaved` already coalesces
`NumInput.parseFlexibleNumber(...) ?? 0` (228-229, 246-247, 264-265) and the
validators are `optionalNonNegative`.

**Effort:** XS (3 lines). **Migration:** none. **Risk:** none — pure UX.

---

## 4. Scanned item appears at the **top** of the cart

> *«عند قراءة منتج جديد يجب أن يظهر في أعلى قائمة الطلبات وليس في الأسفل»*

**Why:** the cashier watches the just-scanned line for price confirmation; on a
long cart it scrolls off the bottom.

**Where** — `billing_bloc.dart:164-196` `_onAddProductToCart`. New lines are
**appended** (187-190: `[...cleanState.cartItems, _priceLine(...)]`). Prepend
instead: `[_priceLine(...), ...cleanState.cartItems]`. Both renderers
(`home_page.dart:827-834`, `checkout_page.dart:185`) follow list order — **no
widget change**.

**Decision to confirm:** on **re-scanning an existing** item (branch 178-185, qty
++ in place) — should it also **jump to top**? Recommend **yes** (consistency:
"the thing I just touched is on top"). **Effort:** S. **Migration:** none.

---

## 5. Newly added product appears at the **top** of the product list

> *«عند إضافة منتج جديد يجب أن يظهر في أعلى قائمة المنتجات وليس في الأسفل»*

**Where** — the list order comes from `products_dao.dart:16`
`watchAllProducts() => select(products).watch()` with **no `ORDER BY`** (so it's
rowid/undefined). Options:
- **(a) cheap:** `..orderBy([(p) => OrderingTerm.desc(p.rowId)])` — newest-first
  by insertion, zero migration.
- **(b) explicit:** add a `createdAt` column to `products_table.dart` (schema
  **v13→v14**, additive `addColumn` with default) and order by it. More honest,
  survives future row rewrites, but costs a migration.

**Recommendation:** **(a)** for this batch — matches the "no migration" spirit and
`rowId` desc is monotonic with insertion here. Flag (b) as the clean upgrade if a
real `createdAt` is ever wanted for reporting. `product_list_page.dart:330-344`
renders in stream order, so nothing else changes. **Effort:** XS (option a).

---

## 6. Show/hide the print button + auto printer-connected check (red notice)

> *«إضافة إعداد لإظهار/إخفاء زر الطباعة + التحقق التلقائي من الطابعة إذا متصلة
> (ظهور إشعار بلون أحمر عند إنهاء أوردر)»*

Two sub-parts:

**6a — toggle the print button.** Some shops don't print. Add a KV bool (see the
shared toggle precedent) and gate the post-sale print button at
`checkout_page.dart:322-356`. Auto-print in `_onConfirmSale`
(`billing_bloc.dart:318-343`) should respect the same flag.

**6b — red "printer not connected" notice on finishing an order.** Live check
already exists: `PrinterHelper.isLiveConnected()` (`printer_helper.dart:24-34`),
and the bloc already emits `BillingError.printerUnavailable` when a print fails
(`billing_bloc.dart:336`). Surface it as a **red** notice reusing the existing
red-box style (`checkout_page.dart:581-609`) / red snackbar (69-74) when a sale
is confirmed while the printer is disconnected **and** printing is enabled.

**Effort:** M (two coordinated pieces). **Migration:** none.

---

## 7. Halve notification (snackbar) durations

> *«تقليل زمن ظهور الإشعارات مثل إشعار الطابعة غير متصلة إلى نصف الزمن»*

**Where** — there's **no central duration**; some snackbars set it explicitly
(`home_page.dart:317` 6s, `main.dart:86` 5s, `support_sheet.dart:58` 6s,
`subscription_plans_page.dart:379` 6s), most inherit Flutter's ~4s default via
`snackBarTheme` (`app_theme.dart:203-209`, no duration).

**Approach:** introduce a shared helper/const (e.g. `AppSnack.short =
Duration(seconds: 2)`, `.normal = 3s`) and route snackbars through it, halving
the loud ones. `SnackBarThemeData` has no `duration` field, so a helper is the
clean fix rather than a theme one-liner. **Effort:** S (mechanical sweep).

---

## 8. Out-of-stock made obvious (red in list + scan notice) ⭐

> *«عند إضافة منتج منتهية الكمية يظهر بلون أحمر في قائمة البحث + عند قراءة الباركود
> يظهر إشعار "انتهت كمية هذا المنتج"... حتى لا يبحث في متجره ساعات ويؤخّر الزبون»*

**Why (owner's own words):** so the merchant *knows on the spot* an item is out,
instead of hunting the shelves and stalling the customer. **High-value.**

**Where**
- Add `bool get isOutOfStock => quantity <= 0;` to `product.dart` (near
  `isLowStock`, line 34).
- List tile: `product_list_page.dart:417-421` currently **hides** the stock row
  for a qty-0/no-alert item, and `_buildStockRow` (500-546) only reddens on
  `isLowStock`. Change the gate + color so **zero-qty shows a red "out of stock"
  row**.
- Scan: `billing_bloc.dart:136-162` `_onScanBarcode` adds to cart with no stock
  gate (except the measured branch). Add an out-of-stock check before line 158
  that surfaces a **transient notice** (a new `BillingState` flag, mirror
  `measuredPrompt`) → red snackbar on `home_page`.

**Important interaction with existing policy:** the app **allows overselling by
default** (POS floors stock at 0, never blocks — see CLAUDE.md "Stock is
optional"). So this item is a **warning, not a block**: it must *inform* even as
the sale proceeds. Do **not** turn it into a hard stop (that's the separate opt-in
`blockOversell` path). **Effort:** M. **Migration:** none.

---

## 9. Camera tap-to-focus

> *«إضافة تركيز للكاميرا... عند الضغط يزداد تركيز الكاميرا على الجزء الذي يُضغط عليه»*

**⚠️ Blocked on a package upgrade.** `mobile_scanner: ^5.1.0` (`pubspec.yaml:39`)
exposes **no** tap-to-focus / focus-point API — region/point focus landed in the
**6.x** line. 5.x only has `toggleTorch`, `switchCamera`, `setZoomScale`,
`analyzeImage`.

**Approach:** bundle with **item #11** — do one **`mobile_scanner` 5.1 → 6.x
upgrade** and implement tap-to-focus (a `GestureDetector`/`onTapDown` over the
`MobileScanner` at `home_page.dart:406-414` and `scanner_page.dart:63-67`, calling
the 6.x focus API). **Effort:** M–L (upgrade + migration of the two controllers +
device retest). **Risk:** the 5→6 upgrade has breaking API changes — must retest
scan + torch on a real device. See the joint note under #11.

---

## 10. Render the order/invoice as a real table ⭐

> *«إظهار الفاتورة عند "مراجعة الطلب" وفي صفحة تفاصيل الفاتورة كجدول بالأعمدة:
> مسلسل (م) — الصنف — الكمية (ك) — الوحدة (كجم/قطعة) — الإفرادي — الإجمالي»*
> Reference: the printed wholesale invoice photo (Image #12) is the target layout.

**Columns:** `م` (serial) · `الصنف` (item) · `ك` (qty) · unit (kg/piece) · `الإفرادي`
(unit price) · `الإجمالي` (line total).

**Where**
- Checkout review already uses a `Table` (`checkout_page.dart:160-220`) but only
  3 columns — extend to 6 via `_headerCell`/`_dataCell`. Unit derives from
  `item.product.saleType.isMeasured` (kg vs piece; `l10n.unitKg`).
- Invoice detail (`invoice_detail_page.dart:196-254`) uses `Row`+`Expanded`, not a
  real `Table` — rebuild as a `Table` for column alignment.

**⚠️ Data gap for reprints:** the **unit (kg/piece) is not persisted** on
`InvoiceItem` (`invoice_item.dart`) — only qty/price/currency are snapshotted. For
a historical invoice we can't currently render the unit column faithfully.
Options: (a) infer from whether qty is fractional (imperfect); (b) snapshot a
`unit`/`saleType` on `sales_items` going forward (schema bump, additive) — old
rows fall back to (a). **Recommend (b)** if the unit column matters on reprints;
otherwise ship the live checkout table now and mark detail-page unit as
best-effort.

**Merge note:** this **subsumes item #2** (qty column). Build #10 → #2 is done.
New l10n keys needed: serial(`م`), qty(`ك`), unit, unit-price(`الإفرادي`) —
`colProduct/colPrice/colTotal/unitPrice/unitKg` already exist. **Effort:** M.

---

## 11. Barcode read reliability ⭐

> *«منتج لم يستطع برنامجنا قراءة الباركود الخاص به عدة مرات، وأحياناً ينجح مع قراءة
> خاطئة. جرّبت تطبيق SuperCodeReader فقرأه بسهولة بدون خطأ في كل مرة.»*
> Reference: *Super CodeReader* (Image #11) reads it every time, error-free.

**Why it matters most:** a **wrong** read is worse than a failed one — it rings up
the wrong product. This is a correctness bug, not just polish.

**Current config**
- Inline (`home_page.dart:40-43`): `detectionSpeed: normal`, `returnImage: false`,
  **no `formats:` restriction** (scans every symbology → more misread surface),
  custom 2s dedup (`_lastScanTimes`).
- ScannerPage (`scanner_page.dart:16-19`): `detectionSpeed: noDuplicates` — a
  **different** dedup strategy than home. Inconsistent.

**Approach (layered — do the cheap levers first, then upgrade if needed):**
1. **Restrict `formats:`** to the symbologies retail products actually use
   (EAN-13/EAN-8/UPC-A/UPC-E, plus Code128 if you print your own labels). Fewer
   candidate decoders = far fewer *wrong* reads.
2. **Unify `detectionSpeed`** and consider `cameraResolution` bump for dense/small
   barcodes; align the two controllers' dedup so behavior is predictable.
3. **Upgrade `mobile_scanner` 5.1 → 6.x** (shared with **#9**) — newer MLKit /
   ZXing backend improves decode robustness and unlocks tap-to-focus (which itself
   helps the failing-barcode case: focus + zoom on a small/curved label).

**Data I still need from you (offered in the note):** please send **(a)** a clear
photo of the exact barcode that fails on the product, and **(b)** its expected
digits. That lets me confirm the symbology and reproduce, so I tune `formats:` to
the real culprit rather than guessing. **Effort:** M (levers 1–2) → L (with the
upgrade). **Migration:** none.

---

## Suggested build order

Grouped by value ÷ effort and by shared surface (so we touch each file once).

| Wave | Items | Rationale |
|---|---|---|
| **A — quick wins (a day)** | 3, 4, 5(a), 7 | One-to-few-line changes, zero migration, immediate cashier relief. |
| **B — the two star UX items** | 8, 10 (+2 folds in) | Highest field value: "don't hunt the shelf" + the invoice-as-table the owner drew for us. |
| **C — settings batch** | 1, 6 | Both ride the shared KV-toggle precedent; do them together. |
| **D — scanner overhaul** | 11, 9 | One `mobile_scanner` 5→6 upgrade unlocks both; needs real-device retest — schedule last. |

**Open decisions to confirm before building** (all called out inline above):
1. **#4** — should re-scanning an existing item also jump it to the top? *(rec: yes)*
2. **#5** — `rowId desc` (no migration) vs. a real `createdAt` column? *(rec: rowId now)*
3. **#10** — persist `unit`/`saleType` on `sales_items` for faithful reprints, or
   infer best-effort? *(rec: persist if the unit column matters on old invoices)*
4. **#11/#9** — approve the `mobile_scanner` 6.x upgrade (breaking API, device
   retest) as part of this batch?

**Data still needed from the owner:** the failing barcode photo + expected digits
(item #11).
