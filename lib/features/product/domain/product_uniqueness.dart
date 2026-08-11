import 'entities/product.dart';

/// The two rules a product has to satisfy before it can be saved.
///
/// Both were written out longhand in the add form, the edit form, and now the
/// duplicate dialog. Three copies of a rule is how the third one ends up
/// slightly different from the other two — so they live here, once.

/// Whether another product already carries [name].
///
/// Case-insensitive and trimmed, because the point of the rule is that a
/// **cashier cannot tell two rows apart**: "Cola" and "cola " are one product
/// as far as anyone at the counter is concerned. Pass [excludingId] when
/// editing, so renaming a product does not collide with itself.
bool productNameTaken(
  Iterable<Product> products,
  String name, {
  String? excludingId,
}) {
  final needle = name.trim().toLowerCase();
  if (needle.isEmpty) return false;
  return products.any((p) =>
      p.id != excludingId && p.name.trim().toLowerCase() == needle);
}

/// Whether another product already carries [barcode].
///
/// **A blank barcode is never taken.** Loose produce, bakery items and
/// anything sold by weight legitimately have none, and a shop can have dozens
/// of them — which is also why the database index is partial (`WHERE barcode
/// != ''`) rather than a plain unique constraint.
bool productBarcodeTaken(
  Iterable<Product> products,
  String barcode, {
  String? excludingId,
}) {
  final needle = barcode.trim();
  if (needle.isEmpty) return false;
  return products.any((p) => p.id != excludingId && p.barcode == needle);
}
