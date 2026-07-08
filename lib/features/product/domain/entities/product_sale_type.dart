/// How a product is sold — determines how its quantity is entered at sale time.
///
/// [piece] items are sold in whole/fractional units and step by ±1. Measured
/// types (starting with [weight]) are priced per unit of measure (per kg) and
/// let the cashier enter either a measure or a money amount, the app deriving
/// the other.
///
/// Persisted **by name** (`saleType.name`) in the DB, never by index — adding or
/// reordering cases must not remap existing rows. Parse back with [fromName],
/// which falls back to [piece] for any unknown/legacy value.
enum ProductSaleType {
  piece,
  weight,
  // Future measured types slot in here (e.g. volume, length, box) with no DB
  // migration — the column stores the name string.
  ;

  /// Safe reverse lookup for a stored name; unknown/legacy values → [piece].
  static ProductSaleType fromName(String? name) {
    for (final t in ProductSaleType.values) {
      if (t.name == name) return t;
    }
    return ProductSaleType.piece;
  }

  /// True for anything sold by a measure (not by discrete pieces) — gates the
  /// weight/amount entry dialog and the per-unit price/label treatment.
  bool get isMeasured => this != ProductSaleType.piece;
}
