// Smoke tests for the refactored core flows. These drive the BLoCs against
// in-memory fake repositories (no Drift / native SQLite / plugins), so they run
// reliably under `flutter test` and guard the architecture refactor:
//   - BLoCs depend on repository interfaces directly (no use-case layer)
//   - sale confirmation persists via a single saveInvoice call (atomic record)
//   - errors are surfaced as typed enums, never English strings
//   - product list & history are driven by repository streams
import 'dart:async';

import 'package:billing_app/core/error/failure.dart';
import 'package:billing_app/features/billing/domain/entities/invoice.dart';
import 'package:billing_app/features/billing/domain/entities/invoice_item.dart';
import 'package:billing_app/features/billing/domain/entities/invoice_list_item.dart';
import 'package:billing_app/features/billing/domain/entities/sales_filter.dart';
import 'package:billing_app/features/billing/domain/entities/sales_summary.dart';
import 'package:billing_app/features/billing/domain/repositories/invoice_repository.dart';
import 'package:billing_app/features/billing/presentation/bloc/billing_bloc.dart';
import 'package:billing_app/features/billing/presentation/bloc/history_bloc.dart';
import 'package:billing_app/features/product/domain/entities/product.dart';
import 'package:billing_app/features/product/domain/repositories/product_repository.dart';
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
}

class _FakeInvoiceRepository implements InvoiceRepository {
  final _controller = StreamController<List<Invoice>>();
  int saveCount = 0;
  Invoice? savedInvoice;
  List<InvoiceItem>? savedItems;
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
      {String? customerId}) async {
    saveCount++;
    savedInvoice = invoice;
    savedItems = items;
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

    test('credit sale → customerId forwarded to saveInvoice', () async {
      final invoiceRepo = _FakeInvoiceRepository();
      final bloc = BillingBloc(
        productRepository: _FakeProductRepository(),
        printerRepository: _FakePrinterRepository(),
        invoiceRepository: invoiceRepo,
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

    test('empty cart confirm → emptyCart error, nothing saved', () async {
      final invoiceRepo = _FakeInvoiceRepository();
      final bloc = BillingBloc(
        productRepository: _FakeProductRepository(),
        printerRepository: _FakePrinterRepository(),
        invoiceRepository: invoiceRepo,
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
  });

  group('ProductBloc', () {
    test('LoadProducts subscribes to the stream and emits loaded', () async {
      final repo = _FakeProductRepository();
      final bloc = ProductBloc(repository: repo);
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
      final bloc = ProductBloc(repository: repo);
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
      final bloc = ProductBloc(repository: repo);
      final done = bloc.stream.firstWhere((s) => s.message != null);
      bloc.add(AddProduct(_product()));

      final state = await done.timeout(_timeout);
      expect(state.status, ProductStatus.error);
      expect(state.message, ProductMessage.barcodeExists);
      await bloc.close(); // stream unused here, so no repo.dispose()
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
