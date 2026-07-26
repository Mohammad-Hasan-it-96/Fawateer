import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/product_units_table.dart';
import '../tables/products_table.dart';

part 'product_units_dao.g.dart';

/// Serialized inventory (Plan 012) — one row per physical item.
///
/// **The invariant this DAO exists to protect (Plan 012 D1):** for a serialized
/// product, `products.quantity` is a *maintained cache* of the number of
/// available units. Units are the source of truth. Every mutation here writes
/// both sides **in one transaction**, the same discipline the sale path uses for
/// invoice + stock + cashbox — so the two can never drift apart through a
/// partial write.
///
/// `Products` is in the accessor list so those writes can name it as an updated
/// table, which is what re-runs `watchAllProducts` and gets the new on-hand onto
/// every screen. (The same `customUpdate(..., updates:)` lesson the sale
/// deduction learned the hard way — see `SalesDao.insertInvoiceWithItems`.)
@DriftAccessor(tables: [ProductUnits, Products])
class ProductUnitsDao extends DatabaseAccessor<AppDatabase>
    with _$ProductUnitsDaoMixin {
  ProductUnitsDao(super.db);

  /// The name every available-unit count and stock sync is keyed on. Kept as one
  /// constant so "which statuses count as on-hand" is defined in exactly one
  /// place in SQL, matching `UnitStatus.isAvailable` in Dart.
  static const _available = 'inStock';

  /// Live list of a SKU's units, newest first.
  Stream<List<ProductUnitRow>> watchUnitsForProduct(String productId) =>
      (select(productUnits)
            ..where((u) => u.productId.equals(productId))
            ..orderBy([(u) => OrderingTerm.desc(u.createdAt)]))
          .watch();

  Future<ProductUnitRow?> getUnitById(String id) =>
      (select(productUnits)..where((u) => u.id.equals(id))).getSingleOrNull();

  Future<List<ProductUnitRow>> getUnitsForProduct(String productId) =>
      (select(productUnits)..where((u) => u.productId.equals(productId))).get();

  /// Find one unit by its exact serial. This is the second scan path (Plan 012
  /// D6): the POS tries `getByBarcode` first and falls through to here, so
  /// scanning an IMEI selects that specific handset.
  ///
  /// Returns null for a blank serial rather than matching the blank-serial rows
  /// a shop may have logged before reading a label — scanning nothing must not
  /// silently pick an arbitrary unit.
  Future<ProductUnitRow?> getBySerial(String serial) {
    if (serial.isEmpty) return Future.value(null);
    return (select(productUnits)..where((u) => u.serial.equals(serial)))
        .getSingleOrNull();
  }

  /// How many units of [productId] are on the shelf.
  Future<int> availableCount(String productId) async {
    final row = await customSelect(
      'SELECT COUNT(*) AS c FROM product_units WHERE product_id = ? AND status = ?',
      variables: [
        Variable<String>(productId),
        const Variable<String>(_available),
      ],
      readsFrom: {productUnits},
    ).getSingle();
    return row.read<int>('c');
  }

  /// Add a unit and re-sync the SKU's cached quantity, atomically.
  ///
  /// Throws if the serial collides with an existing one — that is the
  /// partial-unique index doing its job, and the caller maps it to a
  /// `DuplicateFailure` so the cashier is told rather than silently given two
  /// rows for one handset.
  Future<void> insertUnit(ProductUnitsCompanion unit) => transaction(() async {
        await into(productUnits).insert(unit);
        await _syncQuantity(unit.productId.value);
      });

  /// Delete a unit and re-sync the cached quantity, atomically.
  Future<void> deleteUnit(String id) => transaction(() async {
        final row = await (select(productUnits)..where((u) => u.id.equals(id)))
            .getSingleOrNull();
        if (row == null) return;
        await (delete(productUnits)..where((u) => u.id.equals(id))).go();
        await _syncQuantity(row.productId);
      });

  /// Change a unit's status (e.g. mark defective) and re-sync, atomically.
  Future<void> updateStatus(String id, String status) => transaction(() async {
        final row = await (select(productUnits)..where((u) => u.id.equals(id)))
            .getSingleOrNull();
        if (row == null) return;
        await (update(productUnits)..where((u) => u.id.equals(id)))
            .write(ProductUnitsCompanion(status: Value(status)));
        await _syncQuantity(row.productId);
      });

  /// Set a unit's warranty expiry (ms since epoch; 0 clears it). Does not touch
  /// stock, so no re-sync is needed.
  Future<void> setWarranty(String id, int warrantyUntil) =>
      (update(productUnits)..where((u) => u.id.equals(id)))
          .write(ProductUnitsCompanion(warrantyUntil: Value(warrantyUntil)));

  /// Mark units sold as part of a sale.
  ///
  /// **Deliberately not wrapped in its own transaction** — it is called from
  /// inside the sale's transaction (`SalesDao.insertInvoiceWithItems`), so that
  /// a unit can never be marked sold by an invoice that failed to save. Drift
  /// nests transactions as savepoints, but the guarantee we want is that this
  /// shares the *caller's* atomicity, so it takes no transaction of its own.
  ///
  /// The quantity is **not** re-synced here: the sale path already decrements
  /// `products.quantity` for every line, serialized or not, and doing both would
  /// double-count. That coupling is the one place the invariant is maintained
  /// outside this DAO, and it is why this method is named for the sale.
  Future<void> markSoldInSaleTransaction({
    required List<String> unitIds,
    required String invoiceId,
    required int soldAt,
  }) async {
    for (final id in unitIds) {
      await (update(productUnits)..where((u) => u.id.equals(id))).write(
        ProductUnitsCompanion(
          status: const Value('sold'),
          soldInvoiceId: Value(invoiceId),
          soldAt: Value(soldAt),
        ),
      );
    }
  }

  /// Release units back to stock when their invoice is deleted, and re-sync the
  /// affected SKUs. Mirrors how deleting a sale reverses its cashbox entry.
  Future<void> releaseByInvoiceInTransaction(String invoiceId) async {
    final rows = await (select(productUnits)
          ..where((u) => u.soldInvoiceId.equals(invoiceId)))
        .get();
    if (rows.isEmpty) return;
    await (update(productUnits)
            ..where((u) => u.soldInvoiceId.equals(invoiceId)))
        .write(const ProductUnitsCompanion(
      status: Value(_available),
      soldInvoiceId: Value(''),
      soldAt: Value(0),
    ));
    for (final productId in rows.map((r) => r.productId).toSet()) {
      await _syncQuantity(productId);
    }
  }

  /// Rewrite `products.quantity` from the authoritative unit count.
  ///
  /// Written as one `UPDATE … SELECT COUNT(*)` rather than read-then-write so
  /// two concurrent unit edits can't read the same stale count and clobber each
  /// other — the same reasoning behind the sale's relative stock decrement.
  Future<void> _syncQuantity(String productId) => customUpdate(
        'UPDATE products SET quantity = ('
        '  SELECT COUNT(*) FROM product_units'
        '  WHERE product_id = ? AND status = ?'
        ') WHERE id = ? AND is_serialized = 1',
        variables: [
          Variable<String>(productId),
          const Variable<String>(_available),
          Variable<String>(productId),
        ],
        updates: {products},
      );
}
