import 'package:drift/drift.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/products_dao.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';

class ProductRepositoryDriftImpl implements ProductRepository {
  final ProductsDao _dao;

  const ProductRepositoryDriftImpl(this._dao);

  // ── mapping helpers ───────────────────────────────────────────────────────

  static Product _toEntity(ProductRow row) => Product(
        id: row.id,
        name: row.name,
        barcode: row.barcode,
        price: row.price,
        cost: row.cost,
        quantity: row.quantity,
        minStockAlert: row.minStockAlert,
      );

  static ProductsCompanion _toCompanion(Product p) => ProductsCompanion(
        id: Value(p.id),
        name: Value(p.name),
        barcode: Value(p.barcode),
        price: Value(p.price),
        cost: Value(p.cost),
        quantity: Value(p.quantity),
        minStockAlert: Value(p.minStockAlert),
      );

  // ── repository interface ──────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<Product>>> getProducts() async {
    try {
      final rows = await _dao.getAllProducts();
      return Right(rows.map(_toEntity).toList());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Stream<List<Product>> watchProducts() =>
      _dao.watchAllProducts().map((rows) => rows.map(_toEntity).toList());

  @override
  Future<Either<Failure, Product>> getProductByBarcode(String barcode) async {
    try {
      final row = await _dao.getByBarcode(barcode);
      if (row == null) {
        return Left(NotFoundFailure('No product for barcode: $barcode'));
      }
      return Right(_toEntity(row));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addProduct(Product product) async {
    try {
      await _dao.createProduct(_toCompanion(product));
      return const Right(null);
    } catch (e) {
      // A non-empty barcode that already exists trips the partial-unique index.
      if (e.toString().contains('UNIQUE')) {
        return const Left(
            DuplicateFailure('A product with this barcode already exists'));
      }
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateProduct(Product product) async {
    try {
      await _dao.insertProduct(_toCompanion(product)); // insertOrReplace
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteProduct(String id) async {
    try {
      await _dao.deleteProduct(id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}

