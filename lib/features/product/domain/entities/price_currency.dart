/// The currency a product's price (and cost) is entered in.
///
/// [sp] (Syrian Pound) is the app's **base/book currency** — every stored
/// amount (invoice, debt, cashbox, report) is in SP. [usd] is a per-product
/// *pricing label*: a USD-priced product is converted to SP at the moment of
/// sale using the shop's exchange rate, and only the resolved SP figure is
/// posted to the books. See `docs/plans/003-dual-currency.md`.
///
/// Persisted **by name** (`currency.name`) in the DB, never by index — adding a
/// currency or reordering cases must not remap existing rows. Parse back with
/// [fromName], which falls back to [sp] for any unknown/legacy value.
enum PriceCurrency {
  sp,
  usd,
  // Future currencies (e.g. eur, try) slot in here with no DB migration — the
  // column stores the name string.
  ;

  /// Safe reverse lookup for a stored name; unknown/legacy values → [sp].
  static PriceCurrency fromName(String? name) {
    for (final c in PriceCurrency.values) {
      if (c.name == name) return c;
    }
    return PriceCurrency.sp;
  }

  /// True for any non-base currency that must be converted to SP at sale time.
  bool get isForeign => this != PriceCurrency.sp;

  /// Format [amount] in this currency for catalog display. SP uses the shop's
  /// configured [spSymbol]; foreign currencies use their own glyph so a USD
  /// price never renders with the SP symbol.
  String label(double amount, String spSymbol) {
    final n = amount.toStringAsFixed(2);
    switch (this) {
      case PriceCurrency.sp:
        return spSymbol.isEmpty ? n : '$spSymbol$n';
      case PriceCurrency.usd:
        return '\$$n';
    }
  }
}
