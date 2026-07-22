// Device integration test for the "Sales by field" report group-by (Plan 010
// V1.3). Runs on a real device against the bundled sqlite3_flutter_libs SQLite,
// so it proves JSON1 (`json_extract`/`json_valid`) is available and that
// `DashboardDao.salesByAttribute` groups correctly — the one runtime path the
// host unit tests (which use fakes) can't cover.
//
// Run: flutter test integration_test/sales_by_field_test.dart -d <deviceId>
import 'package:billing_app/core/database/app_database.dart';
import 'package:billing_app/core/database/daos/dashboard_dao.dart';
import 'package:billing_app/core/utils/label_image.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late DashboardDao dao;

  setUp(() async {
    // In-memory DB over the device's real SQLite — never touches the app's
    // on-disk `fawateer` database. onCreate builds the full v13 schema.
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = DashboardDao(db);

    // Three products: two with a `color` attribute, one with none ('' default).
    await db.customStatement(
        "INSERT INTO products (id,name,price,attributes) VALUES "
        "('p1','Phone A',100,'{\"color\":\"black\"}'),"
        "('p2','Phone B',50,'{\"color\":\"white\"}'),"
        "('p3','Loose',30,'')");
    await db.customStatement(
        "INSERT INTO sales_invoices (id,created_at,total_amount) "
        "VALUES ('inv1',1000,280)");
    await db.customStatement(
        "INSERT INTO sales_items (invoice_id,product_id,product_name,price,quantity) VALUES "
        "('inv1','p1','Phone A',100,2)," // black: revenue 200, qty 2
        "('inv1','p2','Phone B',50,1),"  // white: revenue 50
        "('inv1','p3','Loose',30,1)");   // no color: revenue 30
  });

  tearDown(() async => db.close());

  testWidgets('salesByAttribute groups sales by a JSON attribute value',
      (tester) async {
    final rows = await dao.salesByAttribute(
      0,
      9999999999999,
      jsonPath: r'$."color"',
      orderByColumn: 'revenue',
    );

    // Ranked by revenue desc: black (200) > white (50) > no-value (30).
    expect(rows.map((r) => r.productName).toList(), ['black', 'white', '—']);
    expect(rows[0].revenue, 200);
    expect(rows[0].quantity, 2);
    expect(rows[1].revenue, 50);
    // Product with no `color` value buckets under the '—' sentinel (json_valid
    // guards the '' default so json_extract never errors).
    expect(rows[2].productName, '—');
    expect(rows[2].revenue, 30);
  });

  testWidgets('an unknown attribute path yields a single no-value bucket',
      (tester) async {
    final rows = await dao.salesByAttribute(
      0,
      9999999999999,
      jsonPath: r'$."nonexistent"',
      orderByColumn: 'revenue',
    );
    // No product has this field → all sales collapse into one '—' group.
    expect(rows.length, 1);
    expect(rows.single.productName, '—');
    expect(rows.single.revenue, 280); // 200 + 50 + 30
  });

  // Product labels (Plan 010): rendering a barcode/QR to ESC/POS raster needs a
  // real engine (dart:ui toImage), so it's exercised here rather than on the
  // host. Proves the `barcode` package + raster pipeline produce printable bytes.
  testWidgets('LabelImage renders barcode and QR labels to ESC/POS bytes',
      (tester) async {
    final barcodeBytes = await LabelImage.buildEscPosBytes(
        name: 'هاتف', priceText: '10,000 ل.س', barcodeData: '6291234567890');
    expect(barcodeBytes.length, greaterThan(100));
    expect(barcodeBytes.take(2).toList(), [0x1B, 0x40]); // ESC @ init

    final qrBytes = await LabelImage.buildEscPosBytes(
        name: 'هاتف',
        priceText: '10,000 ل.س',
        barcodeData: '6291234567890',
        useQr: true,
        copies: 3);
    expect(qrBytes.length, greaterThan(barcodeBytes.length)); // 3 copies

    // A label with no code still prints (name/price tag).
    final noCode = await LabelImage.buildEscPosBytes(
        name: 'تفاح', priceText: '2,000 ل.س');
    expect(noCode.length, greaterThan(50));
  });
}
