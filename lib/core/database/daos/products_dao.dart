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
}
