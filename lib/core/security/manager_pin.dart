import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../network/api_config.dart';

/// Pure logic behind the manager lock (Plan 016 B) — no storage, no UI, so it
/// can be tested exactly.
///
/// **What this is, and is not.** It is a speed bump on the owner's own till:
/// it stops a helper deleting a sale while the owner is out. It is not a login,
/// there is no session and no user list, and anyone holding the unlocked phone
/// for long enough will get past a 4-digit code. Describing it as more than
/// that to a shop would be a lie they'd rely on.

/// A PIN is 4 to 6 digits — long enough not to be guessed on the second try,
/// short enough to type one-handed at a busy counter.
///
/// ASCII digits only. Arabic-Indic digits are deliberately **not** accepted
/// here: the field restricts input to `0-9`, and silently normalising them
/// would mean a PIN set with one keyboard couldn't be typed with the other.
bool isValidPin(String pin) => RegExp(r'^\d{4,6}$').hasMatch(pin);

/// Hash a PIN for storage. Never store the PIN itself: this row travels inside
/// every Google Drive backup (which is not encrypted) and every future sync
/// snapshot, so a plain PIN would be readable by anyone holding either.
///
/// The salt is per-install, so two shops using `1234` do not share a hash and
/// a stolen backup can't be matched against a precomputed table.
String hashPin(String salt, String pin) =>
    sha256.convert(utf8.encode('$salt|$pin')).toString();

/// A fresh 128-bit salt, hex encoded. `Random.secure()` — a predictable salt is
/// no salt at all.
String newPinSalt() {
  final rng = Random.secure();
  final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}

/// The six-digit code support gives a shop that has forgotten its PIN
/// (Plan 017, option R1).
///
/// **Derived, never fetched.** A shop locked out of its own till is very often
/// a shop with no internet — that is precisely when this is needed — so the app
/// has to be able to check the code offline. Support computes the same value
/// with a small internal tool; see `docs/manager-pin-reset.md`.
///
/// It changes daily, so a code shared once does not become a permanent master
/// key for that device.
///
/// The secret lives in the APK and an APK can be pulled apart. That is
/// accepted: this guards an owner's own till, not a bank vault, and the
/// alternative (a server call) fails exactly when it is needed.
String pinResetCode(String deviceId, DateTime day) {
  final d = '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';
  final digest =
      sha256.convert(utf8.encode('$deviceId|${ApiConfig.pinResetSecret}|$d'));
  final n = (digest.bytes[0] << 16 | digest.bytes[1] << 8 | digest.bytes[2]) %
      1000000;
  return n.toString().padLeft(6, '0');
}

/// Whether [entered] is a valid reset code for this device around [now].
///
/// Yesterday and tomorrow are accepted as well as today. Support and the shop
/// can be on opposite sides of midnight, or in different time zones, and a code
/// that stops working while it is being read out loud would send the shop back
/// to support for nothing. The window is still short enough that a code does
/// not become a standing key.
bool isValidPinResetCode(String entered, String deviceId, DateTime now) {
  final code = entered.trim();
  if (code.length != 6) return false;
  final today = DateTime(now.year, now.month, now.day);
  for (final offset in const [0, -1, 1]) {
    if (pinResetCode(deviceId, today.add(Duration(days: offset))) == code) {
      return true;
    }
  }
  return false;
}
