// Serialized units — IMEI/serial per physical item (Plan 012, bucket C of
// Plan 010).
//
// The model these tests defend: a Product is a SKU, a ProductUnit is one
// physical object. A shop holding five identical handsets holds ONE product row
// and FIVE unit rows. Plan 010 called refusing to model IMEI as a per-SKU
// attribute its single most important decision, because an attribute bag gives
// you one IMEI slot for five phones — wrong on day one, and warranty lookup
// becomes impossible.
import 'dart:async';

import 'package:billing_app/core/currency/exchange_rate_service.dart';
import 'package:billing_app/core/error/failure.dart';
import 'package:billing_app/core/settings/inventory_settings_service.dart';
import 'package:billing_app/core/settings/print_settings_service.dart';
import 'package:billing_app/features/attributes/domain/entities/attribute_definition.dart';
import 'package:billing_app/features/attributes/domain/repositories/attribute_definition_repository.dart';
import 'package:billing_app/features/billing/domain/entities/invoice.dart';
import 'package:billing_app/features/billing/domain/entities/invoice_item.dart';
import 'package:billing_app/features/billing/domain/repositories/invoice_repository.dart';
import 'package:billing_app/features/billing/presentation/bloc/billing_bloc.dart';
import 'package:billing_app/features/product/domain/entities/product.dart';
import 'package:billing_app/features/product/domain/entities/product_unit.dart';
import 'package:billing_app/features/product/domain/entities/unit_status.dart';
import 'package:billing_app/features/product/domain/repositories/product_repository.dart';
import 'package:billing_app/features/product/domain/repositories/product_unit_repository.dart';
import 'package:billing_app/features/settings/domain/repositories/printer_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

// ── Fakes ───────────────────────────────────────────────────────────────────

class _FakeProductRepository implements ProductRepository {
  final Map<String, Product> byBarcode;
  final Map<String, Product> byId;
  _FakeProductRepository({this.byBarcode = const {}, this.byId = const {}});

  @override
  Future<Either<Failure, Product>> getProductByBarcode(String barcode) async {
    final p = byBarcode[barcode];
    return p == null ? Left(NotFoundFailure('no $barcode')) : Right(p);
  }

  @override
  Future<Either<Failure, Product>> getProductById(String id) async {
    final p = byId[id];
    return p == null ? Left(NotFoundFailure('no id $id')) : Right(p);
  }

  @override
  noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not used by this test');
}

class _FakeProductUnitRepository implements ProductUnitRepository {
  final Map<String, ProductUnit> bySerial;
  _FakeProductUnitRepository({this.bySerial = const {}});

  @override
  Future<Either<Failure, ProductUnit>> findBySerial(String serial) async {
    final u = bySerial[serial];
    return u == null
        ? const Left(NotFoundFailure('serial_not_found'))
        : Right(u);
  }

  @override
  noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not used by this test');
}

class _FakeInvoiceRepository implements InvoiceRepository {
  List<InvoiceItem>? savedItems;
  List<String>? savedUnitIds;

