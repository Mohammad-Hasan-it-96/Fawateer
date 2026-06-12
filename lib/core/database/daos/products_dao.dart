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

  /// Reactive stream of all products.
  Stream<List<ProductRow>> watchAllProducts() => select(products).watch();

  /// Find a single product by barcode (or null if not found).
  Future<ProductRow?> getByBarcode(String barcode) =>
      (select(products)..where((p) => p.barcode.equals(barcode)))
          .getSingleOrNull();

  /// Insert or replace (used for both add and update).
  Future<void> insertProduct(ProductsCompanion product) =>
      into(products).insert(product, mode: InsertMode.insertOrReplace);

  /// Delete a product by its [id]. Returns the number of deleted rows.
  Future<int> deleteProduct(String id) =>
      (delete(products)..where((p) => p.id.equals(id))).go();
}

