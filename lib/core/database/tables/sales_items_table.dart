import 'package:drift/drift.dart';

@DataClassName('SalesItemRow')
class SalesItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get invoiceId => text()();
  TextColumn get productId => text()();
  TextColumn get productName => text()();
  // Resolved SP unit price (settlement value the books use). A USD-priced
  // product is converted to SP at sale time before this snapshot is taken.
  RealColumn get price => real()();
  RealColumn get cost => real().withDefault(const Constant(0))();
  // Double (matches products.quantity) so items can be sold by weight/fraction.
  RealColumn get quantity => real()();
  // Dual-currency snapshot (for display/audit only — never recomputed). Lets a
  // reprinted receipt show "$10 × 15000 = 150,000 SP". priceCurrency is the
  // PriceCurrency name the line was sold in ('sp' default); fxRate is the
  // SP-per-USD rate used (0 for SP-native lines); priceOriginal is the unit
  // price in its original currency. Additive defaults keep old rows valid.
  TextColumn get priceCurrency => text().withDefault(const Constant('sp'))();
  RealColumn get fxRate => real().withDefault(const Constant(0))();
  RealColumn get priceOriginal => real().withDefault(const Constant(0))();
}

