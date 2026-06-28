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

  void emit(List<Invoice> invoices) => _controller.add(invoices);
  Future<void> dispose() => _controller.close();

  @override
  Future<Either<Failure, void>> saveInvoice(
      Invoice invoice, List<InvoiceItem> items) async {
    saveCount++;
    savedInvoice = invoice;
    savedItems = items;
    return const Right(null);
  }

  @override
  Stream<List<Invoice>> watchInvoices() => _controller.stream;

  @override
  Future<Either<Failure, List<Invoice>>> getAllInvoices() async =>
      const Right([]);
  @override
  Future<Either<Failure, List<InvoiceItem>>> getInvoiceItems(
          String invoiceId) async =>
      const Right([]);
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
  }) async {
    printReceiptCount++;
    return printerAvailable;
  }

  @override
  Future<Either<Failure, List<PrinterDevice>>> scanDevices() async =>
      const Right([]);
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
        currencySymbol: '',
      ));

      final state = await confirmed.timeout(_timeout);
      expect(state.saleConfirmed, isTrue);
      expect(invoiceRepo.saveCount, 1);
      expect(invoiceRepo.savedItems!.single.productId, 'p1');
      expect(invoiceRepo.savedItems!.single.quantity, 1.0);
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
    test('watchInvoices stream drives today total/count', () async {
      final repo = _FakeInvoiceRepository();
      final bloc = HistoryBloc(repository: repo);
      final loaded = bloc.stream.firstWhere((s) => s.invoices.isNotEmpty);
      bloc.add(LoadHistoryEvent());
      repo.emit([Invoice(id: 'i1', createdAt: DateTime.now(), totalAmount: 25)]);

      final state = await loaded.timeout(_timeout);
      expect(state.todayCount, 1);
      expect(state.todayTotal, 25);
      await bloc.close();
      await repo.dispose();
    });
  });
}
