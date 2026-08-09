// Smoke tests for the refactored core flows. These drive the BLoCs against
// in-memory fake repositories (no Drift / native SQLite / plugins), so they run
// reliably under `flutter test` and guard the architecture refactor:
//   - BLoCs depend on repository interfaces directly (no use-case layer)
//   - sale confirmation persists via a single saveInvoice call (atomic record)
//   - errors are surfaced as typed enums, never English strings
//   - product list & history are driven by repository streams
import 'dart:async';

import 'package:billing_app/core/currency/exchange_rate_service.dart';
import 'package:billing_app/core/settings/inventory_settings_service.dart';
import 'package:billing_app/core/settings/print_settings_service.dart';
import 'package:billing_app/core/error/failure.dart';
import 'package:billing_app/features/billing/domain/entities/invoice.dart';
import 'package:billing_app/features/billing/domain/entities/invoice_item.dart';
import 'package:billing_app/features/billing/domain/entities/invoice_list_item.dart';
import 'package:billing_app/features/billing/domain/entities/sales_filter.dart';
import 'package:billing_app/features/billing/domain/entities/sales_summary.dart';
import 'package:billing_app/features/billing/domain/repositories/invoice_repository.dart';
import 'package:billing_app/features/billing/presentation/bloc/billing_bloc.dart';
import 'package:billing_app/features/billing/presentation/bloc/history_bloc.dart';
import 'package:billing_app/features/product/domain/entities/price_currency.dart';
import 'package:billing_app/features/product/domain/entities/product.dart';
import 'package:billing_app/features/product/domain/entities/product_unit.dart';
import 'package:billing_app/features/product/domain/repositories/product_repository.dart';
import 'package:billing_app/features/product/domain/repositories/product_unit_repository.dart';
import 'package:billing_app/core/attributes/product_attributes.dart';
import 'package:billing_app/features/attributes/domain/entities/attribute_definition.dart';
import 'package:billing_app/features/attributes/domain/repositories/attribute_definition_repository.dart';
import 'package:billing_app/features/product/presentation/bloc/product_bloc.dart';
import 'package:billing_app/features/settings/domain/entities/printer_device.dart';
import 'package:billing_app/features/settings/domain/entities/receipt_line.dart';
import 'package:billing_app/features/settings/domain/repositories/printer_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_test/flutter_test.dart';

const _timeout = Duration(seconds: 2);

Product _product({
  String id = 'p1',
  String barcode = '123',
  double price = 10,
  double quantity = 5,
}) =>
    Product(id: id, name: 'Test', barcode: barcode, price: price, quantity: quantity);

// ── Fakes ───────────────────────────────────────────────────────────────────

/// Configurable rate fake. Defaults to null (unset) — the SP-only BillingBloc
/// tests never consult it; the dual-currency tests pass an explicit rate.
class _FakeExchangeRateService implements ExchangeRateService {
  final double? rate;
  _FakeExchangeRateService({this.rate});
  @override
  Future<double?> getRate() async => rate;
  @override
  Future<DateTime?> getUpdatedAt() async => null;
  @override
  Future<void> setRate(double rate) async {}
}

/// Custom-fields fake. Defaults to no definitions; pass `defs:` to exercise the
/// receipt-attribute snapshot (Plan 010).
class _FakeAttributeDefinitionRepository
    implements AttributeDefinitionRepository {
  final List<AttributeDefinition> defs;
  _FakeAttributeDefinitionRepository({this.defs = const []});

  @override
  Stream<List<AttributeDefinition>> watchDefinitions() => Stream.value(defs);

  @override
  noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not used by this test');
}

/// Strict-inventory flag fake. Defaults to off (overselling allowed), matching
/// the app default; pass `block: true` to exercise the checkout stock gate.
class _FakeInventorySettingsService implements InventorySettingsService {
  final bool block;
  _FakeInventorySettingsService({this.block = false});
  @override
  Future<bool> isBlockOversellEnabled() async => block;
  @override
  Future<void> setBlockOversell(bool enabled) async {}
}

class _FakePrintSettingsService implements PrintSettingsService {
  final bool enabled;
  _FakePrintSettingsService({this.enabled = true});
  @override
  Future<bool> isPrintButtonEnabled() async => enabled;
  @override
  Future<void> setPrintButtonEnabled(bool value) async {}
}

/// Serialized inventory fake (Plan 012). Defaults to holding no units, so the
/// POS's second scan path finds nothing and every pre-existing test keeps its
/// original barcode-only behavior.
class _FakeProductUnitRepository implements ProductUnitRepository {
  @override
  Future<Either<Failure, ProductUnit>> findBySerial(String serial) async =>
      const Left(NotFoundFailure('serial_not_found'));

