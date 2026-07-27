import 'package:drift/drift.dart';

import 'sync_meta.dart';

/// One **physical object**, as opposed to [Products] which is a SKU (Plan 012,
/// bucket C of Plan 010).
///
/// A phone shop holding five "iPhone 15 128GB Black" has **one product row and
/// five unit rows**. This is precisely why Plan 010 refused to model IMEI as a
/// JSON attribute: an attribute bag gives you one IMEI slot for five phones, so
/// warranty lookup — "which invoice sold *this* handset?" — is impossible.
///
/// Purely additive table (schema v14→v15); no existing table is touched.
@DataClassName('ProductUnitRow')
class ProductUnits extends Table with SyncMeta {
  TextColumn get id => text()();

  /// The SKU this unit is one instance of.
  TextColumn get productId => text()();

  /// The IMEI / serial number. Globally unique among non-empty values, enforced
  /// by a partial-unique index — an IMEI identifies one handset on earth, so a
  /// shop must not be able to enter it twice and sell one phone twice.
  TextColumn get serial => text()();

  /// [UnitStatus] name ('inStock' | 'sold' | 'returned' | 'defective'). Stored
  /// by name, never index — the same rule as ProductSaleType/PriceCurrency, so
  /// reordering enum cases can't remap existing rows. Unknown values decode
  /// back to 'inStock'.
  TextColumn get status => text().withDefault(const Constant('inStock'))();

  /// The invoice that sold this unit; '' while unsold. This is the *lookup*
  /// direction (serial → invoice). It is not redundant with the
  /// `sales_items.serialSnapshot` written at sale time: the snapshot survives
  /// this row being deleted, and this link survives line edits.
  TextColumn get soldInvoiceId => text().withDefault(const Constant(''))();

  /// Sale time, ms since epoch; 0 while unsold.
  IntColumn get soldAt => integer().withDefault(const Constant(0))();

  /// Warranty expiry, ms since epoch; 0 = no warranty recorded. Answers the
  /// question a phone shop is actually asked across the counter.
  IntColumn get warrantyUntil => integer().withDefault(const Constant(0))();

  TextColumn get note => text().withDefault(const Constant(''))();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
