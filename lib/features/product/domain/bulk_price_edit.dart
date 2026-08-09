import 'entities/price_currency.dart';
import 'entities/product.dart';

/// Which number a bulk edit touches.
enum BulkPriceField { price, cost }

/// How the new number is worked out.
enum BulkPriceMode {
  /// Every selected product gets the same amount.
  setTo,

  /// Every selected product's own amount moves by a percentage (`+10`, `-5`).
  percent,
}

/// A bulk price/cost change, as a value object (Plan 015 B2.2).
///
/// Pure and testable: the page collects the choice, this works out every new
/// number, and the repository only writes. The maths lives here precisely
/// because getting it wrong is silent — a shop does not notice a price that is
/// 1 pound off until the day's takings do not add up.
class BulkPriceEdit {
  final BulkPriceField field;
  final BulkPriceMode mode;

  /// The amount (for [BulkPriceMode.setTo]) or the percentage delta (for
  /// [BulkPriceMode.percent], where `10` means +10% and `-10` means −10%).
  final double value;

  const BulkPriceEdit({
    required this.field,
    required this.mode,
    required this.value,
  });

  double _current(Product p) =>
      field == BulkPriceField.price ? p.price : p.cost;

  /// Round to what the currency can actually represent: whole pounds for SP
  /// (piastres are dead — the same rule `usdToSp` follows at the conversion
  /// boundary), two decimals for a USD-priced product.
  static double _round(double v, PriceCurrency currency) =>
      currency == PriceCurrency.usd
          ? double.parse(v.toStringAsFixed(2))
          : v.roundToDouble();

  /// The number [p] would end up with. Never negative, never non-finite: a
  /// −200% entry means "free", not "the shop pays the customer".
  double newValueFor(Product p) {
    final current = _current(p);
    final raw =
        mode == BulkPriceMode.setTo ? value : current * (1 + value / 100);
    if (!raw.isFinite) return current;
    return _round(raw < 0 ? 0 : raw, p.priceCurrency);
  }

  /// Whether this edit actually moves [p]. Used for the "N products will
  /// change" preview, and to skip no-op writes.
  ///
  /// Note a percentage of zero is still zero, so a product with no cost
  /// recorded is untouched by "raise cost 10%" — there is nothing to raise.
  bool changes(Product p) => newValueFor(p) != _current(p);

  Product applyTo(Product p) {
    final v = newValueFor(p);
    return field == BulkPriceField.price
        ? p.copyWith(price: v)
        : p.copyWith(cost: v);
  }
}

/// True when [products] are not all priced in the same currency.
///
/// This blocks [BulkPriceMode.setTo] only. "Every one of these is now 5000"
/// is meaningless across a mixed selection — 5000 pounds and 5000 dollars are
/// not the same instruction, and the app must not guess which was meant. A
/// **percentage** has no such problem: +10% is +10% in any currency, so that
/// mode stays open.
bool mixesCurrencies(Iterable<Product> products) =>
    products.map((p) => p.priceCurrency).toSet().length > 1;
