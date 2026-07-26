import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/product.dart';

abstract class ProductRepository {
  Future<Either<Failure, List<Product>>> getProducts();

  /// Reactive stream of all products, updated on every write (incl. stock
  /// changes from a sale).
  Stream<List<Product>> watchProducts();
  Future<Either<Failure, Product>> getProductByBarcode(String barcode);

  /// Single product by id — used to resolve the SKU behind a scanned serial
  /// (Plan 012). Returns [NotFoundFailure] when the id is unknown.
  Future<Either<Failure, Product>> getProductById(String id);
  Future<Either<Failure, void>> addProduct(Product product);
  Future<Either<Failure, void>> updateProduct(Product product);
  Future<Either<Failure, void>> deleteProduct(String id);
}
