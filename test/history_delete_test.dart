// HistoryBloc's delete handler (Plan 016 A) against a fake repository.
//
// The reversal itself is SQL and is covered on the device
// (integration_test/invoice_delete_test.dart). What is worth pinning here is
// what the *page* is told afterwards: the detail page closes itself on `done`,
// so a delete that failed must never report `done`, and the cached line items
// of a sale that no longer exists must not survive it.
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

  final List<String> deleted = [];
  Either<Failure, void> deleteResult = const Right(null);

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
  Future<Either<Failure, void>> deleteInvoice(String id) async {
    deleted.add(id);
    return deleteResult;
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

  test('a successful delete reports done, so the detail page can close',
      () async {
    bloc.add(const DeleteInvoiceEvent('inv1'));
    final done = await bloc.stream
        .firstWhere((s) => s.deleteStatus == DeleteStatus.done);

    expect(repo.deleted, ['inv1']);
    expect(done.deleteStatus, DeleteStatus.done);
  });

  test('the outcome returns to idle so it cannot re-fire', () async {
    bloc.add(const DeleteInvoiceEvent('inv1'));
    await bloc.stream.firstWhere((s) => s.deleteStatus == DeleteStatus.idle &&
        repo.deleted.isNotEmpty);

    expect(bloc.state.deleteStatus, DeleteStatus.idle);
  });

  test('a failed delete never reports done', () async {
    // `done` is what closes the detail page and shows a green confirmation.
    // Reporting it after a failed write would tell the shop a sale was undone
    // while it is still on their books.
    repo.deleteResult = const Left(CacheFailure('locked'));

    bloc.add(const DeleteInvoiceEvent('inv1'));
    final failed = await bloc.stream
        .firstWhere((s) => s.deleteStatus == DeleteStatus.failed);

    expect(failed.deleteStatus, DeleteStatus.failed);
  });

  test('the deleted invoice drops out of the item cache', () async {
    // A stale cache would let a detail page keep rendering a sale that no
    // longer exists.
    bloc.add(const LoadInvoiceDetailsEvent('inv1'));
    await bloc.stream.firstWhere((s) => s.itemsCache.containsKey('inv1'));

    bloc.add(const DeleteInvoiceEvent('inv1'));
    await bloc.stream.firstWhere((s) => s.deleteStatus == DeleteStatus.done);

    expect(bloc.state.itemsCache.containsKey('inv1'), isFalse);
  });

  test('deleting the same invoice twice is harmless', () async {
    // Not a guarantee that it runs once — the in-flight guard depends on
    // timing, and the confirm dialog closes before dispatching anyway. What
    // matters is that a repeat is safe: the second pass finds nothing left to
    // reverse (proven against real SQLite in the integration test) and still
    // reports success rather than an error the shop cannot act on.
    bloc.add(const DeleteInvoiceEvent('inv1'));
    await bloc.stream.firstWhere((s) => s.deleteStatus == DeleteStatus.done);
    bloc.add(const DeleteInvoiceEvent('inv1'));
    final second =
        await bloc.stream.firstWhere((s) => s.deleteStatus != DeleteStatus.idle);

    expect(second.deleteStatus, isNot(DeleteStatus.failed));
  });
}
