import 'package:drift/drift.dart';
import 'package:fpdart/fpdart.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/attributes/product_attributes.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/products_dao.dart';
import '../../../../core/database/daos/stock_dao.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/sync/sync_clock.dart';
import '../../../attributes/domain/product_category.dart';
import '../../domain/entities/price_currency.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/product_sale_type.dart';
import '../../domain/entities/stock_movement_reason.dart';
import '../../domain/repositories/product_repository.dart';

class ProductRepositoryDriftImpl implements ProductRepository {
  final ProductsDao _dao;
  final StockDao _stock;
  final SyncClock _clock;

  const ProductRepositoryDriftImpl(this._dao, this._stock, this._clock);

  // ── mapping helpers ───────────────────────────────────────────────────────

  static Product _toEntity(ProductRow row) => Product(
        id: row.id,
        name: row.name,
        barcode: row.barcode,
        price: row.price,
        cost: row.cost,
        quantity: row.quantity,
        minStockAlert: row.minStockAlert,
        saleType: ProductSaleType.fromName(row.saleType),
        priceCurrency: PriceCurrency.fromName(row.priceCurrency),
        attributes: ProductAttributes.fromJson(row.attributes),
        isSerialized: row.isSerialized,
      );

  /// **`quantity` is deliberately absent.** It is a cache of the stock movement
  /// log (Plan 002, Phase 0) and is written only by `StockDao`'s recompute.
  /// Including it here would let a product save overwrite on-hand with whatever
  /// number the form was showing — the last-write-wins scalar the movement log
  /// exists to eliminate — and would silently erase any sale made while the
  /// edit screen was open.
  static ProductsCompanion _toCompanion(Product p, SyncStamp stamp) =>
      ProductsCompanion(
        id: Value(p.id),
        name: Value(p.name),
        barcode: Value(p.barcode),
        price: Value(p.price),
        cost: Value(p.cost),
        minStockAlert: Value(p.minStockAlert),
        saleType: Value(p.saleType.name),
        priceCurrency: Value(p.priceCurrency.name),
        attributes: Value(p.attributes.toJson()),
        isSerialized: Value(p.isSerialized),

        // **The sync stamp, on every write.** Without it `updated_at` stays ''
        // — the "predates sync, never push me" marker — so the row is silently
        // invisible to `SyncDao.collectSince` and never leaves this phone. That
        // was the shipped state: deletes and sales were stamped, ordinary
        // creates and edits were not, so a shop could add a product on one till
        // and watch the other till never hear about it while every screen
        // reported success (found in a two-phone field test, 2026-09-01).
        updatedAt: Value(stamp.hlc),
        originDevice: Value(stamp.device),
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
  Future<Either<Failure, Product>> getProductById(String id) async {
    try {
      final row = await _dao.getById(id);
      if (row == null) {
        return Left(NotFoundFailure('No product for id: $id'));
      }
      return Right(_toEntity(row));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Product>>> getProductsByBarcode(
      String barcode) async {
    try {
      final rows = await _dao.getAllByBarcode(barcode);
      if (rows.isEmpty) {
        return Left(NotFoundFailure('No product for barcode: $barcode'));
      }
      return Right(rows.map(_toEntity).toList());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addProduct(Product product) async {
    try {
      await _dao.createProduct(_toCompanion(product, await _clock.stamp()));
      // Whatever stock the owner typed on the add form becomes the product's
      // opening balance — an event, so a second device adding the same product
      // offline contributes its own movement instead of overwriting this one.
      await _applyQuantity(product, StockMovementReason.openingBalance);
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
      await _dao.insertProduct(
          _toCompanion(product, await _clock.stamp())); // insertOrReplace
      // The edit form's quantity field is a *correction*, recorded as the
      // difference from what the log currently says. Serialized products send
      // their unchanged on-hand (the field is read-only for them), so this is a
      // no-op there and units stay the sole authority.
      await _applyQuantity(product, StockMovementReason.adjustment);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Move a product's on-hand to what the form asked for, by recording the
  /// difference. No-op for a serialized product, whose stock is owned by its
  /// units — writing a movement there would give it two disagreeing authorities.
  Future<void> _applyQuantity(
      Product product, StockMovementReason reason) async {
    if (product.isSerialized) {
      await _stock.recomputeQuantity(product.id);
      return;
    }
    await _stock.setOnHand(
      productId: product.id,
      target: product.quantity,
      movementId: const Uuid().v4(),
      reason: reason.name,
      now: DateTime.now().millisecondsSinceEpoch,
      stamp: await _clock.stamp(),
    );
  }

  @override
  Future<Either<Failure, void>> updatePrices(List<Product> products) async {
    if (products.isEmpty) return const Right(null);
    try {
      await _dao.updatePriceAndCost([
        for (final p in products) (id: p.id, price: p.price, cost: p.cost),
      ], await _clock.stamp());
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> setAttributeOnProducts({
    required List<String> productIds,
    required String definitionId,
    required String value,
  }) async {
    if (productIds.isEmpty) return const Right(null);
    try {
      await _dao.setAttributeOnProducts(
        ids: productIds,
        jsonPath: attributeJsonPath(definitionId),
        value: value,
        stamp: await _clock.stamp(),
      );
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteProduct(String id) async {
    try {
      await _dao.softDeleteProduct(id, await _clock.stamp());
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}

