import 'package:billing_app/core/currency/exchange_rate_service.dart';
import 'package:billing_app/core/settings/inventory_settings_service.dart';
import 'package:billing_app/core/settings/print_settings_service.dart';
import 'package:billing_app/core/error/failure.dart';
import 'package:billing_app/features/billing/domain/repositories/invoice_repository.dart';
import 'package:billing_app/features/billing/presentation/bloc/billing_bloc.dart';
import 'package:billing_app/features/product/domain/entities/product.dart';
import 'package:billing_app/features/product/domain/entities/product_unit.dart';
import 'package:billing_app/features/product/domain/repositories/product_repository.dart';
import 'package:billing_app/features/product/domain/repositories/product_unit_repository.dart';
import 'package:billing_app/features/attributes/domain/entities/attribute_definition.dart';
import 'package:billing_app/features/attributes/domain/repositories/attribute_definition_repository.dart';
import 'package:billing_app/features/settings/domain/repositories/printer_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

/// Catalogue keyed by barcode, so a test can "create" a product mid-scenario
/// exactly as the add-product page does.
class _FakeProductRepository implements ProductRepository {
  final Map<String, Product> byBarcode = {};

  /// Barcodes the shop deliberately shares between two products (Plan 015
  /// Case A). Takes precedence over [byBarcode] when set.
  final Map<String, List<Product>> sharedBarcodes = {};

  @override
  Future<Either<Failure, List<Product>>> getProductsByBarcode(
      String barcode) async {
    final shared = sharedBarcodes[barcode];
    if (shared != null) return Right(shared);
    final product = byBarcode[barcode];
    if (product == null) {
      return Left(NotFoundFailure('no product for $barcode'));
    }
    return Right([product]);
  }

  @override
  noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not used by this test');
}