  @override
  Future<Either<Failure, void>> saveInvoice(
      Invoice invoice, List<InvoiceItem> items,
      {String? customerId, List<String> soldUnitIds = const []}) async {
    savedItems = items;
    savedUnitIds = soldUnitIds;
    return const Right(null);
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
  Stream<List<AttributeDefinition>> watchDefinitions() => Stream.value(const []);
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
  Future<bool> isPrintButtonEnabled() async => false;
  @override
  noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not used by this test');
}

// ── Fixtures ────────────────────────────────────────────────────────────────

const _phone = Product(
  id: 'sku-iphone',
  name: 'iPhone 15 128GB',
  barcode: 'BOX-123',
  price: 5000000,
  quantity: 2,
  isSerialized: true,
);

ProductUnit _unit(String id, String serial,
        {UnitStatus status = UnitStatus.inStock}) =>
    ProductUnit(
      id: id,
      productId: _phone.id,
      serial: serial,
      status: status,
      createdAt: DateTime(2026, 7, 1),
    );

BillingBloc _bloc({
  Map<String, ProductUnit> units = const {},
  _FakeInvoiceRepository? invoices,
}) =>
    BillingBloc(
      productRepository: _FakeProductRepository(
        byBarcode: {_phone.barcode: _phone},
        byId: {_phone.id: _phone},
      ),
      printerRepository: _FakePrinterRepository(),
      invoiceRepository: invoices ?? _FakeInvoiceRepository(),
      exchangeRateService: _FakeExchangeRateService(),
      inventorySettingsService: _FakeInventorySettingsService(),
      printSettingsService: _FakePrintSettingsService(),
      attributeRepository: _FakeAttributeDefinitionRepository(),
      productUnitRepository: _FakeProductUnitRepository(bySerial: units),
    );

/// Wait until [test] holds, or fail — the scan path hops through an internal
/// AddProductToCartEvent, so the result lands a microtask or two later.
Future<BillingState> _settle(
    BillingBloc bloc, bool Function(BillingState) test) async {
  if (test(bloc.state)) return bloc.state;
  return bloc.stream.firstWhere(test).timeout(const Duration(seconds: 2));
}

void main() {
  group('UnitStatus', () {
    test('round-trips by name, never by index', () {
      for (final s in UnitStatus.values) {
        expect(UnitStatus.fromName(s.name), s);
      }
    });

    test('unknown and legacy values fall back to inStock', () {
      // The whole point of storing the name: a future case added above `sold`
      // must not silently turn every sold handset back into stock.
      expect(UnitStatus.fromName('reserved'), UnitStatus.inStock);
      expect(UnitStatus.fromName(''), UnitStatus.inStock);
      expect(UnitStatus.fromName(null), UnitStatus.inStock);
    });

    test('only inStock counts as available', () {
      expect(UnitStatus.inStock.isAvailable, isTrue);
      expect(UnitStatus.sold.isAvailable, isFalse);
      // A returned handset is deliberately NOT back on the shelf — it needs an
      // explicit action first.
      expect(UnitStatus.returned.isAvailable, isFalse);
      expect(UnitStatus.defective.isAvailable, isFalse);
    });
  });

  group('warranty', () {
    final unit = _unit('u1', 'IMEI-1')
        .copyWith(warrantyUntil: DateTime(2026, 12, 31));

    test('is live before the expiry date', () {
      expect(unit.isUnderWarrantyAt(DateTime(2026, 7, 26)), isTrue);
    });

    test('is still live ON the expiry date — the boundary customers argue about',
        () {
      expect(unit.isUnderWarrantyAt(DateTime(2026, 12, 31)), isTrue);
    });

    test('has lapsed the day after', () {
      expect(unit.isUnderWarrantyAt(DateTime(2027, 1, 1)), isFalse);
    });

    test('a unit with no recorded warranty is never under warranty', () {
      expect(_unit('u2', 'IMEI-2').isUnderWarrantyAt(DateTime(2026, 1, 1)),
          isFalse);
    });
  });

  group('second scan path (barcode → serial)', () {
    test('scanning an IMEI adds that exact unit to the cart', () async {
      final u = _unit('u1', 'IMEI-1');
      final bloc = _bloc(units: {'IMEI-1': u});

      bloc.add(const ScanBarcodeEvent('IMEI-1'));
      final state = await _settle(bloc, (s) => s.cartItems.isNotEmpty);

      expect(state.cartItems.single.unit?.id, 'u1');
      expect(state.cartItems.single.product.id, _phone.id);
      expect(state.cartItems.single.quantity, 1.0,
          reason: 'one scanned handset is one item');
      expect(state.error, isNull);
      await bloc.close();
    });

    test('a barcode still wins over the serial lookup', () async {
      // Ordering matters (Plan 012 D6): the box barcode is the common case, so
      // it must not be shadowed by a serial that happens to collide.
      final bloc = _bloc(units: {'BOX-123': _unit('u1', 'BOX-123')});

      bloc.add(const ScanBarcodeEvent('BOX-123'));
      final state = await _settle(bloc, (s) => s.cartItems.isNotEmpty);

      expect(state.cartItems.single.unit, isNull,
          reason: 'the barcode matched a SKU, so no unit should be bound');
      await bloc.close();
    });

    test('an already-sold handset reports unitNotAvailable, not productNotFound',
        () async {
      // This distinction is the point: the serial IS on file. Saying "product
      // not found" would send the cashier hunting a shelf for a phone that was
      // sold last week.
      final bloc = _bloc(
          units: {'IMEI-9': _unit('u9', 'IMEI-9', status: UnitStatus.sold)});

      bloc.add(const ScanBarcodeEvent('IMEI-9'));
      final state = await _settle(bloc, (s) => s.error != null);

      expect(state.error, BillingError.unitNotAvailable);
      expect(state.errorBarcode, 'IMEI-9');
      expect(state.cartItems, isEmpty, reason: 'a sold handset cannot re-sell');
      await bloc.close();
    });

    test('an unknown code still falls through to productNotFound', () async {
      final bloc = _bloc();

      bloc.add(const ScanBarcodeEvent('NOPE'));
      final state = await _settle(bloc, (s) => s.error != null);

      expect(state.error, BillingError.productNotFound);
      await bloc.close();
    });
  });

  group('cart semantics for serialized lines', () {
    test('two handsets of one SKU are two lines, not quantity 2', () async {
      // Plan 012 D5. They must stay separate because each line snapshots its
      // own serial — merging them would lose one IMEI entirely.
      final bloc = _bloc(units: {
        'IMEI-1': _unit('u1', 'IMEI-1'),
        'IMEI-2': _unit('u2', 'IMEI-2'),
      });

      bloc.add(const ScanBarcodeEvent('IMEI-1'));
      await _settle(bloc, (s) => s.cartItems.length == 1);
      bloc.add(const ScanBarcodeEvent('IMEI-2'));
      final state = await _settle(bloc, (s) => s.cartItems.length == 2);

      expect(state.cartItems.map((c) => c.unit?.serial).toSet(),
          {'IMEI-1', 'IMEI-2'});
      expect(state.cartItems.every((c) => c.quantity == 1.0), isTrue);
      await bloc.close();
    });

    test('re-scanning the SAME handset does not claim two were sold', () async {
      // Without the unit-aware match this would increment to quantity 2 — the
      // shop would bill a customer for a phone that does not exist.
      final bloc = _bloc(units: {'IMEI-1': _unit('u1', 'IMEI-1')});

      bloc.add(const ScanBarcodeEvent('IMEI-1'));
      await _settle(bloc, (s) => s.cartItems.isNotEmpty);
      bloc.add(const ScanBarcodeEvent('IMEI-1'));
      // Give the second scan a chance to (wrongly) add a line.
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.cartItems.length, 1);
      expect(bloc.state.cartItems.single.quantity, 1.0);
      await bloc.close();
    });
  });

