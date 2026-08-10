// HistoryBloc's payment-correction handler (Plan 016 C-a) against a fake
// repository.
//
// The transaction itself is SQL and is covered on the device
// (integration_test/invoice_payment_change_test.dart). What is worth pinning
// here is what the *page* is told: it rewrites its header from `done`, so a
// failed write must never report it — and unlike a delete, the cached line
// items must survive, because the sale did not change.
import 'dart:async';

import 'package:billing_app/core/error/failure.dart';
import 'package:billing_app/features/billing/domain/entities/invoice_item.dart';
import 'package:billing_app/features/billing/domain/entities/invoice_list_item.dart';
import 'package:billing_app/features/billing/domain/entities/sales_filter.dart';
import 'package:billing_app/features/billing/domain/entities/sales_summary.dart';
import 'package:billing_app/features/billing/domain/repositories/invoice_repository.dart';
import 'package:billing_app/features/billing/presentation/bloc/history_bloc.dart';
import 'package:billing_app/features/settings/domain/repositories/printer_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

class _FakeInvoiceRepository implements InvoiceRepository {
  final _list = StreamController<List<InvoiceListItem>>.broadcast();
  final _summary = StreamController<SalesSummary>.broadcast();

  /// Every correction asked for, as (invoiceId, customerId).
  final List<(String, String?)> changes = [];
  Either<Failure, void> changeResult = const Right(null);

  @override
  Stream<List<InvoiceListItem>> watchFilteredInvoices(SalesFilter filter,
          {int limit = 30, int offset = 0}) =>
      _list.stream;

  @override
  Stream<SalesSummary> watchSummary(SalesFilter filter) => _summary.stream;

  @override
  Future<Either<Failure, List<InvoiceItem>>> getInvoiceItems(String id) async =>
      const Right([]);

  @override
  Future<Either<Failure, void>> changeInvoicePayment(String invoiceId,
      {required String? customerId}) async {
    changes.add((invoiceId, customerId));
    return changeResult;
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

void main() {
  late _FakeInvoiceRepository repo;
  late HistoryBloc bloc;

  setUp(() {
    repo = _FakeInvoiceRepository();
    bloc = HistoryBloc(
        repository: repo, printerRepository: _FakePrinterRepository());
    bloc.add(LoadHistoryEvent());
  });

  tearDown(() => bloc.close());

  test('choosing a customer books the sale as credit', () async {
    bloc.add(const ChangeInvoicePaymentEvent(
        invoiceId: 'inv1', customerId: 'c1'));
    await bloc.stream
        .firstWhere((s) => s.paymentChangeStatus == PaymentChangeStatus.done);

    expect(repo.changes, [('inv1', 'c1')]);
  });

  test('a null customer books it back as cash', () async {
    // The null has to reach the repository as a *value*, not be dropped as an
    // absent argument — it is the only thing that says "cash".
    bloc.add(const ChangeInvoicePaymentEvent(
        invoiceId: 'inv1', customerId: null));
    await bloc.stream
        .firstWhere((s) => s.paymentChangeStatus == PaymentChangeStatus.done);

    expect(repo.changes, [('inv1', null)]);
  });

  test('a failed correction never reports done', () async {
    // `done` is what rewrites the detail page's header. Reporting it after a
    // failed write would show a debt on a customer who was never charged.
    repo.changeResult = const Left(CacheFailure('locked'));

    bloc.add(const ChangeInvoicePaymentEvent(
        invoiceId: 'inv1', customerId: 'c1'));
    final failed = await bloc.stream
        .firstWhere((s) => s.paymentChangeStatus == PaymentChangeStatus.failed);

    expect(failed.paymentChangeStatus, PaymentChangeStatus.failed);
  });

  test('a missing customer surfaces as a failure, not a silent success',
      () async {
    repo.changeResult = const Left(NotFoundFailure('customer not found'));

    bloc.add(const ChangeInvoicePaymentEvent(
        invoiceId: 'inv1', customerId: 'ghost'));
    final failed = await bloc.stream
        .firstWhere((s) => s.paymentChangeStatus == PaymentChangeStatus.failed);

    expect(failed.paymentChangeStatus, PaymentChangeStatus.failed);
  });

  test('the outcome returns to idle so it cannot re-fire', () async {
    bloc.add(const ChangeInvoicePaymentEvent(
        invoiceId: 'inv1', customerId: 'c1'));
    await bloc.stream.firstWhere((s) =>
        s.paymentChangeStatus == PaymentChangeStatus.idle &&
        repo.changes.isNotEmpty);

    expect(bloc.state.paymentChangeStatus, PaymentChangeStatus.idle);
  });

  test('the cached line items survive, unlike a delete', () async {
    // The sale did not change — only how it was paid. Evicting the cache here
    // would make the detail page flash a spinner over an invoice that is still
    // perfectly intact.
    bloc.add(const LoadInvoiceDetailsEvent('inv1'));
    await bloc.stream.firstWhere((s) => s.itemsCache.containsKey('inv1'));

    bloc.add(const ChangeInvoicePaymentEvent(
        invoiceId: 'inv1', customerId: 'c1'));
    await bloc.stream
        .firstWhere((s) => s.paymentChangeStatus == PaymentChangeStatus.done);

    expect(bloc.state.itemsCache.containsKey('inv1'), isTrue);
  });

  group('InvoiceListItem.withPayment', () {
    final credit = InvoiceListItem(
      id: 'inv1',
      createdAt: DateTime(2026, 1, 1),
      total: 2000,
      itemCount: 1,
      isCredit: true,
      customerName: 'أحمد',
      customerId: 'c1',
    );

    test('switching to cash drops the customer entirely', () {
      // A leftover name would leave the header reading "Cash — أحمد", which is
      // not a thing this app can record.
      final cash = credit.withPayment(isCredit: false);

      expect(cash.isCredit, isFalse);
      expect(cash.customerName, isNull);
      expect(cash.customerId, isNull);
    });

    test('the sale itself is carried through untouched', () {
      final moved = credit.withPayment(
          isCredit: true, customerName: 'سميرة', customerId: 'c2');

      expect(moved.id, 'inv1');
      expect(moved.total, 2000);
      expect(moved.itemCount, 1);
      expect(moved.createdAt, DateTime(2026, 1, 1));
      expect(moved.customerName, 'سميرة');
    });
  });
}
