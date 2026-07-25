import 'package:billing_app/core/currency/exchange_rate_service.dart';
import 'package:billing_app/core/settings/inventory_settings_service.dart';
import 'package:billing_app/core/error/failure.dart';
import 'package:billing_app/features/billing/domain/repositories/invoice_repository.dart';
import 'package:billing_app/features/billing/presentation/bloc/billing_bloc.dart';
import 'package:billing_app/features/product/domain/entities/product.dart';
import 'package:billing_app/features/product/domain/repositories/product_repository.dart';
import 'package:billing_app/features/attributes/domain/entities/attribute_definition.dart';
import 'package:billing_app/features/attributes/domain/repositories/attribute_definition_repository.dart';
import 'package:billing_app/features/settings/domain/repositories/printer_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

/// Catalogue keyed by barcode, so a test can "create" a product mid-scenario
/// exactly as the add-product page does.
class _FakeProductRepository implements ProductRepository {
  final Map<String, Product> byBarcode = {};

  @override
  Future<Either<Failure, Product>> getProductByBarcode(String barcode) async {
    final product = byBarcode[barcode];
    if (product == null) {
      return Left(NotFoundFailure('no product for $barcode'));
    }
    return Right(product);
  }

  @override
  noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not used by this test');
}

class _FakePrinterRepository implements PrinterRepository {
  @override
  noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not used by this test');
}

class _FakeInvoiceRepository implements InvoiceRepository {
  @override
  noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not used by this test');
}

class _FakeExchangeRateService implements ExchangeRateService {
  @override
  Future<double?> getRate() async => null;

  @override
  noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not used by this test');
}

class _FakeAttributeDefinitionRepository
    implements AttributeDefinitionRepository {
  @override
  Stream<List<AttributeDefinition>> watchDefinitions() =>
      Stream.value(const []);

  @override
  noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not used by this test');
}

class _FakeInventorySettingsService implements InventorySettingsService {
  @override
  Future<bool> isBlockOversellEnabled() async => false;

  @override
  noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not used by this test');
}

Product _product(String id, String barcode) => Product(
      id: id,
      name: 'Item $id',
      price: 1000,
      quantity: 10,
      barcode: barcode,
    );

/// A stock-tracked item (owner set a low-stock alert) that has run out.
Product _outOfStock(String id, String barcode) => Product(
      id: id,
      name: 'Item $id',
      price: 1000,
      quantity: 0,
      minStockAlert: 5,
      barcode: barcode,
    );

/// An untracked loose/produce item at zero — no alert set, so it must NOT read
/// as "out of stock" (it sits at 0 forever).
Product _untracked(String id, String barcode) => Product(
      id: id,
      name: 'Item $id',
      price: 1000,
      quantity: 0,
      barcode: barcode,
    );

