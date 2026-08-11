import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/product.dart';

abstract class ProductRepository {
  Future<Either<Failure, List<Product>>> getProducts();

  /// Reactive stream of all products, updated on every write (incl. stock
  /// changes from a sale).
  Stream<List<Product>> watchProducts();
  /// Every product carrying [barcode] — usually one, but since Plan 015 Case A
  /// a shop may deliberately hold two at different prices. An empty list is a
  /// [NotFoundFailure]; the caller decides what to do with more than one.
  Future<Either<Failure, List<Product>>> getProductsByBarcode(String barcode);

  /// Single product by id — used to resolve the SKU behind a scanned serial
  /// (Plan 012). Returns [NotFoundFailure] when the id is unknown.
  Future<Either<Failure, Product>> getProductById(String id);
  Future<Either<Failure, void>> addProduct(Product product);
  Future<Either<Failure, void>> updateProduct(Product product);
  Future<Either<Failure, void>> deleteProduct(String id);

  /// Write the price and cost of many products in one transaction (Plan 015
  /// B2.2 — bulk price edit). Takes whole entities but **saves only price and
  /// cost**; nothing else on the passed products is written, so a stale name or
  /// quantity in the caller's copy cannot overwrite the real row.
  Future<Either<Failure, void>> updatePrices(List<Product> products);

  /// Set one custom-field value on many products in a single transaction —
  /// bulk category assign (Plan 014 step 2). A blank [value] clears the field,
  /// which is how products are moved back to the "no category" bucket.
  Future<Either<Failure, void>> setAttributeOnProducts({
    required List<String> productIds,
    required String definitionId,
    required String value,
  });
}