  group('sale', () {
    test('snapshots the serial on the line and reports the consumed unit',
        () async {
      final invoices = _FakeInvoiceRepository();
      final bloc =
          _bloc(units: {'IMEI-1': _unit('u1', 'IMEI-1')}, invoices: invoices);

      bloc.add(const ScanBarcodeEvent('IMEI-1'));
      await _settle(bloc, (s) => s.cartItems.isNotEmpty);
      bloc.add(const ConfirmSaleEvent(
          shopName: 'Shop', address1: '', address2: '', phone: '', footer: ''));
      await _settle(bloc, (s) => !s.isSaving && s.saleConfirmed);

      // The snapshot is what makes a reprint honest years later, even if the
      // unit row is deleted — same rule as price/cost/fxRate/saleType.
      expect(invoices.savedItems!.single.serialSnapshot, 'IMEI-1');
      // And the unit id is what lets the sale mark the handset sold inside its
      // own transaction.
      expect(invoices.savedUnitIds, ['u1']);
      await bloc.close();
    });

    test('a normal non-serialized sale carries no serial and no units',
        () async {
      final invoices = _FakeInvoiceRepository();
      final bloc = _bloc(invoices: invoices);

      bloc.add(const ScanBarcodeEvent('BOX-123'));
      await _settle(bloc, (s) => s.cartItems.isNotEmpty);
      bloc.add(const ConfirmSaleEvent(
          shopName: 'Shop', address1: '', address2: '', phone: '', footer: ''));
      await _settle(bloc, (s) => !s.isSaving && s.saleConfirmed);

      expect(invoices.savedItems!.single.serialSnapshot, '');
      expect(invoices.savedUnitIds, isEmpty,
          reason: 'nothing to mark sold for an ordinary SKU');
      await bloc.close();
    });
  });
}
