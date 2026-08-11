// ProductBloc's bulk price handler (Plan 015 B2.2) against a fake repository.
//
// What matters here is what reaches the database: the selection is chosen on a
// live, stream-backed list, so the ids in the event and the products the BLoC
// holds are not guaranteed to line up.
import 'dart:async';

import 'package:billing_app/core/error/failure.dart';
import 'package:billing_app/features/product/domain/bulk_price_edit.dart';
import 'package:billing_app/features/product/domain/entities/product.dart';
import 'package:billing_app/features/product/domain/repositories/product_repository.dart';
import 'package:billing_app/features/product/presentation/bloc/product_bloc.dart';
import 'package:billing_app/features/settings/domain/repositories/printer_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

class _FakeProductRepository implements ProductRepository {
  final _controller = StreamController<List<Product>>.broadcast();

  /// Every batch handed to [updatePrices], so a test can assert both what was
  /// written and that nothing was written at all.
  final List<List<Product>> writes = [];
  Either<Failure, void> writeResult = const Right(null);

  void emit(List<Product> products) => _controller.add(products);

  @override
  Stream<List<Product>> watchProducts() => _controller.stream;

  @override
  Future<Either<Failure, void>> updatePrices(List<Product> products) async {
    writes.add(products);
    return writeResult;
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

Product _p(String id, double price) =>
    Product(id: id, name: id, barcode: '', price: price);

void main() {
  late _FakeProductRepository repo;
  late ProductBloc bloc;

  setUp(() {
    repo = _FakeProductRepository();
    bloc = ProductBloc(
        repository: repo, printerRepository: _FakePrinterRepository());
    bloc.add(LoadProducts());
  });

  tearDown(() => bloc.close());

  /// Push a catalogue through the stream and wait for the BLoC to hold it.
  Future<void> seed(List<Product> products) async {
    repo.emit(products);
    await bloc.stream.firstWhere((s) => s.products.length == products.length);
  }

  test('writes only the products the edit moves', () async {
    await seed([_p('a', 1000), _p('b', 3000), _p('c', 2000)]);

    bloc.add(const BulkUpdatePrices(
      productIds: {'a', 'b', 'c'},
      edit: BulkPriceEdit(
          field: BulkPriceField.price, mode: BulkPriceMode.setTo, value: 3000),
    ));
    await bloc.stream
        .firstWhere((s) => s.message == ProductMessage.bulkPricesUpdated);

    // 'b' was already 3000. Re-writing it would be a wasted row — and on the
    // sync branch, a wasted push carrying a fresh HLC stamp.
    expect(repo.writes.single.map((p) => p.id), ['a', 'c']);
    expect(repo.writes.single.every((p) => p.price == 3000), isTrue);
    expect(bloc.state.messageCount, 2);
  });

  test('leaves unselected products alone', () async {
    await seed([_p('a', 1000), _p('b', 1000)]);

    bloc.add(const BulkUpdatePrices(
      productIds: {'a'},
      edit: BulkPriceEdit(
          field: BulkPriceField.price, mode: BulkPriceMode.percent, value: 50),
    ));
    await bloc.stream
        .firstWhere((s) => s.message == ProductMessage.bulkPricesUpdated);

    expect(repo.writes.single.map((p) => p.id), ['a']);
    expect(repo.writes.single.single.price, 1500);
  });

  test('silently skips ids that no longer exist', () async {
    // The selection is held as ids across stream updates, so a product deleted
    // (or sold out of existence) between ticking and applying is normal — it
    // must not fail the whole batch.
    await seed([_p('a', 1000)]);

    bloc.add(const BulkUpdatePrices(
      productIds: {'a', 'gone'},
      edit: BulkPriceEdit(
          field: BulkPriceField.price, mode: BulkPriceMode.setTo, value: 2000),
    ));
    await bloc.stream
        .firstWhere((s) => s.message == ProductMessage.bulkPricesUpdated);

    expect(repo.writes.single.map((p) => p.id), ['a']);
    expect(bloc.state.messageCount, 1);
  });

  test('a no-op edit reports "nothing changed" and writes nothing', () async {
    // A green "done" after nothing happened is how a shop ends up believing a
    // price change was saved when it was not.
    await seed([_p('a', 1000)]);

    bloc.add(const BulkUpdatePrices(
      productIds: {'a'},
      edit: BulkPriceEdit(
          field: BulkPriceField.price, mode: BulkPriceMode.setTo, value: 1000),
    ));
    final state = await bloc.stream.firstWhere((s) => s.message != null);

    expect(state.message, ProductMessage.bulkPricesUnchanged);
    expect(repo.writes, isEmpty);
  });

  test('a failed write reports an error, not a success', () async {
    await seed([_p('a', 1000)]);
    repo.writeResult = const Left(CacheFailure('disk full'));

    bloc.add(const BulkUpdatePrices(
      productIds: {'a'},
      edit: BulkPriceEdit(
          field: BulkPriceField.price, mode: BulkPriceMode.setTo, value: 2000),
    ));
    final state = await bloc.stream.firstWhere((s) => s.message != null);

    expect(state.message, ProductMessage.saveFailed);
    expect(state.status, ProductStatus.error);
  });
}
