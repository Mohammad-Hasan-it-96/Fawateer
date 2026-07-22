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
}
