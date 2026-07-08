# Architecture Review — Fawateer POS

> Lead Architect review of the current codebase before adding new features.
> Goal: confirm production-readiness and long-term maintainability — **not** to add features.
> Guiding principle: keep it simple, avoid unnecessary abstractions, prefer maintainability over cleverness.

---

## What's already right (don't touch)

- **Layering is consistent and correct** in product / shop / billing-history: entity → repository interface → drift impl → usecase → bloc. The dependency direction never inverts.
- **DI ordering** in `service_locator.dart` is textbook (db → dao → repo → usecase → bloc) and easy to follow.
- **Migrations** are disciplined — append-only `if (from < N)` blocks, idempotent indexes, documented rationale. The hardest thing to get right, and it's right.
- **Repositories map rows → entities directly** with no redundant model layer. Correct call for an app this size.

The issues below are real, but you're refactoring from a healthy base, not a broken one.

---

## 🔴 Critical (fix now, before any new feature)

### C1. Stock deduction is non-atomic and silently corrupts product data

`BillingBloc._onConfirmSale` (`billing_bloc.dart:131–136`):

```dart
for (final cartItem in state.cartItems) {
  final newQuantity = cartItem.product.quantity - cartItem.quantity;
  await updateProductUseCase(cartItem.product.copyWith(quantity: newQuantity));
}
```

**Why it's a problem** — three compounding issues:

1. **Read-modify-write on a stale snapshot.** `cartItem.product` was captured at *scan time*. The new quantity is computed from that stale value and written back. Any change to on-hand quantity between scan and confirm is lost.
2. **It overwrites the entire product row.** `updateProductUseCase` → `insertProduct(insertOrReplace)` writes the *whole* cart snapshot. If a product's price/name/cost is edited after it's added to the cart, **confirming the sale silently reverts those edits.** That's data corruption, not a stock bug.
3. **It's outside the invoice transaction and errors are swallowed** ("best-effort"). The invoice saves, the deduction fails or partially applies, and inventory silently desyncs from sales — with no record.

**Fix now?** Yes — this is the one issue I'd gate a release on. Inventory you can't trust is worse than no inventory feature.

**Simplest solution** — push the whole sale into one repository method + one transaction, and decrement *relatively* in SQL (never write the snapshot back):

```dart
// SalesDao — inside the existing transaction()
await into(salesInvoices).insert(invoice);
for (final item in items) {
  await into(salesItems).insert(item);
  await customStatement(
    'UPDATE products SET quantity = quantity - ? WHERE id = ?',
    [item.quantity, item.productId]);
}
```

The BLoC then loses the entire second loop, and the deduction becomes atomic with the sale.

---

## 🟠 Recommended (fix soon — they compound as features grow)

### R1. Three different "how a BLoC reaches data" patterns

- `ProductBloc` / `ShopBloc` / `HistoryBloc` → **usecases only** ✅
- `PrinterBloc` → **repository directly, no usecases**
- `BillingBloc` → **2 usecases + 2 repositories + a `new PrinterHelper()` singleton**

**Why it's a problem:** the rule isn't predictable, and `BillingBloc` instantiating `PrinterHelper()` directly wires infrastructure (Bluetooth connection state) into a BLoC. One exception and the pattern stops being a guardrail.

**Fix now?** Soon. Decide the rule before more features pile on.

**Simplest solution** — pick **one** rule and apply it everywhere. Recommendation given the "don't over-engineer" constraint: **let BLoCs call repositories directly, and keep usecases only where there's real logic.** Today every usecase is a one-line passthrough — dropping the trivial ones removes ~8 files and the inconsistency disappears (everyone uses repositories). If you prefer usecases for uniformity, that's fine too — but then `PrinterBloc` and `BillingBloc` must go through them as well.

### R2. Printing logic lives in the BLoC and is duplicated

`_onConfirmSale` and `_onPrintReceipt` both build `Map<String, dynamic>` receipt rows and drive `PrinterHelper` directly; the connect-or-reconnect dance is copy-pasted in both.

