import 'package:drift/drift.dart';

import 'sync_meta.dart';

/// Append-only log of every change to on-hand stock (Plan 002, Phase 0 —
/// "inventory, the hard one").
///
/// **Why a log and not a number.** `products.quantity` used to be the truth, a
/// single scalar mutated in place. Under last-write-wins that loses sales: two
/// devices each selling one of five converge on "4" — one sale's deduction is
/// simply overwritten, and a unit vanishes from the books with nothing to show
/// it ever happened. Signed movements have no such failure: they are
/// append-only, so two devices merge by **union** and both sales count. It is
/// the same shape the cashbox and the debt ledger already use, and for the same
/// reason — a derived total cannot be clobbered.
///
/// `products.quantity` survives as a **local cache** of `SUM(delta)`, recomputed
/// from this log by [kRecomputeQuantitySql] inside every transaction that writes
/// a movement. Deriving it at every read would be purer, but it is read by the
/// POS, the oversell guard, the low-stock chip, the inventory-value aggregate
/// and several joins — the identical trade-off Plan 012 made for serialized
/// units, resolved the identical way.
///
/// **The cache must never be replicated.** When the sync engine lands,
/// `products.quantity` has to be excluded from the products row merge and
/// recomputed locally after movements are applied. Merging it as a field would
/// reintroduce exactly the lost-sale bug this table exists to remove.
@DataClassName('StockMovementRow')
class StockMovements extends Table with SyncMeta {
  TextColumn get id => text()();

  TextColumn get productId => text()();

  /// Signed change to on-hand: negative for a sale, positive for a restock.
  ///
  /// `double` (not int) because stock is `double` app-wide — a shop selling
  /// 0.333 kg of rice records a fractional movement.
  RealColumn get delta => real()();

  /// Why the stock moved, persisted **by name** — never by index, the same rule
  /// as `ProductSaleType` / `PriceCurrency` / `CashTransactionType` / `UnitStatus`,
  /// so reordering the enum can't silently remap history.
  TextColumn get reason => text().withDefault(const Constant('adjustment'))();

  /// The record that caused the movement (invoice id for a sale), or `''`.
  /// Mirrors `cashbox_transactions.relatedId` — it is what lets a deleted
  /// invoice find and reverse the movements it posted.
  TextColumn get relatedId => text().withDefault(const Constant(''))();

  TextColumn get note => text().withDefault(const Constant(''))();

  /// When the stock actually moved, ms since epoch. Separate from [createdAt]
  /// for the same reason the cashbox separates them: a movement can be recorded
  /// after the fact.
  IntColumn get occurredAt => integer()();

  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Rewrites one product's cached `quantity` from whatever is authoritative for
/// it. Takes the product id as its single bound parameter.
///
/// Defined once, here, because three DAOs need it (the sale path, the unit path
/// and the stock path) and drift discourages cross-DAO calls inside a
/// transaction. Three copies of this `CASE` would be three chances for on-hand
/// to mean different things in different places.
///
/// **Two authorities, one per kind of product**, and that is deliberate rather
/// than an inconsistency: a serialized SKU's movement log *is* its
/// `product_units` table — each row is already an append-only, uuid-keyed,
/// merge-safe record of one physical item — so counting units satisfies Plan
/// 002's requirement without a second parallel ledger that could disagree with
/// it.
///
/// The `MAX(…, 0)` floor preserves today's shipped behaviour: on-hand never
/// displays negative. Note it clamps the **sum**, not each step — a shop that
/// oversells to −3 and then restocks 5 correctly lands on 2, where the old
/// clamp-as-you-go `MAX(quantity - ?, 0)` would have said 5. Plan 002 wants
/// transient negative on-hand surfaced once devices race; the signed truth is
/// preserved in the log for exactly that, and only this display cache is
/// floored.
const String kRecomputeQuantitySql = '''
UPDATE products SET quantity = CASE
  WHEN is_serialized = 1 THEN (
    SELECT COUNT(*) FROM product_units
     WHERE product_id = products.id AND status = 'inStock' AND deleted_at = '')
  ELSE MAX((
    SELECT COALESCE(SUM(delta), 0) FROM stock_movements
     WHERE product_id = products.id AND deleted_at = ''), 0)
  END
WHERE id = ?''';
