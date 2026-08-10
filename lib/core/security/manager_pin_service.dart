import '../database/daos/settings_dao.dart';
import 'manager_pin.dart';

/// Storage and verification for the manager PIN (Plan 016 B).
///
/// Two [AppSettings] key-value rows, no table and no migration — the same
/// approach as the exchange rate and the backup flags. The hash and its salt
/// live **together in the database** on purpose: a Google Drive restore onto a
/// new phone has to carry both, or the shop's own PIN would stop working the
/// moment they replaced their handset.
///
/// The PIN itself is never stored. See [hashPin].
class ManagerPinService {
  final SettingsDao _dao;
  ManagerPinService(this._dao);

  static const _hashKey = 'manager_pin_hash';
  static const _saltKey = 'manager_pin_salt';

  /// How many wrong tries before the guard makes the user wait.
  static const int maxAttempts = 5;
  static const Duration cooldown = Duration(seconds: 30);

  // In memory only, and honestly so: this resets when the app restarts, so it
  // slows down guessing at the counter rather than defeating someone patient.
  // Persisting it would mean a wrong-PIN streak could lock the *owner* out of
  // their own till across restarts, which is a worse failure than the one it
  // prevents.
  int _failures = 0;
  DateTime? _lockedUntil;

  /// Whether a PIN is set. No cached copy — this is one indexed row, and a
  /// cache could go stale against the settings screen that just cleared it.
  Future<bool> isPinSet() async {
    final hash = await _dao.getValue(_hashKey);
    return hash != null && hash.isNotEmpty;
  }

  /// Store [pin], minting a salt on first use. Returns false if the format is
  /// wrong, so a caller can't accidentally set an unenterable PIN.
  Future<bool> setPin(String pin) async {
    if (!isValidPin(pin)) return false;
    var salt = await _dao.getValue(_saltKey);
    if (salt == null || salt.isEmpty) {
      salt = newPinSalt();
      await _dao.setValue(_saltKey, salt);
    }
    await _dao.setValue(_hashKey, hashPin(salt, pin));
    _resetAttempts();
    return true;
  }

  /// True when [pin] matches. Always false while [cooldownRemaining] is
  /// running, so the wait can't be skipped by simply asking again.
  Future<bool> verify(String pin) async {
    if (cooldownRemaining != null) return false;
    final hash = await _dao.getValue(_hashKey);
    final salt = await _dao.getValue(_saltKey);
    if (hash == null || hash.isEmpty || salt == null || salt.isEmpty) {
      // No PIN set: nothing to verify against. Treated as a failure rather than
      // a pass, because every caller checks [isPinSet] first — reaching here
      // means something is wrong, and the safe answer is "no".
      return false;
    }
    if (hashPin(salt, pin) == hash) {
      _resetAttempts();
      return true;
    }
    _failures++;
    if (_failures >= maxAttempts) {
      _lockedUntil = DateTime.now().add(cooldown);
      _failures = 0;
    }
    return false;
  }

  /// Time left before another try is allowed, or null when not waiting.
  Duration? get cooldownRemaining {
    final until = _lockedUntil;
    if (until == null) return null;
    final left = until.difference(DateTime.now());
    if (left <= Duration.zero) {
      _lockedUntil = null;
      return null;
    }
    return left;
  }

  /// Remove the lock entirely (from Settings with the current PIN, or from the
  /// forgot-PIN flow with a support reset code). The salt goes too: keeping it
  /// would let an old backup's hash be checked against a PIN the shop believes
  /// they deleted.
  Future<void> clear() async {
    await _dao.deleteKey(_hashKey);
    await _dao.deleteKey(_saltKey);
    _resetAttempts();
  }

  void _resetAttempts() {
    _failures = 0;
    _lockedUntil = null;
  }
}
