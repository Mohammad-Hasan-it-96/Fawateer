// Surfacing stock the shop has sold past zero (Plan 002 Q6).
//
// A real-SQLite test rather than a fake, because the thing under test IS the
// query: the sign of a SUM over an append-only log, which rows the GROUP BY
// includes, and the two exclusions that keep it honest. Stub the SQL out and
// there is nothing left to assert.
//
// It runs on the host — `NativeDatabase` works under plain `flutter test` —
// following `snapshot_seeder_test`. Nothing here needs *Android's* SQLite
// build, which is what `integration_test/` is for.
import 'dart:io';

import 'package:billing_app/core/database/app_database.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late File dbFile;
  late AppDatabase db;

  setUp(() async {
    dbFile = File('${Directory.systemTemp.path}/'
        'fawateer_oversold_${DateTime.now().microsecondsSinceEpoch}.sqlite');
    if (dbFile.existsSync()) dbFile.deleteSync();
    db = AppDatabase.forTesting(NativeDatabase(dbFile));
    await db.customSelect('SELECT 1').getSingle();
  });

  tearDown(() async {
    await db.close();
    if (dbFile.existsSync()) dbFile.deleteSync();
  });

  Future<void> addProduct(
    String id,
    String name, {
    bool serialized = false,
  }) =>
      db.customInsert(
        'INSERT INTO products (id, name, price, cost, quantity, min_stock_alert, '
        'barcode, sale_type, price_currency, attributes, is_serialized, '
        "created_at, updated_at, deleted_at, origin_device) "
        "VALUES (?, ?, 100.0, 50.0, 0.0, 0.0, '', 'piece', 'sp', '{}', ?, 0, '', '', '')",
        variables: [
          Variable<String>(id),
          Variable<String>(name),
          Variable<int>(serialized ? 1 : 0),
        ],
      );

  Future<void> addMovement(
    String id,
    String productId,
    double delta, {
    String deletedAt = '',
  }) =>
      db.customInsert(
        'INSERT INTO stock_movements (id, product_id, delta, reason, related_id, '
        'note, occurred_at, created_at, updated_at, deleted_at, origin_device) '
        "VALUES (?, ?, ?, 'sale', '', '', 0, 0, '', ?, '')",
        variables: [
          Variable<String>(id),
          Variable<String>(productId),
          Variable<double>(delta),
          Variable<String>(deletedAt),
        ],
      );

  test('a product sold past zero is reported, with its negative on-hand',
      () async {
    await addProduct('p1', 'Rice');
    await addMovement('m1', 'p1', 5); // opening
    await addMovement('m2', 'p1', -4); // this till
    await addMovement('m3', 'p1', -4); // the other till, merged in by union

    final rows = await db.dashboardDao.oversoldProducts();

    // Both sales counted — which is the entire point of the log, and why the
    // shortfall can be reported at all. A last-write-wins scalar would have
    // converged on "1" and shown nothing wrong here.
    expect(rows.single.name, 'Rice');
    expect(rows.single.value, -3);
  });

  test('the cached quantity hides what this reports', () async {
    await addProduct('p1', 'Rice');
    await addMovement('m1', 'p1', 2);
    await addMovement('m2', 'p1', -5);
    await db.stockDao.recomputeQuantity('p1');

    final cached = await db
        .customSelect('SELECT quantity FROM products WHERE id = ?',
            variables: const [Variable<String>('p1')])
        .getSingle();

    // `kRecomputeQuantitySql` floors the cache at 0 so no screen prints a
    // negative count. That floor is exactly why the flag cannot be derived from
    // `products.quantity` and has to read the signed log.
    expect(cached.read<double>('quantity'), 0);
    expect((await db.dashboardDao.oversoldProducts()).single.value, -3);
  });

  test('a product in stock is not reported', () async {
    await addProduct('p1', 'Rice');
    await addMovement('m1', 'p1', 10);
    await addMovement('m2', 'p1', -4);

    expect(await db.dashboardDao.oversoldProducts(), isEmpty);
  });

  test('a product with no movements at all is not reported', () async {
    // The JOIN, not a LEFT JOIN: a product nobody has ever counted has no log,
    // and "no information" must not read as "sold past zero".
    await addProduct('p1', 'Loose parsley');

    expect(await db.dashboardDao.oversoldProducts(), isEmpty);
  });

  test('float noise on a weighed product is not an oversell', () async {
    await addProduct('p1', 'Rice');
    await addMovement('m1', 'p1', 0.3);
    await addMovement('m2', 'p1', -0.1);
    await addMovement('m3', 'p1', -0.2);

    // 0.3 - 0.1 - 0.2 lands a hair below zero in IEEE 754. Reporting that as a
    // shortfall would put a permanent red card on the dashboard of a shop that
    // has sold exactly what it had.
    expect(await db.dashboardDao.oversoldProducts(), isEmpty);
  });

  test('a serialized product is never reported from the movement log',
      () async {
    await addProduct('p1', 'Phone', serialized: true);
    await addMovement('m1', 'p1', -3);

    // Its on-hand authority is `product_units`, and `kRecomputeQuantitySql`
    // ignores stray movements on it. Reporting one here would accuse a shop of
    // overselling handsets on the strength of a row nothing else counts.
    expect(await db.dashboardDao.oversoldProducts(), isEmpty);
  });

  test('a tombstoned movement stops counting', () async {
    await addProduct('p1', 'Rice');
    await addMovement('m1', 'p1', 2);
    await addMovement('m2', 'p1', -5, deletedAt: '00017-1-node');

    // Deleting the invoice tombstones the movements it posted rather than
    // writing a compensating one — so a reversed sale must leave no shortfall
    // behind it.
    expect(await db.dashboardDao.oversoldProducts(), isEmpty);
  });

  test('a deleted product stops being reported', () async {
    await addProduct('p1', 'Rice');
    await addMovement('m1', 'p1', -3);
    await db.customUpdate(
      "UPDATE products SET deleted_at = '00017-1-node' WHERE id = ?",
      variables: const [Variable<String>('p1')],
    );

    expect(await db.dashboardDao.oversoldProducts(), isEmpty);
  });

  test('the worst shortfall comes first and the list is capped', () async {
    for (var i = 0; i < 4; i++) {
      await addProduct('p$i', 'Item $i');
      await addMovement('m$i', 'p$i', -(i + 1).toDouble());
    }

    final rows = await db.dashboardDao.oversoldProducts(limit: 2);

    // Worst first: an owner with a dozen shortfalls should be looking at the
    // two that matter, not scrolling a card.
    expect(rows.map((r) => r.name), ['Item 3', 'Item 2']);
  });
}
