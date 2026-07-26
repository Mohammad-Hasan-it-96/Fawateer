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
  // Currency the `price`/`cost` are entered in: the PriceCurrency name
  // ('sp' | 'usd' | …). SP is the base/book currency; a 'usd' product is
  // converted to SP at sale time. Stored by name (not index) — unknown/legacy
  // values decode back to 'sp'. Additive: every existing product decodes as SP.
  TextColumn get priceCurrency => text().withDefault(const Constant('sp'))();
  // Owner-defined custom fields (Plan 010, bucket A) as a JSON object keyed by
  // AttributeDefinition id: {"<defId>":"<value>"}. '' = no attributes. This is
  // the source of truth; the hot path (name/price/qty/barcode) never reads it.
  // Additive: every existing product decodes as empty.
  TextColumn get attributes => text().withDefault(const Constant(''))();
  // Opt-in per-unit identity (Plan 012, bucket C): when true this SKU's stock is
  // tracked as individual `product_units` rows carrying an IMEI/serial each.
  // Off for every existing product, and off by default — a shop that never turns
  // it on sees exactly today's behavior.
  BoolColumn get isSerialized => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