**Why it's a problem:** stringly-typed receipt maps, duplicated reconnect logic, and the BLoC owning infrastructure concerns.

**Fix now?** Soon — bundle with R1.

**Simplest solution** — move "build receipt + ensure connected + print" behind `PrinterRepository.printReceipt(...)`. Both handlers collapse to one call and the `Map<String,dynamic>` disappears.

### R3. The domain layer imports a Bluetooth plugin

`printer_repository.dart` (domain) imports `print_bluetooth_thermal`, returns its `BluetoothInfo` type, and `throw`s instead of returning `Either<Failure>` like every other repository.

**Why it's a problem:** the domain layer depends on a hardware package, and the printer feature opts out of the `Either` error convention used everywhere else.

**Fix now?** Soon.

**Simplest solution** — define a tiny `PrinterDevice(name, mac)` domain class and return that; return `Either<Failure, T>` for consistency.

### R4. Only one `Failure` type, used for genuinely different conditions

"Product not found by barcode" maps to `CacheFailure` (`product_repository_drift_impl.dart:52`), same as a real DB error. The BLoC also surfaces hardcoded English ("Product not found: ...") in an Arabic-first app, bypassing ARB localization.

**Why it's a problem:** the UI can't tell "scan a real barcode" from "the database broke," and error text escapes localization.

**Fix now?** Soon.

**Simplest solution** — add `NotFoundFailure` (one class). Emit a *failure type* from the BLoC and let the page map it to an l10n string; don't put user-facing English in the BLoC.

### R5. Dead customer fields in the domain

`Invoice` carries `customerId` / `customerName`, threaded through the entity, companion, and DAO — but the customers feature was dropped in the v3 migration.

**Why it's a problem:** every reader assumes these mean something; they're permanently empty. Dead surface area invites bugs.

**Fix now?** Later — cheap whenever convenient.

**Simplest solution** — remove them from the entity and mapping; leave the DB columns orphaned (exactly as you already do for `stock` / `upiId` — no migration needed).

---

## 🟡 Nice-to-have (later, when convenient)

- **N1. Unused reactive streams.** DAOs expose `watchAllProducts()` / `watchAllInvoices()` but nothing uses them — lists reload manually via `refreshHistoryIfNeeded` + re-dispatched `LoadProducts`. Switching list BLoCs to `emit.forEach(stream)` would delete the manual-refresh plumbing and auto-sync History totals after a sale. Deliberate change, not urgent.
- **N2. `HistoryBloc` computes "today" with `DateTime.now()` inline** — fine functionally, untestable. Extract only if you start testing it.
- **N3. `deleteInvoice` leaves orphaned line items** (the DAO comment admits it). Unused today, so harmless — but if you ever expose delete, add `ON DELETE CASCADE` or delete items in the same transaction.
- **N4. Receipt encoding is Latin-1** (`_textToBytes` uses `text.codeUnits`). For an Arabic-first app, Arabic shop names/items will print as garbage. More a functionality gap than architecture, but it contradicts the product's primary locale.
- **N5. Clean the stream-of-consciousness comments in `printer_helper.dart`** (lines ~84–100 are scratch notes). Cosmetic.

---

## Bottom line

The architecture is **fundamentally sound and appropriately simple** — not over-engineered, and it will scale fine. There is exactly **one issue I'd gate a release on (C1)** because it's a correctness/data-integrity bug, not a style preference. The recommended tier is mostly about **picking one consistent rule (R1)** so the codebase stays predictable as it grows — that single decision resolves R1, R2, and most of R3 together.

### Suggested order of work

1. **C1** — atomic `recordSale` (transaction + relative SQL decrement). Contained, high-value.
2. **R1 / R2** — choose one data-access rule; move printing behind the repository.
3. **R3 / R4 / R5** — restore the domain boundary, add `NotFoundFailure`, drop dead fields.
4. **N1–N5** — opportunistic.
