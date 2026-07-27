/// Where one physical [ProductUnit] currently is (Plan 012).
///
/// Persisted **by name** (`status.name`) in `product_units.status`, never by
/// index — the same rule as `ProductSaleType`/`PriceCurrency`/`CashTransactionType`,
/// so adding or reordering cases can never remap existing rows. Parse back with
/// [fromName], which falls back to [inStock] for any unknown/legacy value.
///
/// V1 only drives [inStock] and [sold]. [returned] and [defective] exist so a
/// returns/RMA flow is additive later — they cost nothing to reserve now and
/// would cost a migration to add if the column stored indices.
enum UnitStatus {
  /// On the shelf and sellable.
  inStock,

  /// Sold — `soldInvoiceId` and `soldAt` are set.
  sold,

  /// Came back from a customer. Not sellable again without an explicit action,
  /// so it is deliberately *not* [inStock].
  returned,

  /// Faulty; held out of stock.
  defective,
  ;

  /// Safe reverse lookup for a stored name; unknown/legacy values → [inStock].
  static UnitStatus fromName(String? name) {
    for (final s in UnitStatus.values) {
      if (s.name == name) return s;
    }
    return UnitStatus.inStock;
  }

  /// True when this unit counts toward on-hand stock and may be sold.
  ///
  /// This is the single predicate the `quantity` cache is maintained against
  /// (see Plan 012 D1) — if a future status should count as sellable, change it
  /// here and nowhere else.
  bool get isAvailable => this == UnitStatus.inStock;
}
