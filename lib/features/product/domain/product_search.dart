import '../../../core/utils/arabic_search.dart';
import 'entities/product.dart';

/// Pure predicate for the product list's search + custom-field filters
/// (Plan 010), kept out of the widget so it can be unit-tested.
///
/// [query] is free text, matched against the name, barcode, **and any
/// custom-field value** (so typing an IMEI/color/storage value finds the
/// product). [attrFilters] maps an `AttributeDefinition.id` to the set of
/// accepted values — a product must match **every** field present (AND across
/// fields) by holding **one of** its accepted values (OR within a field). An
/// empty query and empty filters match everything.
///
/// Both sides pass through [normalizeForSearch] (Plan 013 #2). Before that this
/// only lower-cased, so a product saved as `مياه معدنيّة` was unreachable by
/// anyone typing `مياه معدنية` — the same words, a different string.
bool productMatchesSearch(
  Product p, {
  required String query,
  required Map<String, Set<String>> attrFilters,
}) {
  if (query.isNotEmpty) {
    final needle = normalizeForSearch(query);
    final hit = normalizeForSearch(p.name).contains(needle) ||
        normalizeForSearch(p.barcode).contains(needle) ||
        p.attributes.values.values
            .any((v) => normalizeForSearch(v).contains(needle));
    if (!hit) return false;
  }
  for (final entry in attrFilters.entries) {
    if (entry.value.isEmpty) continue;
    final v = p.attributes[entry.key];
    if (v == null || !entry.value.contains(v)) return false;
  }
  return true;
}