/// Serialized inventory fake (Plan 012). Holds no units by default, so the
/// second scan path finds nothing and these barcode tests keep their original
/// behavior.
class _FakeProductUnitRepository implements ProductUnitRepository {
  @override
  Future<Either<Failure, ProductUnit>> findBySerial(String serial) async =>
      const Left(NotFoundFailure('serial_not_found'));

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

class _FakePrintSettingsService implements PrintSettingsService {
  @override
  Future<bool> isPrintButtonEnabled() async => true;

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

/// A zero-qty item with no low-stock alert — still counts as out of stock (the
/// shop wants to know whenever quantity is zero, tracked or not).
Product _zeroNoAlert(String id, String barcode) => Product(
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
      printSettingsService: _FakePrintSettingsService(),
      attributeRepository: _FakeAttributeDefinitionRepository(),
      productUnitRepository: _FakeProductUnitRepository(),
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

  test('scanning any zero-qty product flags out-of-stock, even with no alert',
      () async {
    products.byBarcode['L'] = _zeroNoAlert('l1', 'L');
    bloc.add(const ScanBarcodeEvent('L'));
    await bloc.stream.firstWhere((s) => s.cartItems.isNotEmpty).timeout(
          const Duration(seconds: 2),
          onTimeout: () => throw StateError('item never reached the cart'),
        );

    expect(bloc.state.outOfStockScan?.id, 'l1',
        reason: 'zero quantity is out of stock regardless of a low-stock alert');
  });

  test('scanning an in-stock product does not flag out-of-stock', () async {
    products.byBarcode['S'] = _product('s1', 'S'); // quantity 10
    bloc.add(const ScanBarcodeEvent('S'));
    await bloc.stream.firstWhere((s) => s.cartItems.isNotEmpty).timeout(
          const Duration(seconds: 2),
          onTimeout: () => throw StateError('item never reached the cart'),
        );

    expect(bloc.state.outOfStockScan, isNull);
  });

  group('editing a product from the cart (Plan 013 #4)', () {
    Future<void> scanOne() async {
      products.byBarcode['E'] = _product('e1', 'E'); // price 1000
      bloc.add(const ScanBarcodeEvent('E'));
      await bloc.stream.firstWhere((s) => s.cartItems.isNotEmpty).timeout(
            const Duration(seconds: 2),
            onTimeout: () => throw StateError('item never reached the cart'),
          );
    }

    test('the open line takes the new price', () async {
      await scanOne();
      expect(bloc.state.cartItems.single.unitPriceSp, 1000);

      bloc.add(RefreshCartProductEvent(
          _product('e1', 'E').copyWith(price: 1500)));
      await bloc.stream
          .firstWhere((s) => s.cartItems.single.unitPriceSp == 1500);

      // The cashier edited the product *from this cart, to fix this sale*.
      // Leaving the line at the old price would look exactly like the edit
      // did not save.
      expect(bloc.state.cartItems.single.unitPriceSp, 1500);
    });

    test('the quantity and the line discount survive the edit', () async {
      await scanOne();
      bloc.add(const UpdateQuantityEvent('e1', 4));
      await bloc.stream.firstWhere((s) => s.cartItems.single.quantity == 4);
      bloc.add(const SetLineDiscountEvent('e1', 250));
      await bloc.stream.firstWhere((s) => s.cartItems.single.discount == 250);

      bloc.add(RefreshCartProductEvent(
          _product('e1', 'E').copyWith(price: 1500)));
      await bloc.stream
          .firstWhere((s) => s.cartItems.single.unitPriceSp == 1500);

      // The product changed; this sale's line did not. Losing four units or a
      // negotiated discount would be a silent overcharge.
      expect(bloc.state.cartItems.single.quantity, 4);
      expect(bloc.state.cartItems.single.discount, 250);
    });

    test('other lines are left alone', () async {
      await scanOne();
      products.byBarcode['F'] = _product('f1', 'F');
      bloc.add(const ScanBarcodeEvent('F'));
      await bloc.stream.firstWhere((s) => s.cartItems.length == 2);

      bloc.add(RefreshCartProductEvent(
          _product('e1', 'E').copyWith(price: 9999)));
      await bloc.stream.firstWhere(
          (s) => s.cartItems.any((i) => i.unitPriceSp == 9999));

      final other =
          bloc.state.cartItems.firstWhere((i) => i.product.id == 'f1');
      expect(other.unitPriceSp, 1000);
    });

    test('a product edited to zero stock updates the warning', () async {
      await scanOne();
      bloc.add(RefreshCartProductEvent(_zeroNoAlert('e1', 'E')));
      await bloc.stream
          .firstWhere((s) => s.cartItems.single.product.quantity == 0);

      // The cart's stock warnings are derived from the line's product
      // snapshot, so a stale snapshot would keep claiming stock the shop no
      // longer has.
      expect(bloc.state.cartItems.single.product.isOutOfStock, isTrue);
    });
  });

  group('one barcode, two products (Plan 015 Case A)', () {
    Product priced(String id, double price) => Product(
          id: id,
          name: 'دخان',
          price: price,
          quantity: 5,
          barcode: 'CIG',
        );

    test('a shared barcode asks instead of guessing', () async {
      // Guessing would silently ring the wrong price, and the shop would only
      // find out when the till disagreed with the shelf at closing time.
      products.sharedBarcodes['CIG'] = [priced('a', 5000), priced('b', 6000)];

      bloc.add(const ScanBarcodeEvent('CIG'));
      await bloc.stream.firstWhere((s) => s.barcodeChoices.isNotEmpty);

      expect(bloc.state.barcodeChoices.map((p) => p.id), ['a', 'b']);
      // Nothing is added until the cashier answers.
      expect(bloc.state.cartItems, isEmpty);
    });

    test('a single match still adds straight away', () async {
      // The common case must not grow a tap. Only a genuinely ambiguous code
      // asks; every other product in the shop behaves exactly as before.
      products.byBarcode['ONE'] = priced('c', 1000);

      bloc.add(const ScanBarcodeEvent('ONE'));
      await bloc.stream.firstWhere((s) => s.cartItems.isNotEmpty);

      expect(bloc.state.barcodeChoices, isEmpty);
      expect(bloc.state.cartItems.single.product.id, 'c');
    });

    test('the chooser clears, so it cannot reopen on the next rebuild',
        () async {
      products.sharedBarcodes['CIG'] = [priced('a', 5000), priced('b', 6000)];
      bloc.add(const ScanBarcodeEvent('CIG'));
      await bloc.stream.firstWhere((s) => s.barcodeChoices.isNotEmpty);

      bloc.add(const ClearBarcodeChoicesEvent());
      await bloc.stream.firstWhere((s) => s.barcodeChoices.isEmpty);

      expect(bloc.state.barcodeChoices, isEmpty);
    });

    test('a shared barcode never reports "product not found"', () async {
      // The serial fallback runs only when the barcode lookup fails; two
      // matches is a success, so it must not fall through to the not-found
      // path and send the cashier hunting a shelf.
      products.sharedBarcodes['CIG'] = [priced('a', 5000), priced('b', 6000)];

      bloc.add(const ScanBarcodeEvent('CIG'));
      await bloc.stream.firstWhere((s) => s.barcodeChoices.isNotEmpty);

      expect(bloc.state.error, isNull);
    });
  });
}
