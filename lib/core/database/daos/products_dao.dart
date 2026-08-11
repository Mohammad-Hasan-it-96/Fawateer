import 'package:drift/drift.dart';
import '../../sync/sync_clock.dart';
import '../app_database.dart';
import '../tables/products_table.dart';

part 'products_dao.g.dart';

@DriftAccessor(tables: [Products])
class ProductsDao extends DatabaseAccessor<AppDatabase>
    with _$ProductsDaoMixin {
  ProductsDao(super.db);

  /// Fetch all products once.
  Future<List<ProductRow>> getAllProducts() =>
      (select(products)..where((p) => p.deletedAt.equals(''))).get();

  /// Reactive stream of all products, newest-added first (Plan 011 #5).
  /// Ordered by descending rowid — monotonic with insertion order here, so a
  /// just-added product surfaces at the top of the list with no createdAt
  /// column / migration.
  Stream<List<ProductRow>> watchAllProducts() => (select(products)
        ..where((p) => p.deletedAt.equals(''))
        ..orderBy([(p) => OrderingTerm.desc(p.rowId)]))
      .watch();

  /// Find a single product by barcode (or null if not found).
  /// Single product by primary key — the SKU behind a scanned serial (Plan 012).
  Future<ProductRow?> getById(String id) =>
      (select(products)..where((p) => p.id.equals(id) & p.deletedAt.equals('')))
          .getSingleOrNull();

  Future<ProductRow?> getByBarcode(String barcode) => (select(products)
        ..where((p) => p.barcode.equals(barcode) & p.deletedAt.equals('')))
      .getSingleOrNull();

  /// Insert a brand-new product. Throws on a duplicate barcode (the partial-
  /// unique index) instead of silently replacing the existing row — unlike
  /// [insertProduct]'s insert-or-replace. Use this for "add".
  Future<void> createProduct(ProductsCompanion product) =>
      into(products).insert(product);

  /// Insert or replace by id (used for "update"; the barcode is immutable in
  /// the edit form, so this can't clobber a different product).
  Future<void> insertProduct(ProductsCompanion product) =>
      into(products).insert(product, mode: InsertMode.insertOrReplace);

  /// Tombstone a product. Returns the number of rows marked.
  ///
  /// The row stays physically present — see `SyncMeta.deletedAt`. Re-tombstoning
  /// is a no-op (`deleted_at = ''` in the predicate) so a repeat delete cannot
  /// overwrite the original deletion's timestamp with a later one and make the
  /// delete look newer than it was.
  Future<int> softDeleteProduct(String id, SyncStamp stamp) =>
      (update(products)
            ..where((p) => p.id.equals(id) & p.deletedAt.equals('')))
          .write(ProductsCompanion(
        deletedAt: Value(stamp.hlc),
        updatedAt: Value(stamp.hlc),
        originDevice: Value(stamp.device),
      ));

  /// Write a new price + cost onto many products at once (Plan 015 B2.2).
  ///
  /// A real `UPDATE`, deliberately **not** [insertProduct]'s insert-or-replace:
  /// replace deletes and re-inserts the row, which mints a new rowid — and
  /// `watchAllProducts` orders by rowid, so a bulk edit would shuffle every
  /// touched product to the top of the list under the owner's finger, looking
  /// like they had just been added.
  ///
  /// Drift runs a batch inside one transaction, so a failure part-way leaves no
  /// half-priced catalogue.
  ///
  /// **Every row is re-stamped.** A bulk edit is still an edit: without the
  /// stamp the new prices would sit below the push watermark and never leave
  /// this phone, so the other till would keep selling at yesterday's price —
  /// silently, because nothing failed.
  Future<void> updatePriceAndCost(
          List<({String id, double price, double cost})> edits,
          SyncStamp stamp) =>
      batch((b) {
        for (final e in edits) {
          b.update(
            products,
            ProductsCompanion(
              price: Value(e.price),
              cost: Value(e.cost),
              updatedAt: Value(stamp.hlc),
              originDevice: Value(stamp.device),
            ),
            where: (p) => p.id.equals(e.id),
          );
        }
      });

  /// Set (or clear) one custom-field value on many products at once — bulk
  /// category assign, Plan 014 step 2. A blank [value] clears the field, which
  /// is how a product is put back into the "no category" bucket.
  ///
  /// Two details that would each be a silent data loss if skipped:
  ///
  /// - `json_set` on a **non-JSON** column returns NULL, and the `attributes`
  ///   default is `''` for every product that has never had one. Without the
  ///   `CASE`, categorising an untouched product would blank its bag.
  /// - Ids go in **chunks of 200**: SQLite caps bound variables (999 by
  ///   default), and "select all" on a 300-product shop is a realistic thing to
  ///   do.
  ///
  /// One transaction, and `customUpdate(updates: {products})` so the product
  /// stream re-runs — the rule `SalesDao` learned the hard way.
  ///
  /// Re-stamped for the same reason as [updatePriceAndCost]: a category the
  /// other phone never receives is a category that only half the shop has.
  Future<int> setAttributeOnProducts({
    required List<String> ids,
    required String jsonPath,
    required String value,
    required SyncStamp stamp,
  }) {
    if (ids.isEmpty) return Future.value(0);
    final clearing = value.trim().isEmpty;
    return transaction(() async {
      var changed = 0;
      for (var i = 0; i < ids.length; i += 200) {
        final chunk = ids.sublist(i, i + 200 > ids.length ? ids.length : i + 200);
        final holes = List.filled(chunk.length, '?').join(', ');
        changed += await customUpdate(
          clearing
              ? "UPDATE products SET attributes = "
                  "CASE WHEN NOT json_valid(attributes) THEN attributes "
                  "     WHEN json_remove(attributes, ?) = '{}' THEN '' "
                  '     ELSE json_remove(attributes, ?) END, '
                  'updated_at = ?, origin_device = ? '
                  'WHERE id IN ($holes)'
              : 'UPDATE products SET attributes = json_set('
                  "CASE WHEN json_valid(attributes) THEN attributes ELSE '{}' END, ?, ?), "
                  'updated_at = ?, origin_device = ? '
                  'WHERE id IN ($holes)',
          variables: [
            Variable.withString(jsonPath),
            Variable.withString(clearing ? jsonPath : value),
            Variable.withString(stamp.hlc),
            Variable.withString(stamp.device),
            for (final id in chunk) Variable.withString(id),
          ],
          updates: {products},
        );
      }
      return changed;
    });
  }
}
