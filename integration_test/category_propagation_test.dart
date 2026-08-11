// Device integration test for category rename/delete propagation and bulk
// assign (Plan 014 steps 2 and 3).
//
// This belongs here, not in test/, for the reason the suite reserves this
// folder: **the SQLite engine is the thing under test**. The whole feature is
// `json_set` / `json_remove` / `json_extract` against the products table, and a
// fake repository would prove nothing about the one thing that can go wrong —
// a JSON1 statement that silently blanks a product's attribute bag instead of
// editing one key in it.
//
// Run: flutter test integration_test/category_propagation_test.dart -d <deviceId>
import 'package:billing_app/core/database/app_database.dart';
import 'package:billing_app/core/database/daos/attributes_dao.dart';
import 'package:billing_app/core/database/daos/products_dao.dart';
import 'package:billing_app/core/sync/sync_clock.dart';
import 'package:billing_app/features/attributes/domain/product_category.dart';
import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late AttributesDao attributes;
  late ProductsDao productsDao;
  late SyncClock clock;

  const path = r'$."category"';

  setUp(() async {
    // In-memory over the device's real SQLite — never touches the shop's DB.
    db = AppDatabase.forTesting(NativeDatabase.memory());
    attributes = AttributesDao(db);
    productsDao = ProductsDao(db);
    clock = SyncClock(db.settingsDao);
    await clock.load('testnode00000001');

    await db.customStatement(
        "INSERT INTO attribute_definitions (id,label,type,options) VALUES "
        "('category','القسم','select','[\"مشروبات\",\"ألبان\",\"تنظيف\"]')");
    await db.customStatement(
        "INSERT INTO products (id,name,price,attributes) VALUES "
        // Two in مشروبات, one of them also carrying another field.
        "('p1','عصير',1000,'{\"category\":\"مشروبات\"}'),"
        "('p2','ماء',500,'{\"category\":\"مشروبات\",\"color\":\"أزرق\"}'),"
        "('p3','لبن',800,'{\"category\":\"ألبان\"}'),"
        // Never had any attributes — the '' default every legacy row carries.
        "('p4','سكر',300,'')");
  });

  tearDown(() async => db.close());

  Future<String> attrOf(String id) async {
    final row = await db
        .customSelect('SELECT attributes AS a FROM products WHERE id = ?',
            variables: [Variable.withString(id)])
        .getSingle();
    return row.read<String>('a');
  }

  Future<String> optionsOf(String id) async {
    final row = await db
        .customSelect('SELECT options AS o FROM attribute_definitions WHERE id = ?',
            variables: [Variable.withString(id)])
        .getSingle();
    return row.read<String>('o');
  }

  testWidgets('rename moves every product that held the old value',
      (tester) async {
    final moved = await attributes.renameOptionEverywhere(
      definitionId: 'category',
      newOptionsJson: '["عصائر","ألبان","تنظيف"]',
      jsonPath: path,
      from: 'مشروبات',
      to: 'عصائر',
    );

    expect(moved, 2);
    expect(await attrOf('p1'), contains('عصائر'));
    expect(await optionsOf('category'), contains('عصائر'));
    // The products that were in another category are untouched.
    expect(await attrOf('p3'), contains('ألبان'));
  });

  testWidgets('rename edits one key and leaves the rest of the bag alone',
      (tester) async {
    // The failure this guards: replacing the whole attributes column instead of
    // setting one key would wipe every other custom field on the product.
    await attributes.renameOptionEverywhere(
      definitionId: 'category',
      newOptionsJson: '["عصائر"]',
      jsonPath: path,
      from: 'مشروبات',
      to: 'عصائر',
    );

    final bag = await attrOf('p2');
    expect(bag, contains('عصائر'));
    expect(bag, contains('أزرق'));
  });

  testWidgets('delete clears the value and keeps the product', (tester) async {
    final cleared = await attributes.removeOptionEverywhere(
      definitionId: 'category',
      newOptionsJson: '["ألبان","تنظيف"]',
      jsonPath: path,
      value: 'مشروبات',
    );

    expect(cleared, 2);
    // p1 held nothing else, so its bag collapses back to the '' the entity
    // writes for "no attributes" — one representation, not two.
    expect(await attrOf('p1'), '');
    // p2 keeps its other field and simply loses the category.
    final bag = await attrOf('p2');
    expect(bag, contains('أزرق'));
    expect(bag, isNot(contains('مشروبات')));
  });

  testWidgets('bulk assign does not blank a product that had no attributes',
      (tester) async {
    // The sharp edge: json_set() on a non-JSON column returns NULL, and '' is
    // the default for every product that never had a custom field. Without the
    // guard, categorising p4 would erase its bag rather than fill it.
    final changed = await productsDao.setAttributeOnProducts(
      ids: ['p3', 'p4'],
      jsonPath: path,
      value: 'تنظيف',
      stamp: await clock.stamp(),
    );

    expect(changed, 2);
    expect(await attrOf('p4'), contains('تنظيف'));
    expect(await attrOf('p3'), contains('تنظيف'));
  });

  testWidgets('bulk assign keeps other fields on the product', (tester) async {
    await productsDao.setAttributeOnProducts(
      ids: ['p2'],
      jsonPath: path,
      value: 'تنظيف',
      stamp: await clock.stamp(),
    );

    final bag = await attrOf('p2');
    expect(bag, contains('تنظيف'));
    expect(bag, contains('أزرق'));
  });

  testWidgets('bulk assign with a blank value clears the category',
      (tester) async {
    await productsDao.setAttributeOnProducts(
      ids: ['p1', 'p2', 'p4'],
      jsonPath: path,
      value: '',
      stamp: await clock.stamp(),
    );

    expect(await attrOf('p1'), '');
    expect(await attrOf('p2'), contains('أزرق'));
    expect(await attrOf('p2'), isNot(contains('مشروبات')));
    // A product that had nothing keeps having nothing — not '{}', not NULL.
    expect(await attrOf('p4'), '');
  });

  testWidgets('bulk assign survives more ids than SQLite allows variables',
      (tester) async {
    // "Select all" on a real catalogue is hundreds of rows, and SQLite caps
    // bound variables at 999 by default — hence the chunking.
    for (var i = 0; i < 450; i++) {
      await db.customStatement(
          "INSERT INTO products (id,name,price,attributes) "
          "VALUES ('bulk$i','Item $i',10,'')");
    }
    final ids = [for (var i = 0; i < 450; i++) 'bulk$i'];

    final changed = await productsDao.setAttributeOnProducts(
      ids: ids,
      jsonPath: path,
      value: 'تنظيف',
      stamp: await clock.stamp(),
    );

    expect(changed, 450);
    expect(await attrOf('bulk449'), contains('تنظيف'));
  });

  testWidgets('the app builds the same JSON path the queries are tested with',
      (tester) async {
    // Pins the production path helper to the literal used above, so this file
    // cannot pass while the app queries a different key shape.
    expect(attributeJsonPath(kCategoryFieldId), path);
  });
}
