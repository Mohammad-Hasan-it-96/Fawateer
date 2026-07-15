import 'package:drift/drift.dart';

@DataClassName('SalesInvoiceRow')
class SalesInvoices extends Table {
  TextColumn get id => text()();
  /// Stored as milliseconds since epoch.
  IntColumn get createdAt => integer()();
  // Final discounted total the sale settled at (already net of line + cart
  // discounts) — what cashbox/ledger/reports use.
  RealColumn get totalAmount => real()();
  // Whole-cart discount in **SP** applied on top of any per-line discounts.
  // Snapshotted for display ("subtotal − discount = total"); default 0.
  RealColumn get invoiceDiscount => real().withDefault(const Constant(0))();
  // Note: the removed `customerId`/`customerName` columns are left orphaned in
  // existing databases (ignored by Drift, like the old `stock`/`upiId`) — no
  // migration needed since dropping a column requires none.

  @override
  Set<Column> get primaryKey => {id};
}

