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
  /// Single product by primary key — the SKU behind a scanned serial (Plan 012).
  Future<ProductRow?> getById(String id) =>
      (select(products)..where((p) => p.id.equals(id))).getSingleOrNull();

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
  Future<void> updatePriceAndCost(
          List<({String id, double price, double cost})> edits) =>
      batch((b) {
        for (final e in edits) {
          b.update(
            products,
            ProductsCompanion(price: Value(e.price), cost: Value(e.cost)),
            where: (p) => p.id.equals(e.id),
          );
        }
      });

  /// Delete a product by its [id]. Returns the number of deleted rows.
  Future<int> deleteProduct(String id) =>
      (delete(products)..where((p) => p.id.equals(id))).go();
}
