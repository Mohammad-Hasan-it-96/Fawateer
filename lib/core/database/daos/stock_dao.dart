import 'package:drift/drift.dart';
import '../../sync/sync_clock.dart';
import '../app_database.dart';
import '../tables/products_table.dart';
import '../tables/stock_movements_table.dart';

part 'stock_dao.g.dart';

/// The append-only stock ledger (Plan 002, Phase 0).
///
/// **Movements are the truth; `products.quantity` is a cache.** Every method
/// that writes a movement recomputes that cache in the *same transaction*, the
/// discipline `ProductUnitsDao` already uses for serialized SKUs and the sale
/// path uses for invoice + stock + cashbox — so the log and the number it
/// summarises can never drift apart through a partial write.
///
/// `Products` is in the accessor list so the recompute can name it as an
/// updated table, which is what re-runs `watchAllProducts` and gets the new
/// on-hand onto every screen. (The `customUpdate(..., updates:)` lesson the sale
/// deduction learned the hard way — see `SalesDao.insertInvoiceWithItems`.)
@DriftAccessor(tables: [StockMovements, Products])
class StockDao extends DatabaseAccessor<AppDatabase> with _$StockDaoMixin {
  StockDao(super.db);

  /// One product's movements, newest first.
  Stream<List<StockMovementRow>> watchMovements(String productId) =>
      (select(stockMovements)
            ..where((m) =>
                m.productId.equals(productId) & m.deletedAt.equals(''))
            ..orderBy([(m) => OrderingTerm.desc(m.occurredAt)]))
          .watch();

  Future<List<StockMovementRow>> getMovements(String productId) =>
      (select(stockMovements)
            ..where((m) =>
                m.productId.equals(productId) & m.deletedAt.equals(''))
            ..orderBy([(m) => OrderingTerm.desc(m.occurredAt)]))
          .get();

  /// On-hand derived straight from the log, **unclamped and unrounded**.
  ///
  /// This is the honest number: it can be negative when a shop has oversold,
  /// which `products.quantity` deliberately hides behind a floor. Use it when
  /// you need the truth (reconciliation, the future negative-stock flag), not
  /// for the POS.
  Future<double> derivedOnHand(String productId) async {
    final row = await customSelect(
      'SELECT COALESCE(SUM(delta), 0.0) AS on_hand FROM stock_movements '
      "WHERE product_id = ? AND deleted_at = ''",
      variables: [Variable<String>(productId)],
      readsFrom: {stockMovements},
    ).getSingle();
    return row.read<double>('on_hand');
  }

  /// Append a movement and refresh the product's cached quantity, atomically.
  ///
  /// A zero [delta] is written rather than skipped when a caller asks for it —
  /// a stock take that confirms the count *is* a fact worth recording — so
  /// callers that want "nothing happened, write nothing" must check first.
  Future<void> recordMovement(StockMovementsCompanion movement) =>
      transaction(() async {
        await into(stockMovements).insert(movement);
        await recomputeQuantity(movement.productId.value);
      });

  /// Move a product to an exact on-hand figure by recording the difference.
  ///
  /// This is what the edit-product quantity field goes through. Setting
  /// `products.quantity` directly is the last-write-wins scalar Plan 002
  /// rejects: two devices editing the same product would each save their own
  /// absolute number and one would erase the other's, sales included. A
  /// *difference* merges — both corrections survive.
  ///
  /// Measured against the derived on-hand, not the cached column, so a cache
  /// that is somehow stale cannot bake its error into a permanent movement.
  /// Returns the delta written, or 0 when the product is already on target.
  Future<double> setOnHand({
    required String productId,
    required double target,
    required String movementId,
    required String reason,
    required int now,
    required SyncStamp stamp,
    String note = '',
  }) async {
    final current = await derivedOnHand(productId);
    final delta = target - current;
    // Floating point: a form that round-trips "10" must not record a
    // 1.7e-15 correction on every save.
    if (delta.abs() < 0.0005) return 0;
    await recordMovement(StockMovementsCompanion.insert(
      id: movementId,
      productId: productId,
      delta: delta,
      reason: Value(reason),
      note: Value(note),
      occurredAt: now,
      createdAt: now,
      updatedAt: Value(stamp.hlc),
      originDevice: Value(stamp.device),
    ));
    return delta;
  }

  /// Tombstone every movement a source record posted (an invoice's sale lines),
  /// then refresh the affected products.
  ///
  /// Tombstoned rather than compensated with an opposite movement, matching how
  /// deleting an invoice reverses its cashbox entry: the sale did not happen,
  /// so the honest record is that the event is gone, not that stock came back.
  /// A genuine *return* is a different event and gets `StockMovementReason.saleReturn`.
  ///
  /// **Not wrapped in its own transaction** — it is called from inside the
  /// invoice deletion's transaction, so the reversal cannot outlive a delete
  /// that failed.
  Future<void> reverseByRelatedIdInTransaction(
      String relatedId, SyncStamp stamp) async {
    final affected = await (select(stockMovements)
          ..where((m) =>
              m.relatedId.equals(relatedId) & m.deletedAt.equals('')))
        .get();
    if (affected.isEmpty) return;
    await (update(stockMovements)
          ..where((m) =>
              m.relatedId.equals(relatedId) & m.deletedAt.equals('')))
        .write(StockMovementsCompanion(
      deletedAt: Value(stamp.hlc),
      updatedAt: Value(stamp.hlc),
      originDevice: Value(stamp.device),
    ));
    for (final productId in affected.map((m) => m.productId).toSet()) {
      await recomputeQuantity(productId);
    }
  }

  /// Rewrite one product's cached `quantity` from whatever is authoritative for
  /// it — see [kRecomputeQuantitySql] for which source and why.
  Future<void> recomputeQuantity(String productId) => customUpdate(
        kRecomputeQuantitySql,
        variables: [Variable<String>(productId)],
        updates: {products},
      );
}
