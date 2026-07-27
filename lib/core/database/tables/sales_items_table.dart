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
  // Manual per-line discount in **SP** (the resolved amount, whether the cashier
  // entered a % or a fixed value). Snapshotted at sale time like price/cost;
  // line total = price×quantity − discount. Default 0 = no discount.
  RealColumn get discount => real().withDefault(const Constant(0))();
  // Snapshot of the product's *printed* attributes (showOnReceipt) at sale time,
  // as a JSON object of resolved label→value pairs (Plan 010). Read on reprint
  // so a receipt looks identical forever even if the product/definition is later
  // edited or archived — same discipline as price/cost/fxRate/discount above.
  // '' = none. Additive default keeps old rows valid.
  TextColumn get attributesSnapshot => text().withDefault(const Constant(''))();
  // How the line was sold — the ProductSaleType **name** ('piece'/'weight'),
  // frozen at sale time like price/cost/fxRate above (Plan 011 #10). Without it
  // a reprint lost the unit entirely and the invoice table had to guess kg-vs-
  // piece from whether the quantity was fractional, which mislabels a whole-
  // number weight sale (2.0 kg → "piece").
  //
  // Default is '' (**unknown**), not 'piece': legacy rows predate the snapshot,
  // and claiming 'piece' for them would confidently mislabel every old weighed
  // sale. '' instead means "fall back to the quantity heuristic", so old rows
  // are no worse than before while new ones are exact.
  TextColumn get saleType => text().withDefault(const Constant(''))();
  // The IMEI/serial of the physical unit this line sold, frozen at sale time
  // (Plan 012). '' for a non-serialized product — the overwhelming majority.
  //
  // Not redundant with `product_units.soldInvoiceId`: that is the lookup
  // direction (serial → invoice) and lives on a row the shop can delete, while
  // this is the reprint direction and must outlive it. Same reprint-eternal
  // rule as price/cost/fxRate/discount/saleType above.
  TextColumn get serialSnapshot => text().withDefault(const Constant(''))();
}

