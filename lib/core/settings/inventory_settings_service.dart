import '../database/daos/settings_dao.dart';

/// Whether the POS refuses to sell a *tracked* product past its on-hand
/// quantity ("don't sell below zero").
///
/// **Off by default, and that default is deliberate.** Stock is optional in this
/// app — plenty of shops sell loose/produce/untracked items they never count,
/// and on-hand for those sits at 0 forever. Blocking a sale the cashier is
/// physically making would be worse than letting the number go negative, so
/// overselling stays allowed unless the owner explicitly turns strict inventory
/// on. Stored as a single [AppSettings] key-value row (no table, no migration),
/// same as the exchange rate and backup flags.
class InventorySettingsService {
  final SettingsDao _dao;
  const InventorySettingsService(this._dao);

  static const _blockOversellKey = 'inventory_block_oversell';

  /// True when the owner has enabled strict inventory. Any value other than the
  /// literal `'true'` (including an unset key) reads as off.
  Future<bool> isBlockOversellEnabled() async {
    final raw = await _dao.getValue(_blockOversellKey);
    return raw == 'true';
  }

  /// Persist the strict-inventory flag.
  Future<void> setBlockOversell(bool enabled) =>
      _dao.setValue(_blockOversellKey, enabled.toString());
}
