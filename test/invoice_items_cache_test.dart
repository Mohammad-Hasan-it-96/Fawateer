// HistoryBloc's line-item cache (Plan 019 #1).
//
// This cache used to serve one screen — the invoice detail page. It now also
// backs the customer's account, where tapping a credit sale expands to show
// what was sold. Two properties that were merely convenient there are
// load-bearing here, so they are pinned:
//
//   - a *failed* load must not be cached, or the retry tap on a row that
//     failed once can never succeed;
//   - a cached invoice must not be re-fetched, because the account screen can
//     open and close the same row repeatedly while a customer argues about it.
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

const _line = InvoiceItem(
  id: 1,
  invoiceId: 'inv1',
  productId: 'p1',
  productName: 'سكر',
  price: 2500,
  cost: 2000,
  quantity: 2,
);

class _FakeInvoiceRepository implements InvoiceRepository {
  final _list = StreamController<List<InvoiceListItem>>.broadcast();
  final _summary = StreamController<SalesSummary>.broadcast();

  int itemCalls = 0;
  Either<Failure, List<InvoiceItem>> itemsResult = const Right([_line]);

  @override
  Stream<List<InvoiceListItem>> watchFilteredInvoices(SalesFilter filter,
          {int limit = 30, int offset = 0}) =>
      _list.stream;

  @override
  Stream<SalesSummary> watchSummary(SalesFilter filter) => _summary.stream;

  @override
  Future<Either<Failure, List<InvoiceItem>>> getInvoiceItems(String id) async {
    itemCalls++;
    return itemsResult;
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

  test('the sold lines land in the cache under their invoice', () async {
    // What the customer's account reads to answer "what was this 5,000 for?".
    bloc.add(const LoadInvoiceDetailsEvent('inv1'));
    await bloc.stream.firstWhere((s) => s.itemsCache.containsKey('inv1'));

    expect(bloc.state.itemsCache['inv1']!.single.productName, 'سكر');
  });

  test('a cached invoice is not fetched again', () async {
    // The account screen expands and collapses the same row freely; each
    // expand dispatches the event.
    bloc.add(const LoadInvoiceDetailsEvent('inv1'));
    await bloc.stream.firstWhere((s) => s.itemsCache.containsKey('inv1'));

    bloc.add(const LoadInvoiceDetailsEvent('inv1'));
    bloc.add(const LoadInvoiceDetailsEvent('inv1'));
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(repo.itemCalls, 1);
  });

  test('a failed load is recorded but never cached, so a retry can work',
      () async {
    // The row shows a tappable "couldn't load — tap to retry". If the failure
    // were cached as an answer, that tap could never do anything.
    repo.itemsResult = const Left(CacheFailure('locked'));

    bloc.add(const LoadInvoiceDetailsEvent('inv1'));
    await bloc.stream.firstWhere((s) => s.failedItems.contains('inv1'));

    expect(bloc.state.itemsCache.containsKey('inv1'), isFalse);

    repo.itemsResult = const Right([_line]);
    bloc.add(const LoadInvoiceDetailsEvent('inv1'));
    await bloc.stream.firstWhere((s) => s.itemsCache.containsKey('inv1'));

    // And the failure flag clears, so the red line does not linger over lines
    // that are now on screen.
    expect(bloc.state.failedItems.contains('inv1'), isFalse);
  });

  test('an invoice with no lines is a real answer, not a stuck spinner',
      () async {
    repo.itemsResult = const Right([]);

    bloc.add(const LoadInvoiceDetailsEvent('inv1'));
    await bloc.stream.firstWhere((s) => s.itemsCache.containsKey('inv1'));

    expect(bloc.state.itemsCache['inv1'], isEmpty);
  });
}
