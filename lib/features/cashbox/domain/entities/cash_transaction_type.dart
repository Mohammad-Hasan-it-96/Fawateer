/// The direction a cash movement pushes the balance.
enum CashDirection {
  /// Money into the drawer (+amount).
  inflow,

  /// Money out of the drawer (−amount).
  outflow,

  /// Caller chooses the sign (manual adjustment).
  either,
}

/// The kind of a single cash movement in the cashbox.
///
/// Persisted **by name** (`type.name`) in the DB, never by index — adding or
/// reordering cases must not remap existing rows (same convention as
/// `ProductSaleType`/`LedgerEntryType`). Parse back with [fromName].
///
/// The set is intentionally broad so the module is ready for features that
/// don't exist yet: [purchasePayment] / [supplierPayment] are **reserved** —
/// Fawateer has no purchases/suppliers module (dropped in schema v3), so nothing
/// auto-posts them today; they exist so those flows can post here with no
/// migration when they ship.
enum CashTransactionType {
  // ── Inflows (+) ──────────────────────────────────────────────────────────
  openingBalance,
  cashSale, // auto: a cash sale (customerId == null)
  customerDebtPayment, // auto: a debt repayment (ledger `payment`)
  manualDeposit,

  // ── Outflows (−) ─────────────────────────────────────────────────────────
  expense,
  personalWithdrawal,
  purchasePayment, // reserved (no purchases module yet)
  supplierPayment, // reserved (no suppliers module yet)

  // ── Bidirectional ────────────────────────────────────────────────────────
  manualAdjustment;

  /// Safe reverse lookup for a stored name; unknown/legacy → [manualAdjustment].
  static CashTransactionType fromName(String? name) {
    for (final t in CashTransactionType.values) {
      if (t.name == name) return t;
    }
    return CashTransactionType.manualAdjustment;
  }

  /// The natural direction for this type. [manualAdjustment] is [CashDirection.either]
  /// (the entry UI shows an in/out toggle); everything else is fixed.
  CashDirection get defaultDirection {
    switch (this) {
      case CashTransactionType.openingBalance:
      case CashTransactionType.cashSale:
      case CashTransactionType.customerDebtPayment:
      case CashTransactionType.manualDeposit:
        return CashDirection.inflow;
      case CashTransactionType.expense:
      case CashTransactionType.personalWithdrawal:
      case CashTransactionType.purchasePayment:
      case CashTransactionType.supplierPayment:
        return CashDirection.outflow;
      case CashTransactionType.manualAdjustment:
        return CashDirection.either;
    }
  }

  /// Auto-created by a sale / debt payment — the entry is owned by its source
  /// record (invoice / ledger entry) and is not user-deletable from the cashbox
  /// UI (delete the source instead, which reverses it).
  bool get isSystemGenerated =>
      this == CashTransactionType.cashSale ||
      this == CashTransactionType.customerDebtPayment;

  /// Types a user can pick when adding a manual cash transaction, in menu order.
  static const List<CashTransactionType> manualTypes = [
    CashTransactionType.manualDeposit,
    CashTransactionType.expense,
    CashTransactionType.personalWithdrawal,
    CashTransactionType.openingBalance,
    CashTransactionType.manualAdjustment,
  ];
}
