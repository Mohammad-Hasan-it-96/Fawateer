import 'package:drift/drift.dart';

/// Single-row table: always store/read with id = 'default'.
@DataClassName('ShopRow')
class ShopSettings extends Table {
  TextColumn get id => text().withDefault(const Constant('default'))();
  TextColumn get name => text().withDefault(const Constant(''))();
  TextColumn get addressLine1 => text().withDefault(const Constant(''))();
  TextColumn get addressLine2 => text().withDefault(const Constant(''))();
  TextColumn get phoneNumber => text().withDefault(const Constant(''))();
  TextColumn get footerText => text().withDefault(const Constant(''))();
  // Base/book currency symbol. Defaults to the Syrian pound (this is a
  // Syria-first app); the owner can change it in Shop Details.
  TextColumn get currencySymbol => text().withDefault(const Constant('ل.س'))();

  @override
  Set<Column> get primaryKey => {id};
}

