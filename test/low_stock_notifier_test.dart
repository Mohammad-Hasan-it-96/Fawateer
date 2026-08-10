// LowStockNotifier (Plan 013 #10) against fakes.
//
// The pure decision is covered in low_stock_alert_test. What is tested here is
// the wiring around it, where the expensive mistakes live: announcing a whole
// catalogue's backlog the first time the feature runs, forgetting what was
// already said and repeating it on every restart, and writing to the database
// on every single sale.
import 'dart:async';
import 'dart:convert';

import 'package:billing_app/core/app_locale.dart';
import 'package:billing_app/core/database/daos/settings_dao.dart';
import 'package:billing_app/core/notifications/local_notifier.dart';
import 'package:billing_app/features/product/data/low_stock_notifier.dart';
import 'package:billing_app/features/product/domain/entities/product.dart';
import 'package:billing_app/features/product/domain/repositories/product_repository.dart';
import 'package:flutter_test/flutter_test.dart';

Product _p(String id, {required double qty, double alert = 5}) => Product(
      id: id,
      name: id,
      barcode: '',
      price: 100,
      quantity: qty,
      minStockAlert: alert,
    );

class _FakeProductRepository implements ProductRepository {
  final _controller = StreamController<List<Product>>.broadcast();
  List<Product> current = const [];

  /// Replays the current list before live updates, so both `.first` and
  /// `.listen` see something without a race.
  @override
  Stream<List<Product>> watchProducts() async* {
    yield current;
    yield* _controller.stream;
  }

  void emit(List<Product> products) {
    current = products;
    _controller.add(products);
  }

  @override
  noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not used by this test');
}

class _FakeSettingsDao implements SettingsDao {
  final Map<String, String> values = {};
  int writes = 0;

  @override
  Future<String?> getValue(String key) async => values[key];

  @override
  Future<void> setValue(String key, String value) async {
    writes++;
    values[key] = value;
  }

  @override
  Future<int> deleteKey(String key) async => values.remove(key) == null ? 0 : 1;

  @override
  noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not used by this test');
}

class _RecordingNotifier extends LocalNotifier {
  final List<({String? title, String? body})> shown = [];

  @override
  Future<void> show({required int id, String? title, String? body}) async {
    shown.add((title: title, body: body));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeProductRepository repo;
  late _FakeSettingsDao dao;
  late _RecordingNotifier notifier;
  late LowStockNotifier service;

  /// Let the stream listener's async work finish.
  Future<void> settle() => Future.delayed(const Duration(milliseconds: 20));

  setUp(() {
    repo = _FakeProductRepository();
    dao = _FakeSettingsDao();
    notifier = _RecordingNotifier();
    service = LowStockNotifier(repo, dao, notifier, locale: kAppLocale);
  });

  tearDown(() => service.stop());

  test('alerts are off until the shop turns them on', () async {
    expect(await service.isEnabled(), isFalse);

    repo.current = [_p('sugar', qty: 1)];
    await service.start();
    await settle();

    expect(notifier.shown, isEmpty);
  });

  test('turning them on does not replay the existing backlog', () async {
    // "Tell me when something runs low" is a request about the future. A shop
    // with thirty already-low items must not be handed thirty notifications
    // for agreeing to it — the Reports page is where the current list lives.
    repo.current = [_p('sugar', qty: 1), _p('tea', qty: 2)];

    await service.setEnabled(true);
    await settle();

    expect(notifier.shown, isEmpty);
    expect(jsonDecode(dao.values[LowStockNotifier.announcedKey]!),
        containsAll(['sugar', 'tea']));
  });

  test('a product crossing the line raises one alert', () async {
    repo.current = [_p('sugar', qty: 20)];
    await service.setEnabled(true);
    await settle();

    repo.emit([_p('sugar', qty: 4)]);
    await settle();

    expect(notifier.shown.length, 1);
    expect(notifier.shown.single.title, contains('sugar'));
  });

  test('selling more of an already-low product stays quiet', () async {
    // The one that would make a shop disable the feature: the product stream
    // re-emits on every sale.
    repo.current = [_p('sugar', qty: 20)];
    await service.setEnabled(true);
    await settle();

    repo.emit([_p('sugar', qty: 4)]);
    await settle();
    repo.emit([_p('sugar', qty: 3)]);
    repo.emit([_p('sugar', qty: 2)]);
    await settle();

    expect(notifier.shown.length, 1);
  });

  test('several products crossing at once give one grouped notice', () async {
    // Three separate tray notifications for one delivery shortfall is how a
    // notification gets muted at the OS level.
    repo.current = [_p('a', qty: 20), _p('b', qty: 20), _p('c', qty: 20)];
    await service.setEnabled(true);
    await settle();

    repo.emit([_p('a', qty: 1), _p('b', qty: 1), _p('c', qty: 1)]);
    await settle();

    expect(notifier.shown.length, 1);
    expect(notifier.shown.single.title, contains('3'));
  });

  test('restocking then running down again alerts a second time', () async {
    repo.current = [_p('sugar', qty: 20)];
    await service.setEnabled(true);
    await settle();

    repo.emit([_p('sugar', qty: 4)]);
    await settle();
    repo.emit([_p('sugar', qty: 50)]); // restocked
    await settle();
    repo.emit([_p('sugar', qty: 3)]);
    await settle();

    expect(notifier.shown.length, 2);
  });

  test('what was announced survives a restart', () async {
    repo.current = [_p('sugar', qty: 20)];
    await service.setEnabled(true);
    await settle();
    repo.emit([_p('sugar', qty: 4)]);
    await settle();
    await service.stop();

    // A fresh instance over the same stored settings — i.e. the app reopened.
    final second = LowStockNotifier(repo, dao, notifier, locale: kAppLocale);
    await second.start();
    await settle();
    await second.stop();

    expect(notifier.shown.length, 1);
  });

  test('an unchanged low set is not rewritten on every sale', () async {
    // This listener runs on every product write in the app. Persisting an
    // identical set each time would be a database write per scan.
    repo.current = [_p('sugar', qty: 4)];
    await service.setEnabled(true);
    await settle();
    final writesAfterSeeding = dao.writes;

    repo.emit([_p('sugar', qty: 4)]);
    repo.emit([_p('sugar', qty: 4)]);
    await settle();

    expect(dao.writes, writesAfterSeeding);
  });

  test('a corrupted stored value degrades to silence, not a crash', () async {
    // It is read inside a stream listener, where an exception has nowhere to
    // go and would kill stock updates for the session.
    dao.values[LowStockNotifier.enabledKey] = 'true';
    dao.values[LowStockNotifier.announcedKey] = 'not json at all';
    repo.current = [_p('sugar', qty: 4)];

    await service.start();
    await settle();

    // Treated as "nothing announced yet", so the currently-low product is
    // reported once and then remembered properly.
    expect(notifier.shown.length, 1);
    expect(jsonDecode(dao.values[LowStockNotifier.announcedKey]!), ['sugar']);
  });

  test('turning alerts off stops the watching', () async {
    repo.current = [_p('sugar', qty: 20)];
    await service.setEnabled(true);
    await settle();

    await service.setEnabled(false);
    repo.emit([_p('sugar', qty: 1)]);
    await settle();

    expect(notifier.shown, isEmpty);
  });
}