void main() {
  late _FakeProductRepository products;
  late BillingBloc bloc;

  setUp(() {
    products = _FakeProductRepository();
    bloc = BillingBloc(
      productRepository: products,
      printerRepository: _FakePrinterRepository(),
      invoiceRepository: _FakeInvoiceRepository(),
      exchangeRateService: _FakeExchangeRateService(),
      inventorySettingsService: _FakeInventorySettingsService(),
      attributeRepository: _FakeAttributeDefinitionRepository(),
    );
  });

  tearDown(() => bloc.close());

  test('scanning an unknown barcode reports it so the UI can offer to add it',
      () async {
    bloc.add(const ScanBarcodeEvent('X'));
    await bloc.stream.firstWhere((s) => s.error != null);

    expect(bloc.state.error, BillingError.productNotFound);
    expect(bloc.state.errorBarcode, 'X');
  });

  test('re-scanning the SAME unknown barcode notifies again', () async {
    bloc.add(const ScanBarcodeEvent('X'));
    await bloc.stream.firstWhere((s) => s.errorBarcode == 'X');

    // The second scan must reach the UI too. A state identical to the current
    // one is swallowed by bloc, which would make the scan a silent no-op.
    var emissions = 0;
    final sub = bloc.stream.listen((_) => emissions++);
    bloc.add(const ScanBarcodeEvent('X'));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await sub.cancel();

    expect(emissions, greaterThan(0),
        reason: 'second scan of the same unknown barcode emitted nothing');
  });

  test('scanning a barcode created after the failed scan adds it to the cart',
      () async {
    // 1. Scan an unknown barcode.
    bloc.add(const ScanBarcodeEvent('X'));
    await bloc.stream.firstWhere((s) => s.errorBarcode == 'X');

    // 2. The user creates the product with that barcode.
    products.byBarcode['X'] = _product('p1', 'X');

    // 3. Scanning it again must put it in the cart.
    bloc.add(const ScanBarcodeEvent('X'));
    await bloc.stream.firstWhere((s) => s.cartItems.isNotEmpty).timeout(
          const Duration(seconds: 2),
          onTimeout: () => throw StateError('product never reached the cart'),
        );

    expect(bloc.state.cartItems.single.product.id, 'p1');
    expect(bloc.state.error, isNull);
  });

  // Plan 011 #4: the just-touched line must sit at the TOP of the cart so it
  // stays visible for price confirmation on a long cart.
  test('a newly added product is prepended to the top of the cart', () async {
    bloc.add(AddProductToCartEvent(_product('a', 'A')));
    await bloc.stream.firstWhere((s) => s.cartItems.length == 1);
    bloc.add(AddProductToCartEvent(_product('b', 'B')));
    await bloc.stream.firstWhere((s) => s.cartItems.length == 2);

    expect(bloc.state.cartItems.map((i) => i.product.id).toList(), ['b', 'a'],
        reason: 'newest add belongs on top');
  });

  test('re-adding an existing line moves it to the top and bumps its quantity',
      () async {
    bloc.add(AddProductToCartEvent(_product('a', 'A')));
    await bloc.stream.firstWhere((s) => s.cartItems.length == 1);
    bloc.add(AddProductToCartEvent(_product('b', 'B')));
    await bloc.stream.firstWhere((s) => s.cartItems.length == 2);
    // Re-add 'a' (currently at the bottom) — it should jump to the top.
    bloc.add(AddProductToCartEvent(_product('a', 'A')));
    await bloc.stream
        .firstWhere((s) => s.cartItems.first.product.id == 'a');

    expect(bloc.state.cartItems.map((i) => i.product.id).toList(), ['a', 'b']);
    expect(bloc.state.cartItems.first.quantity, 2,
        reason: 're-add increments the existing line, not a duplicate');
  });

  // Plan 011 #8: a finished, stock-tracked item must be flagged loudly so the
  // shopkeeper knows — but still added, since overselling is allowed.
  test('scanning a tracked out-of-stock product flags it AND still adds to cart',
      () async {
    products.byBarcode['Z'] = _outOfStock('z1', 'Z');
    bloc.add(const ScanBarcodeEvent('Z'));
    await bloc.stream.firstWhere((s) => s.cartItems.isNotEmpty).timeout(
          const Duration(seconds: 2),
          onTimeout: () => throw StateError('item never reached the cart'),
        );

    expect(bloc.state.cartItems.single.product.id, 'z1',
        reason: 'overselling is allowed — the item is still added');
    expect(bloc.state.outOfStockScan?.id, 'z1',
        reason: 'the finished item must be flagged for the red notice');
  });

  test('scanning an untracked zero-qty product does not flag out-of-stock',
      () async {
    products.byBarcode['L'] = _untracked('l1', 'L');
    bloc.add(const ScanBarcodeEvent('L'));
    await bloc.stream.firstWhere((s) => s.cartItems.isNotEmpty).timeout(
          const Duration(seconds: 2),
          onTimeout: () => throw StateError('item never reached the cart'),
        );

    expect(bloc.state.outOfStockScan, isNull,
        reason: 'untracked loose items sit at 0 forever — no nag');
  });
}