  @override
  noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not used by this test');
}

class _FakeProductRepository implements ProductRepository {
  final Map<String, Product> byBarcode;
  // Single-subscription (not broadcast) so an emit() before the bloc subscribes
  // is buffered and delivered, instead of being dropped.
  final _controller = StreamController<List<Product>>();

  /// Result returned by [addProduct] — override to simulate a duplicate barcode.
  Either<Failure, void> addResult = const Right(null);

  _FakeProductRepository({this.byBarcode = const {}});

  void emit(List<Product> products) => _controller.add(products);
  Future<void> dispose() => _controller.close();

  @override
  Future<Either<Failure, Product>> getProductByBarcode(String barcode) async {
    final p = byBarcode[barcode];
    return p == null ? Left(NotFoundFailure('no $barcode')) : Right(p);
  }

  @override
  Future<Either<Failure, Product>> getProductById(String id) async {
    for (final p in byBarcode.values) {
      if (p.id == id) return Right(p);
    }
    return Left(NotFoundFailure('no id $id'));
  }

  @override
  Stream<List<Product>> watchProducts() => _controller.stream;

  @override
  Future<Either<Failure, List<Product>>> getProducts() async => const Right([]);
  @override
  Future<Either<Failure, void>> addProduct(Product product) async => addResult;
  @override
  Future<Either<Failure, void>> updateProduct(Product product) async =>
      const Right(null);
  @override
  Future<Either<Failure, void>> deleteProduct(String id) async =>
      const Right(null);
  @override
  Future<Either<Failure, void>> updatePrices(List<Product> products) async =>
      const Right(null);
}

class _FakeInvoiceRepository implements InvoiceRepository {
  final _controller = StreamController<List<Invoice>>();
  int saveCount = 0;
  Invoice? savedInvoice;
  List<InvoiceItem>? savedItems;

  /// Serialized units the sale consumed (Plan 012); empty for a normal sale.
  List<String> savedUnitIds = const [];
  String? savedCustomerId;

  /// Result returned by [getInvoiceItems] — override to simulate a load failure.
  Either<Failure, List<InvoiceItem>> itemsResult = const Right([]);

  // Audit-center streams. Broadcast + last-value replay so an emit that lands
  // before the bloc subscribes (or across a re-subscribe on filter change) is
  // still delivered.
  final _listController = StreamController<List<InvoiceListItem>>.broadcast();
  final _summaryController = StreamController<SalesSummary>.broadcast();
  List<InvoiceListItem>? _lastList;
  SalesSummary? _lastSummary;
  Object? _pendingListError;

  void emit(List<Invoice> invoices) => _controller.add(invoices);
  void emitError(Object e) => _controller.addError(e);
  void emitList(List<InvoiceListItem> items) {
    _lastList = items;
    _listController.add(items);
  }

  void emitListError(Object e) {
    _pendingListError = e; // replayed if the bloc subscribes after this
    _listController.addError(e);
  }

  void emitSummary(SalesSummary summary) {
    _lastSummary = summary;
    _summaryController.add(summary);
  }

  // Fire-and-forget: a never-listened single-subscription controller's close()
  // never completes, so don't await it (would hang the test).
  Future<void> dispose() async {
    unawaited(_controller.close());
    unawaited(_listController.close());
    unawaited(_summaryController.close());
  }

  @override
  Future<Either<Failure, void>> saveInvoice(
      Invoice invoice, List<InvoiceItem> items,
      {String? customerId, List<String> soldUnitIds = const []}) async {
    saveCount++;
    savedInvoice = invoice;
    savedItems = items;
    savedUnitIds = soldUnitIds;
    savedCustomerId = customerId;
    return const Right(null);
  }

  @override
  Stream<List<Invoice>> watchInvoices() => _controller.stream;

  @override
  Stream<List<InvoiceListItem>> watchFilteredInvoices(
    SalesFilter filter, {
    int limit = 30,
    int offset = 0,
  }) async* {
    if (_lastList != null) yield _lastList!;
    final err = _pendingListError;
    if (err != null) {
      _pendingListError = null;
      throw err; // an error emitted before we subscribed still reaches the bloc
    }
    yield* _listController.stream;
  }

  @override
  Stream<SalesSummary> watchSummary(SalesFilter filter) async* {
    if (_lastSummary != null) yield _lastSummary!;
    yield* _summaryController.stream;
  }

