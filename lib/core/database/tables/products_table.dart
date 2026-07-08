import 'package:drift/drift.dart';

@DataClassName('ProductRow')
class Products extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get barcode => text().withDefault(const Constant(''))();
  RealColumn get price => real()();
  RealColumn get cost => real().withDefault(const Constant(0))();
  // On-hand inventory (replaces the old int `stock`); a double so items can be
  // sold by weight/fraction (e.g. 1.5 kg).
  RealColumn get quantity => real().withDefault(const Constant(0))();
  // Low-stock threshold; 0 disables the alert.
  RealColumn get minStockAlert => real().withDefault(const Constant(0))();
  // How the product is sold: the ProductSaleType name ('piece' | 'weight' | …).
  // Stored as a name string (not an index) so future enum cases/reordering can't
  // remap existing rows; unknown values decode back to 'piece'.
  TextColumn get saleType => text().withDefault(const Constant('piece'))();

  @override
  Set<Column> get primaryKey => {id};
}

