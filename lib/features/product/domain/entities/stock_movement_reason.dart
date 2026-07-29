/// Why a stock movement happened (Plan 002, Phase 0).
///
/// Extensible enum persisted **by name**, never by index — the same rule as
/// `ProductSaleType`, `PriceCurrency`, `CashTransactionType` and `UnitStatus`,
/// so adding or reordering cases can never remap a shop's history.
enum StockMovementReason {
  /// Stock the product was created with, or the balance a pre-log product
  /// already had when the v18 migration ran.
  openingBalance,

  /// Deducted by a sale. `relatedId` carries the invoice id.
  sale,

  /// Put back because the sale was deleted. Not written today — deleting an
  /// invoice tombstones the movements it posted instead, matching how it
  /// reverses its cashbox entry. Reserved so a future "return one line"
  /// flow, which is *not* a deletion, has an honest reason to record.
  saleReturn,

  /// Goods received from a supplier. Reserved: no purchasing module exists yet,
  /// but it can post here with no migration when one ships — the same courtesy
  /// `CashTransactionType.purchasePayment` extends to the cashbox.
  purchase,

  /// The owner corrected the count by hand (the edit-product quantity field, or
  /// a stock take). The default.
  adjustment,

  /// Written off — damaged, expired, stolen. Reserved for a future flow; today
  /// a shop records this as an [adjustment].
  loss;

  /// Decode a persisted name, falling back to [adjustment] for anything
  /// unknown. A movement from a newer build must still count toward on-hand:
  /// dropping it would silently change the shop's stock.
  static StockMovementReason fromName(String? name) =>
      StockMovementReason.values.firstWhere(
        (r) => r.name == name,
        orElse: () => StockMovementReason.adjustment,
      );

  /// Whether this reason normally adds stock. Display only — the sign lives in
  /// `delta`, exactly as it does in the cashbox's signed `amount`.
  bool get isInflow =>
      this == openingBalance || this == purchase || this == saleReturn;
}