  @override
  Future<Either<Failure, List<Invoice>>> getAllInvoices() async =>
      const Right([]);
  @override
  Future<Either<Failure, List<InvoiceItem>>> getInvoiceItems(
          String invoiceId) async =>
      itemsResult;
  @override
  Future<Either<Failure, void>> deleteInvoice(String id) async =>
      const Right(null);
}

class _FakePrinterRepository implements PrinterRepository {
  final bool printerAvailable;
  int printReceiptCount = 0;

  _FakePrinterRepository({this.printerAvailable = false});

  @override
  Future<bool> printReceipt({
    required String shopName,
    required String address1,
    required String address2,
    required String phone,
    required String footer,
    required double total,
    required List<ReceiptLine> items,
    String currency = '',
  }) async {
    printReceiptCount++;
    return printerAvailable;
  }

  @override
  Future<Either<Failure, List<PrinterDevice>>> scanDevices() async =>
      const Right([]);
  @override
  Future<bool> printStatement(String text) async => printerAvailable;
  int printLabelCount = 0;
  @override
  Future<bool> printLabel({
    required String name,
    required String priceText,
    String barcodeData = '',
    bool useQr = false,
    int copies = 1,
  }) async {
    printLabelCount++;
    return printerAvailable;
  }

  @override
  Future<bool> connect(String macAddress) async => false;
  @override
  Future<bool> disconnect() async => true;
  @override
  Future<String?> getSavedPrinterMac() async => null;
  @override
  Future<String?> getSavedPrinterName() async => null;
  @override
  Future<void> savePrinterData(String mac, String name) async {}
  @override
  Future<void> clearPrinterData() async {}
  @override
  Future<void> testPrint(String shopName) async {}
}

// ── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('BillingBloc', () {
    test('unknown barcode → typed productNotFound error carrying the barcode',
        () async {
      final bloc = BillingBloc(
        productRepository: _FakeProductRepository(),
        printerRepository: _FakePrinterRepository(),
        invoiceRepository: _FakeInvoiceRepository(),
        exchangeRateService: _FakeExchangeRateService(),
        inventorySettingsService: _FakeInventorySettingsService(),
        printSettingsService: _FakePrintSettingsService(),
        attributeRepository: _FakeAttributeDefinitionRepository(),
        productUnitRepository: _FakeProductUnitRepository(),
      );
      final next = bloc.stream.firstWhere((s) => s.error != null);
      bloc.add(const ScanBarcodeEvent('999'));

      final state = await next.timeout(_timeout);
      expect(state.error, BillingError.productNotFound);
      expect(state.errorBarcode, '999');
      await bloc.close();
    });

    test('known barcode → product added to cart', () async {
      final bloc = BillingBloc(
        productRepository:
            _FakeProductRepository(byBarcode: {'123': _product()}),
        printerRepository: _FakePrinterRepository(),
        invoiceRepository: _FakeInvoiceRepository(),
        exchangeRateService: _FakeExchangeRateService(),
        inventorySettingsService: _FakeInventorySettingsService(),
        printSettingsService: _FakePrintSettingsService(),
        attributeRepository: _FakeAttributeDefinitionRepository(),
        productUnitRepository: _FakeProductUnitRepository(),
      );
      final next = bloc.stream.firstWhere((s) => s.cartItems.isNotEmpty);
      bloc.add(const ScanBarcodeEvent('123'));

      final state = await next.timeout(_timeout);
      expect(state.cartItems.single.product.id, 'p1');
      await bloc.close();
    });

    test('confirm sale → saveInvoice called once with the cart line items',
        () async {
      final invoiceRepo = _FakeInvoiceRepository();
      final bloc = BillingBloc(
        productRepository: _FakeProductRepository(),
        printerRepository: _FakePrinterRepository(),
        invoiceRepository: invoiceRepo,
        exchangeRateService: _FakeExchangeRateService(),
        inventorySettingsService: _FakeInventorySettingsService(),
        printSettingsService: _FakePrintSettingsService(),
        attributeRepository: _FakeAttributeDefinitionRepository(),
        productUnitRepository: _FakeProductUnitRepository(),
      );
      final confirmed = bloc.stream.firstWhere((s) => s.saleConfirmed);
      bloc.add(AddProductToCartEvent(_product()));
      bloc.add(const ConfirmSaleEvent(
        shopName: 'Shop',
        address1: '',
        address2: '',
        phone: '',
        footer: '',
      ));

      final state = await confirmed.timeout(_timeout);
      expect(state.saleConfirmed, isTrue);
      expect(invoiceRepo.saveCount, 1);
      expect(invoiceRepo.savedItems!.single.productId, 'p1');
      expect(invoiceRepo.savedItems!.single.quantity, 1.0);
      expect(invoiceRepo.savedCustomerId, isNull); // cash sale by default
      await bloc.close();
    });

    // Plan 011 #6: with printing turned off, a confirmed sale still saves but
    // must NOT attempt to print (and so never nags "printer not connected").
    test('printing disabled → confirmed sale saves but does not auto-print',
        () async {
      final invoiceRepo = _FakeInvoiceRepository();
      final printer = _FakePrinterRepository();
      final bloc = BillingBloc(
        productRepository: _FakeProductRepository(),
        printerRepository: printer,
        invoiceRepository: invoiceRepo,
        exchangeRateService: _FakeExchangeRateService(),
        inventorySettingsService: _FakeInventorySettingsService(),
        printSettingsService: _FakePrintSettingsService(enabled: false),
        attributeRepository: _FakeAttributeDefinitionRepository(),
        productUnitRepository: _FakeProductUnitRepository(),
      );
      // Startup loads the flag into state (as main.dart does).
      bloc.add(const LoadPrintSettingsEvent());
      await bloc.stream.firstWhere((s) => !s.printEnabled).timeout(_timeout);

      final confirmed = bloc.stream.firstWhere((s) => s.saleConfirmed);
      bloc.add(AddProductToCartEvent(_product()));
      bloc.add(const ConfirmSaleEvent(
          shopName: 'Shop', address1: '', address2: '', phone: '', footer: ''));
      await confirmed.timeout(_timeout);

      expect(invoiceRepo.saveCount, 1, reason: 'the sale still commits');
      expect(printer.printReceiptCount, 0,
          reason: 'no printer, so no auto-print attempt');
      await bloc.close();
    });

    test('show-on-receipt attributes are snapshotted onto the sale line',
        () async {
      final invoiceRepo = _FakeInvoiceRepository();
      final bloc = BillingBloc(
        productRepository: _FakeProductRepository(),
        printerRepository: _FakePrinterRepository(),
        invoiceRepository: invoiceRepo,
        exchangeRateService: _FakeExchangeRateService(),
        inventorySettingsService: _FakeInventorySettingsService(),
        printSettingsService: _FakePrintSettingsService(),
        attributeRepository: _FakeAttributeDefinitionRepository(defs: const [
          AttributeDefinition(
              id: 'color', label: 'اللون', showOnReceipt: true),
          AttributeDefinition(
              id: 'storage',
              label: 'السعة',
              unit: 'GB',
              showOnReceipt: true),
          // Not flagged for the receipt → must be excluded from the snapshot.
          AttributeDefinition(id: 'size', label: 'المقاس'),
        ]),
        productUnitRepository: _FakeProductUnitRepository(),
      );
      // Let the definitions subscription deliver before the sale.
      await Future<void>.delayed(Duration.zero);

      final product = _product().copyWith(
        attributes: ProductAttributes(
            const {'color': 'أسود', 'storage': '128', 'size': 'L'}),
      );
      final confirmed = bloc.stream.firstWhere((s) => s.saleConfirmed);
      bloc.add(AddProductToCartEvent(product));
      bloc.add(const ConfirmSaleEvent(
          shopName: 'Shop',
          address1: '',
          address2: '',
          phone: '',
          footer: ''));
      await confirmed.timeout(_timeout);

      final snap = invoiceRepo.savedItems!.single.attributesSnapshot;
      expect(snap, contains('اللون'));
      expect(snap, contains('أسود'));
      expect(snap, contains('128 GB')); // unit appended into the frozen value
      expect(snap, isNot(contains('المقاس'))); // not show-on-receipt
      await bloc.close();
    });

    test('credit sale → customerId forwarded to saveInvoice', () async {
      final invoiceRepo = _FakeInvoiceRepository();
      final bloc = BillingBloc(
        productRepository: _FakeProductRepository(),
        printerRepository: _FakePrinterRepository(),
        invoiceRepository: invoiceRepo,
        exchangeRateService: _FakeExchangeRateService(),
        inventorySettingsService: _FakeInventorySettingsService(),
        printSettingsService: _FakePrintSettingsService(),
        attributeRepository: _FakeAttributeDefinitionRepository(),
        productUnitRepository: _FakeProductUnitRepository(),
      );
      final confirmed = bloc.stream.firstWhere((s) => s.saleConfirmed);
      bloc.add(AddProductToCartEvent(_product()));
      bloc.add(const ConfirmSaleEvent(
        shopName: 'Shop',
        address1: '',
        address2: '',
        phone: '',
        footer: '',
        customerId: 'cust-1',
      ));

      await confirmed.timeout(_timeout);
      expect(invoiceRepo.saveCount, 1);
      expect(invoiceRepo.savedCustomerId, 'cust-1');
      await bloc.close();
    });

    test('print with no printer → typed printerUnavailable error', () async {
      final bloc = BillingBloc(
        productRepository: _FakeProductRepository(),
        printerRepository: _FakePrinterRepository(printerAvailable: false),
        invoiceRepository: _FakeInvoiceRepository(),
        exchangeRateService: _FakeExchangeRateService(),
        inventorySettingsService: _FakeInventorySettingsService(),
        printSettingsService: _FakePrintSettingsService(),
        attributeRepository: _FakeAttributeDefinitionRepository(),
        productUnitRepository: _FakeProductUnitRepository(),
      );
      final next = bloc.stream.firstWhere((s) => s.error != null);
      bloc.add(const PrintReceiptEvent(
        shopName: 'Shop',
        address1: '',
        address2: '',
        phone: '',
        footer: '',
      ));

      final state = await next.timeout(_timeout);
      expect(state.error, BillingError.printerUnavailable);
      await bloc.close();
    });

    test('overselling a tracked item warns; untracked stays silent', () async {
      final bloc = BillingBloc(
        productRepository: _FakeProductRepository(),
        printerRepository: _FakePrinterRepository(),
        invoiceRepository: _FakeInvoiceRepository(),
        exchangeRateService: _FakeExchangeRateService(),
        inventorySettingsService: _FakeInventorySettingsService(),
        printSettingsService: _FakePrintSettingsService(),
        attributeRepository: _FakeAttributeDefinitionRepository(),
        productUnitRepository: _FakeProductUnitRepository(),
      );

      // Tracked item, on-hand 1: selling 2 (add twice) must warn.
      const tracked = Product(
          id: 't1', name: 'Milk', barcode: '', price: 5, quantity: 1);
      final warned = bloc.stream.firstWhere((s) => s.lowStockWarnings.isNotEmpty);
      bloc.add(const AddProductToCartEvent(tracked));
      bloc.add(const AddProductToCartEvent(tracked));
      final s1 = await warned.timeout(_timeout);
      expect(s1.lowStockWarnings, contains('Milk'));

      // Untracked item (on-hand 0, no alert): selling it must NOT warn.
      bloc.add(ClearCartEvent());
      const untracked = Product(
          id: 'u1', name: 'Loose', barcode: '', price: 3, quantity: 0);
      final added = bloc.stream.firstWhere((s) => s.cartItems.isNotEmpty);
      bloc.add(const AddProductToCartEvent(untracked));
      final s2 = await added.timeout(_timeout);
      expect(s2.lowStockWarnings, isEmpty);
      await bloc.close();
    });

    test('strict inventory blocks a sold-out (0 on-hand) item; in-stock sells',
        () async {
      final invoiceRepo = _FakeInvoiceRepository();
      final bloc = BillingBloc(
        productRepository: _FakeProductRepository(),
        printerRepository: _FakePrinterRepository(),
        invoiceRepository: invoiceRepo,
        exchangeRateService: _FakeExchangeRateService(),
        inventorySettingsService: _FakeInventorySettingsService(block: true),
        printSettingsService: _FakePrintSettingsService(),
        attributeRepository: _FakeAttributeDefinitionRepository(),
        productUnitRepository: _FakeProductUnitRepository(),
      );

      // Startup loads the strict flag into state (as main.dart does).
      bloc.add(const LoadInventorySettingsEvent());
      await bloc.stream.firstWhere((s) => s.blockOversell).timeout(_timeout);

      // On-hand 0 → selling even a single unit must be refused. This is the
      // reported bug: strict mode has to block sold-out items, not just ones
      // with a leftover positive count or a low-stock alert.
      const soldOut = Product(
          id: 's1', name: 'Cola', barcode: '', price: 5, quantity: 0);
      bloc.add(const AddProductToCartEvent(soldOut));
      final blocked = bloc.stream
          .firstWhere((s) => s.error == BillingError.insufficientStock);
      bloc.add(const ConfirmSaleEvent(
          shopName: 'Shop', address1: '', address2: '', phone: '', footer: ''));
      await blocked.timeout(_timeout);
      expect(invoiceRepo.saveCount, 0);

      // Clearing the cart must NOT drop the strict flag (session setting); a
      // line within its stock still sells through under strict inventory.
      bloc.add(ClearCartEvent());
      const inStock = Product(
          id: 'i1', name: 'Rice', barcode: '', price: 3, quantity: 4);
      bloc.add(const AddProductToCartEvent(inStock));
      final confirmed = bloc.stream.firstWhere((s) => s.saleConfirmed);
      bloc.add(const ConfirmSaleEvent(
          shopName: 'Shop', address1: '', address2: '', phone: '', footer: ''));
      await confirmed.timeout(_timeout);
      expect(invoiceRepo.saveCount, 1);
      expect(bloc.state.blockOversell, isTrue);
      await bloc.close();
    });

    test('empty cart confirm → emptyCart error, nothing saved', () async {
      final invoiceRepo = _FakeInvoiceRepository();
      final bloc = BillingBloc(
        productRepository: _FakeProductRepository(),
        printerRepository: _FakePrinterRepository(),
        invoiceRepository: invoiceRepo,
        exchangeRateService: _FakeExchangeRateService(),
        inventorySettingsService: _FakeInventorySettingsService(),
        printSettingsService: _FakePrintSettingsService(),
        attributeRepository: _FakeAttributeDefinitionRepository(),
        productUnitRepository: _FakeProductUnitRepository(),
      );
      final errored = bloc.stream.firstWhere((s) => s.error != null);
      bloc.add(const ConfirmSaleEvent(
          shopName: 'Shop', address1: '', address2: '', phone: '', footer: ''));

      final state = await errored.timeout(_timeout);
      expect(state.error, BillingError.emptyCart);
      expect(state.saleConfirmed, isFalse);
      expect(invoiceRepo.saveCount, 0);
      await bloc.close();
    });

    test('double-tap confirm → invoice saved only once', () async {
      final invoiceRepo = _FakeInvoiceRepository();
      final bloc = BillingBloc(
        productRepository: _FakeProductRepository(),
        printerRepository: _FakePrinterRepository(),
        invoiceRepository: invoiceRepo,
        exchangeRateService: _FakeExchangeRateService(),
        inventorySettingsService: _FakeInventorySettingsService(),
        printSettingsService: _FakePrintSettingsService(),
        attributeRepository: _FakeAttributeDefinitionRepository(),
        productUnitRepository: _FakeProductUnitRepository(),
      );
      final confirmed = bloc.stream.firstWhere((s) => s.saleConfirmed);
      bloc.add(AddProductToCartEvent(_product()));
      // Two confirms enqueued back-to-back (double tap).
      const confirm = ConfirmSaleEvent(
          shopName: 'Shop', address1: '', address2: '', phone: '', footer: '');
      bloc.add(confirm);
      bloc.add(confirm);

      await confirmed.timeout(_timeout);
      // Let any second handler run before asserting.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(invoiceRepo.saveCount, 1);
      await bloc.close();
    });

    test('USD product is priced into whole SP at the loaded rate', () async {
      final invoiceRepo = _FakeInvoiceRepository();
      final bloc = BillingBloc(
        productRepository: _FakeProductRepository(),
        printerRepository: _FakePrinterRepository(),
        invoiceRepository: invoiceRepo,
        exchangeRateService: _FakeExchangeRateService(rate: 15000),
        inventorySettingsService: _FakeInventorySettingsService(),
        printSettingsService: _FakePrintSettingsService(),
        attributeRepository: _FakeAttributeDefinitionRepository(),
        productUnitRepository: _FakeProductUnitRepository(),
      );
      bloc.add(const LoadExchangeRateEvent());
      await bloc.stream
          .firstWhere((s) => s.exchangeRate == 15000)
          .timeout(_timeout);

      const usd = Product(
          id: 'd1',
          name: 'Phone',
          barcode: '',
          price: 10, // $10
          quantity: 5,
          priceCurrency: PriceCurrency.usd);
      final added = bloc.stream.firstWhere((s) => s.cartItems.isNotEmpty);
      bloc.add(const AddProductToCartEvent(usd));
      final s = await added.timeout(_timeout);

      // $10 × 15000 = 150,000 SP, settled and totalled in SP.
      expect(s.cartItems.single.unitPriceSp, 150000);
      expect(s.totalAmount, 150000);
      expect(s.hasUnpricedItems, isFalse);

      // The sale persists SP price + the FX snapshot for audit.
      final confirmed = bloc.stream.firstWhere((s) => s.saleConfirmed);
      bloc.add(const ConfirmSaleEvent(
          shopName: 'Shop', address1: '', address2: '', phone: '', footer: ''));
      await confirmed.timeout(_timeout);
      final item = invoiceRepo.savedItems!.single;
      expect(item.price, 150000); // resolved SP
      expect(item.priceCurrency, 'usd');
      expect(item.fxRate, 15000);
      expect(item.priceOriginal, 10);
      await bloc.close();
    });

    test('USD product with no rate → unpriced line blocks the sale', () async {
      final invoiceRepo = _FakeInvoiceRepository();
      final bloc = BillingBloc(
        productRepository: _FakeProductRepository(),
        printerRepository: _FakePrinterRepository(),
        invoiceRepository: invoiceRepo,
        exchangeRateService: _FakeExchangeRateService(), // no rate set
        inventorySettingsService: _FakeInventorySettingsService(),
        printSettingsService: _FakePrintSettingsService(),
        attributeRepository: _FakeAttributeDefinitionRepository(),
        productUnitRepository: _FakeProductUnitRepository(),
      );
      bloc.add(const LoadExchangeRateEvent());

      const usd = Product(
          id: 'd1',
          name: 'Phone',
          barcode: '',
          price: 10,
          quantity: 5,
          priceCurrency: PriceCurrency.usd);
      bloc.add(const AddProductToCartEvent(usd));
      final errored = bloc.stream.firstWhere((s) => s.error != null);
      bloc.add(const ConfirmSaleEvent(
          shopName: 'Shop', address1: '', address2: '', phone: '', footer: ''));
      final s = await errored.timeout(_timeout);

      expect(s.error, BillingError.exchangeRateMissing);
      expect(invoiceRepo.saveCount, 0);
      await bloc.close();
    });

    test('line discount reduces the line total and is snapshotted on save',
        () async {
      final invoiceRepo = _FakeInvoiceRepository();
      final bloc = BillingBloc(
        productRepository: _FakeProductRepository(),
        printerRepository: _FakePrinterRepository(),
        invoiceRepository: invoiceRepo,
        exchangeRateService: _FakeExchangeRateService(),
        inventorySettingsService: _FakeInventorySettingsService(),
        printSettingsService: _FakePrintSettingsService(),
        attributeRepository: _FakeAttributeDefinitionRepository(),
        productUnitRepository: _FakeProductUnitRepository(),
      );
      const p = Product(id: 'p1', name: 'X', barcode: '', price: 10, quantity: 5);
      bloc.add(const AddProductToCartEvent(p));
      bloc.add(const AddProductToCartEvent(p));
      bloc.add(const AddProductToCartEvent(p)); // gross 30
      bloc.add(const SetLineDiscountEvent('p1', 5));
      final s = await bloc.stream
          .firstWhere((s) =>
              s.cartItems.isNotEmpty && s.cartItems.first.discount == 5)
          .timeout(_timeout);
      expect(s.cartItems.single.total, 25); // 30 − 5
      expect(s.totalAmount, 25);

      final confirmed = bloc.stream.firstWhere((s) => s.saleConfirmed);
      bloc.add(const ConfirmSaleEvent(
          shopName: 'S', address1: '', address2: '', phone: '', footer: ''));
      await confirmed.timeout(_timeout);
      expect(invoiceRepo.savedItems!.single.discount, 5);
      expect(invoiceRepo.savedInvoice!.totalAmount, 25);
      await bloc.close();
    });

    test('whole-cart discount reduces the total and clamps at zero', () async {
      final bloc = BillingBloc(
        productRepository: _FakeProductRepository(),
        printerRepository: _FakePrinterRepository(),
        invoiceRepository: _FakeInvoiceRepository(),
        exchangeRateService: _FakeExchangeRateService(),
        inventorySettingsService: _FakeInventorySettingsService(),
        printSettingsService: _FakePrintSettingsService(),
        attributeRepository: _FakeAttributeDefinitionRepository(),
        productUnitRepository: _FakeProductUnitRepository(),
      );
      const p = Product(id: 'p1', name: 'X', barcode: '', price: 10, quantity: 5);
      bloc.add(const AddProductToCartEvent(p)); // gross 10
      bloc.add(const SetCartDiscountEvent(4));
      var s = await bloc.stream
          .firstWhere((s) => s.invoiceDiscount == 4)
          .timeout(_timeout);
      expect(s.totalAmount, 6);

      // Over-discounting can never make the total negative.
      bloc.add(const SetCartDiscountEvent(999));
      s = await bloc.stream
          .firstWhere((s) => s.invoiceDiscount == 999)
          .timeout(_timeout);
      expect(s.totalAmount, 0);
      await bloc.close();
    });
  });

  group('ProductBloc', () {
    test('LoadProducts subscribes to the stream and emits loaded', () async {
      final repo = _FakeProductRepository();
      final bloc = ProductBloc(repository: repo, printerRepository: _FakePrinterRepository());
      final loaded = bloc.stream.firstWhere((s) => s.products.isNotEmpty);
      bloc.add(LoadProducts());
      repo.emit([_product()]);

      final state = await loaded.timeout(_timeout);
      expect(state.status, ProductStatus.loaded);
      expect(state.products.single.id, 'p1');
      await bloc.close();
      await repo.dispose();
    });

    test('add success → typed "added" feedback', () async {
      final repo = _FakeProductRepository();
      final bloc = ProductBloc(repository: repo, printerRepository: _FakePrinterRepository());
      final done = bloc.stream.firstWhere((s) => s.message != null);
      bloc.add(AddProduct(_product()));

      final state = await done.timeout(_timeout);
      expect(state.status, ProductStatus.success);
      expect(state.message, ProductMessage.added);
      await bloc.close(); // stream unused here, so no repo.dispose()
    });

    test('duplicate barcode → typed "barcodeExists" feedback', () async {
      final repo = _FakeProductRepository()
        ..addResult = const Left(DuplicateFailure('dup'));
      final bloc = ProductBloc(repository: repo, printerRepository: _FakePrinterRepository());
      final done = bloc.stream.firstWhere((s) => s.message != null);
      bloc.add(AddProduct(_product()));

      final state = await done.timeout(_timeout);
      expect(state.status, ProductStatus.error);
      expect(state.message, ProductMessage.barcodeExists);
      await bloc.close(); // stream unused here, so no repo.dispose()
    });

    test('print label → dispatches to the printer and reports success/failure',
        () async {
      final repo = _FakeProductRepository();
      final printer = _FakePrinterRepository(printerAvailable: true);
      final bloc = ProductBloc(repository: repo, printerRepository: printer);

      final printed = bloc.stream.firstWhere((s) => s.message != null);
      bloc.add(const PrintProductLabel(
          name: 'Phone', priceText: '10', barcodeData: '123', copies: 2));
      final s1 = await printed.timeout(_timeout);
      expect(s1.status, ProductStatus.success);
      expect(s1.message, ProductMessage.labelPrinted);
      expect(printer.printLabelCount, 1);
      await bloc.close();

      // Printer unavailable → typed failure feedback.
      final offline = ProductBloc(
          repository: repo,
          printerRepository: _FakePrinterRepository(printerAvailable: false));
      final failed = offline.stream.firstWhere((s) => s.message != null);
      offline.add(const PrintProductLabel(
          name: 'Phone', priceText: '10', barcodeData: '123'));
      final s2 = await failed.timeout(_timeout);
      expect(s2.status, ProductStatus.error);
      expect(s2.message, ProductMessage.labelPrintFailed);
      await offline.close();
    });
  });

  group('HistoryBloc', () {
    test('filtered stream drives the list + summary cards', () async {
      final repo = _FakeInvoiceRepository();
      final bloc = HistoryBloc(
          repository: repo, printerRepository: _FakePrinterRepository());
      // The list and summary arrive as two independent stream updates, so wait
      // for the state that has both settled.
      final loaded = bloc.stream.firstWhere(
          (s) => s.invoices.isNotEmpty && s.summary.count > 0);
      bloc.add(LoadHistoryEvent());
      repo.emitList([
        InvoiceListItem(
            id: 'i1',
            createdAt: DateTime.now(),
            total: 25,
            itemCount: 2,
            isCredit: false),
      ]);
      repo.emitSummary(
          const SalesSummary(count: 1, total: 25, cashTotal: 25));

      final state = await loaded.timeout(_timeout);
      expect(state.invoices.length, 1);
      expect(state.summary.count, 1);
      expect(state.summary.total, 25);
      await bloc.close();
      await repo.dispose();
    });

    test('stream error → typed HistoryError.loadFailed (no raw string)',
        () async {
      final repo = _FakeInvoiceRepository();
      final bloc = HistoryBloc(
          repository: repo, printerRepository: _FakePrinterRepository());
      final errored =
          bloc.stream.firstWhere((s) => s.status == HistoryStatus.error);
      bloc.add(LoadHistoryEvent());
      repo.emitListError(Exception('db boom'));

      final state = await errored.timeout(_timeout);
      expect(state.error, HistoryError.loadFailed);
      await bloc.close();
      await repo.dispose();
    });

    test('item-load failure → invoice recorded in failedItems (retryable)',
        () async {
      final repo = _FakeInvoiceRepository()
        ..itemsResult = const Left(CacheFailure('boom'));
      final bloc = HistoryBloc(
          repository: repo, printerRepository: _FakePrinterRepository());
      final failed =
          bloc.stream.firstWhere((s) => s.failedItems.contains('i1'));
      bloc.add(const LoadInvoiceDetailsEvent('i1'));

      final state = await failed.timeout(_timeout);
      expect(state.failedItems, contains('i1'));
      await bloc.close();
      await repo.dispose();
    });
  });
}
