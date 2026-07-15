import '../database/daos/settings_dao.dart';

/// Reads/writes the shop's USD→SP exchange rate, stored in the [AppSettings]
/// key-value table. The rate is "SP per 1 USD" — the number the owner sets in
/// Settings. Snapshotting the rate onto each sale (not reading it here at report
/// time) is what keeps historical invoices immutable; this service only holds
/// the single *current* rate used to price new sales.
class ExchangeRateService {
  final SettingsDao _dao;
  const ExchangeRateService(this._dao);

  static const _rateKey = 'exchange_rate_usd_sp';
  static const _updatedKey = 'exchange_rate_updated_at';

  /// The current SP-per-USD rate, or null if the owner hasn't set one yet.
  Future<double?> getRate() async {
    final raw = await _dao.getValue(_rateKey);
    if (raw == null) return null;
    final v = double.tryParse(raw);
    return (v != null && v.isFinite && v > 0) ? v : null;
  }

  /// When the rate was last set (for the stale-rate nudge), or null.
  Future<DateTime?> getUpdatedAt() async {
    final raw = await _dao.getValue(_updatedKey);
    final ms = raw == null ? null : int.tryParse(raw);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  /// Persist a new rate and stamp the update time.
  Future<void> setRate(double rate) async {
    await _dao.setValue(_rateKey, rate.toString());
    await _dao.setValue(
        _updatedKey, DateTime.now().millisecondsSinceEpoch.toString());
  }
}

/// Resolve [amount] (in USD) to whole SP at [rate] (SP per USD). Rounds to a
/// whole pound at the conversion boundary so downstream SP sums stay clean —
/// piastres are effectively dead. Returns null when the rate is missing/invalid
/// so callers can guard (never silently price a USD item at its raw number).
double? usdToSp(double amount, double? rate) {
  if (rate == null || !rate.isFinite || rate <= 0) return null;
  return (amount * rate).roundToDouble();
}
