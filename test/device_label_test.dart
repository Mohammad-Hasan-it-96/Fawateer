// The pure half of device naming (Plan 002, evotech-core 2026-08-11 #2).
//
// `proposedDeviceName` reads a plugin and is not testable on the host; what IS
// worth pinning is the rule the typed name goes through, because it has to
// agree with the server's. The server trims, caps at 40 CHARACTERS (not bytes)
// and stores NULL for empty-after-trim. If this disagrees, the owner types a
// name, saves it, and gets a different one back with nothing on screen
// explaining why.
import 'package:billing_app/core/sync/device_label.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('sanitizeDeviceName', () {
    test('trims, because a stray space is not part of a name', () {
      expect(sanitizeDeviceName('  الكاشير  '), 'الكاشير');
    });

    test('empty and whitespace-only both clear the name', () {
      // Null is how a name is REMOVED — the server stores NULL and the row
      // falls back to its role. Whitespace must land in the same place, or a
      // name made of spaces renders as a blank row that looks like a bug.
      expect(sanitizeDeviceName(''), isNull);
      expect(sanitizeDeviceName('   '), isNull);
      expect(sanitizeDeviceName(null), isNull);
    });

    test('a 40-character Arabic name survives whole', () {
      // The reason the cap counts code points: Arabic is two BYTES per letter
      // in UTF-8, so a byte cap would silently halve every Arabic name.
      final name = 'ك' * kDeviceNameMaxLength;
      expect(sanitizeDeviceName(name), name);
      expect(sanitizeDeviceName(name)!.runes.length, 40);
    });

    test('a longer name is cut to the cap, not rejected', () {
      // Rejecting would mean an error message; cutting matches what the server
      // does, so the owner sees the same result either way.
      final cut = sanitizeDeviceName('a' * 60);
      expect(cut!.length, kDeviceNameMaxLength);
    });

    test('an emoji counts as one character, not two', () {
      // `String.length` counts UTF-16 units, so a name of 40 emoji would be
      // cut in half — and cutting between the halves of a surrogate pair
      // produces a broken character, not a shorter name.
      final name = '📱' * 40;
      final result = sanitizeDeviceName(name)!;
      expect(result.runes.length, 40);
      expect(result, name);
    });

    test('trimming happens before the cap', () {
      // Otherwise 40 characters preceded by spaces would lose its last letters
      // to whitespace that was never going to be stored.
      final result = sanitizeDeviceName('   ${'b' * 40}   ');
      expect(result, 'b' * 40);
    });
  });
}
