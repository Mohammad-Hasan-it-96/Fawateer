import 'entities/product.dart';

/// Build a new product from an existing one (Plan 015 B2.1).
///
/// The owner chose one product per juice flavour knowing the cost: ten flavours
/// is ten trips through the full add form, and most of the ten forms are the
/// same answers. This copies everything that is a property of *the kind of
/// thing* — price, cost, currency, sale type, low-stock threshold, and every
/// custom field including the category — and asks only for the two things that
/// are genuinely different.
///
/// **Three fields are deliberately not copied:**
///
/// - `id`, obviously — a caller-supplied [id] keeps this function pure and
///   testable rather than reaching for a uuid of its own.
/// - `barcode` defaults to blank. A barcode identifies one product; copying it
///   would trip the unique index on save every time. (Two products sharing one
///   barcode is Case A of the same plan, a separate change that has to drop
///   that index first — until then, copying it could only ever fail.)
/// - `quantity` starts at **0**. Stock is a count of things on a shelf, and
///   the new flavour is not on the shelf yet. Inheriting the original's count
///   would invent inventory the shop does not have — and on a serialized SKU it
///   would claim units that physically belong to the other product.
Product duplicateProduct(
  Product source, {
  required String id,
  required String name,
  String barcode = '',
}) {
  return Product(
    id: id,
    name: name.trim(),
    barcode: barcode.trim(),
    price: source.price,
    cost: source.cost,
    quantity: 0,
    minStockAlert: source.minStockAlert,
    saleType: source.saleType,
    priceCurrency: source.priceCurrency,
    attributes: source.attributes,
    isSerialized: source.isSerialized,
  );
}
