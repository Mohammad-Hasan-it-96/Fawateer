/// The kind of a custom product attribute — drives which input widget the
/// dynamic product form renders and how the value is validated/displayed.
///
/// Plan 010 (bucket A: descriptive attributes only). Persisted **by name**
/// (`type.name`) in `attribute_definitions.type`, never by index — adding or
/// reordering cases must not remap existing definitions. Parse back with
/// [fromName], which falls back to [text] for any unknown/legacy value (same
/// discipline as [ProductSaleType]/[PriceCurrency]/[CashTransactionType]).
///
/// Values themselves are always stored as display **strings** on the product
/// (see `ProductAttributes`) — the type only governs input & rendering, keeping
/// V1 lean for simple shops. New cases (e.g. `multiSelect`, `color`) slot in
/// here with no migration.
enum AttributeType {
  /// Free text (IMEI, serial-as-label, notes). Default fallback.
  text,

  /// Numeric entry (storage GB, RAM, voltage). Uses the shared numeric input
  /// formatters; stored as its typed string.
  number,

  /// One choice from a fixed [AttributeDefinition.options] list (color, size).
  select,

  /// Yes/No (e.g. "Original", "Warranty"). Stored as `'true'`/`'false'`.
  boolean,

  /// A calendar date (e.g. warranty-until, best-before). Stored ISO-8601
  /// (`yyyy-MM-dd`).
  date,
  // Future types (multiSelect, color, …) append here — no DB migration, since
  // the column stores the name string.
  ;

  /// Safe reverse lookup for a stored name; unknown/legacy values → [text].
  static AttributeType fromName(String? name) {
    for (final t in AttributeType.values) {
      if (t.name == name) return t;
    }
    return AttributeType.text;
  }

  /// True for types whose value is picked from [AttributeDefinition.options].
  bool get isOptioned => this == AttributeType.select;
}
