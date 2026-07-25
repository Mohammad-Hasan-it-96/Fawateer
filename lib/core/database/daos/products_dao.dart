import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/products_table.dart';

part 'products_dao.g.dart';

@DriftAccessor(tables: [Products])
class ProductsDao extends DatabaseAccessor<AppDatabase>
    with _$ProductsDaoMixin {
  ProductsDao(super.db);

  /// Fetch all products once.
  Future<List<ProductRow>> getAllProducts() => select(products).get();

  /// Reactive stream of all products, newest-added first (Plan 011 #5).
  /// Ordered by descending rowid — monotonic with insertion order here, so a
  /// just-added product surfaces at the top of the list with no createdAt
  /// column / migration.
  Stream<List<ProductRow>> watchAllProducts() =>
      (select(products)..orderBy([(p) => OrderingTerm.desc(p.rowId)])).watch();

  /// Find a single product by barcode (or null if not found).
  Future<ProductRow?> getByBarcode(String barcode) =>
      (select(products)..where((p) => p.barcode.equals(barcode)))
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

  /// Delete a product by its [id]. Returns the number of deleted rows.
  Future<int> deleteProduct(String id) =>
      (delete(products)..where((p) => p.id.equals(id))).go();
}

