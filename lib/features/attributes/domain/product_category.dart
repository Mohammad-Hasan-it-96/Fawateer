import 'entities/attribute_definition.dart';
import 'entities/attribute_type.dart';

/// Product categories (Plan 014), built on the attribute engine rather than on
/// a `categories` table.
///
/// The owner answered "**one** category per product", and a `select` attribute
/// already stores exactly one value per product, filters, searches and groups in
/// reports. A table would have bought multi-category — which was not asked for —
/// at the price of two new tables plus, on the sync branch, two more entries in
/// `kSyncTables` with tombstones and metadata.
///
/// So a category **is** a custom field. What makes it "the category" is this
/// well-known id: the products page looks for a definition with [kCategoryFieldId]
/// and renders its options as the tab's chips.
const String kCategoryFieldId = 'category';

/// The Arabic label the seeded field is created with. User data from the moment
/// it is created — the owner can rename it, and the tab keeps working because
/// the tab matches on the **id**, never the label (the same rule Plan 010 set
/// for attribute values).
const String kCategoryFieldLabel = 'القسم';

/// The category field, if the shop has created it yet. Archived definitions are
/// excluded by the caller passing `state.active`.
AttributeDefinition? categoryFieldOf(Iterable<AttributeDefinition> defs) {
  for (final d in defs) {
    if (d.id == kCategoryFieldId) return d;
  }
  return null;
}

/// A fresh category field carrying [options].
///
/// `sortOrder: 0` puts it first in the product form — a category is the thing an
/// owner picks before any descriptive detail. `showInList` is on so the list
/// subtitle says what section a product belongs to; `showOnReceipt` is
/// deliberately **off** (Plan 014: a customer does not need the shelf layout on
/// their receipt).
AttributeDefinition newCategoryField(List<String> options) =>
    AttributeDefinition(
      id: kCategoryFieldId,
      label: kCategoryFieldLabel,
      type: AttributeType.select,
      options: options,
      showInList: true,
      sortOrder: 0,
    );

/// The SQLite JSON path for one attribute id, e.g. `$."category"`.
///
/// **Quoted**, matching what the report group-by already passes. A generated
/// uuid contains hyphens, and an unquoted JSON path key is not the place to find
/// out which punctuation SQLite tolerates.
///
/// Safe to build by interpolation **only because definition ids are ours** —
/// `kCategoryFieldId` or a uuid, never text the owner typed. Labels are the user
/// data, and labels never reach this function. Callers pass the result as a
/// **bound parameter**, following `DashboardDao.salesByAttribute`.
String attributeJsonPath(String definitionId) => '\$."$definitionId"';

/// Whether [value] is the "no category" bucket.
///
/// `ProductAttributes` never stores an empty value, so an uncategorised product
/// simply has no entry and reads back as `''`. That makes the empty string the
/// natural id for the **أخرى** chip — no sentinel to keep in sync.
bool isUncategorized(String value) => value.isEmpty;
