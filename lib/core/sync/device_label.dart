/// What this phone should be called in the shop's device list (Plan 002,
/// evotech-core 2026-08-11 #2).
///
/// **Telling two linked phones apart is the whole problem this solves.** Before
/// the server carried a name, a three-till shop saw three rows reading
/// "هاتف مرتبط", distinguished only by a last-seen time — and revoking the wrong
/// one takes a working till off the counter mid-shift.
library;

import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

/// The longest name the server stores (`device_seats.name` VARCHAR(40),
/// trimmed and capped server-side, counted in characters not bytes so Arabic
/// is not silently halved).
///
/// We cap here too, and it is not redundant: the owner must see the field stop
/// accepting text, rather than type a long name, save it, and watch it come
/// back shortened by a rule nothing on screen mentioned.
const int kDeviceNameMaxLength = 40;

/// Trim and cap a typed name the way the server will.
///
/// Returns null for empty-after-trim, which is how a name is **cleared** —
/// the server stores NULL and the row falls back to its role plus last-seen.
/// Whitespace-only is deliberately the same as empty: a name made of spaces
/// would render as a blank row that looks like a bug.
String? sanitizeDeviceName(String? raw) {
  final trimmed = raw?.trim() ?? '';
  if (trimmed.isEmpty) return null;
  // Code points, not UTF-16 units: `length` would count an emoji as two and cut
  // an Arabic name short of the 40 the server actually allows.
  final runes = trimmed.runes.toList();
  if (runes.length <= kDeviceNameMaxLength) return trimmed;
  return String.fromCharCodes(runes.take(kDeviceNameMaxLength));
}

/// A name to PROPOSE at enrollment — the handset's own model, e.g.
/// "Infinix X6833B".
///
/// It is a suggestion, never a claim: the owner's rename always wins, and the
/// server is free to trim or reject it. The point is only that a shop which
/// never renames anything still sees two rows it can tell apart, instead of two
/// identical ones.
///
/// **Never throws and never blocks enrollment.** No plugin, an unsupported
/// platform or any plugin error all read as "no suggestion" — the seat enrolls
/// unnamed, exactly as it did before this existed.
Future<String?> proposedDeviceName() async {
  try {
    if (Platform.isAndroid) {
      final info = await DeviceInfoPlugin().androidInfo;
      // brand + model, because `model` alone is often a bare part number
      // ("X6833B") that means nothing to a shopkeeper.
      final parts = [info.brand.trim(), info.model.trim()]
          .where((p) => p.isNotEmpty)
          .toList();
      return sanitizeDeviceName(parts.join(' '));
    }
    if (Platform.isIOS) {
      final info = await DeviceInfoPlugin().iosInfo;
      return sanitizeDeviceName(info.name.isNotEmpty ? info.name : info.model);
    }
  } catch (_) {
    // fall through
  }
  return null;
}
