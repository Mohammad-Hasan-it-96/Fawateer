// The manager lock's pure logic (Plan 016 B) and its storage rules.
//
// Worth testing hard for two reasons. The hash is what stops a PIN travelling
// in plain text inside an unencrypted Google Drive backup, and the reset code
// is the *only* way back in for a shop that forgot its PIN — if it is wrong,
// support cannot help them at all.
import 'package:billing_app/core/security/manager_pin.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isValidPin', () {
    test('accepts 4 to 6 digits', () {
      expect(isValidPin('1234'), isTrue);
      expect(isValidPin('12345'), isTrue);
      expect(isValidPin('123456'), isTrue);
    });

    test('refuses anything shorter, longer, or not digits', () {
      expect(isValidPin('123'), isFalse);
      expect(isValidPin('1234567'), isFalse);
      expect(isValidPin(''), isFalse);
      expect(isValidPin('12a4'), isFalse);
      expect(isValidPin('12 4'), isFalse);
    });

    test('refuses Arabic-Indic digits', () {
      // Not an oversight: the field only emits ASCII digits, and quietly
      // accepting ٤ here would let a PIN be *set* with one keyboard and become
      // untypeable with the other.
      expect(isValidPin('١٢٣٤'), isFalse);
    });
  });

  group('hashPin', () {
    test('never returns the PIN itself', () {
      final hash = hashPin('salt', '1234');
      expect(hash.contains('1234'), isFalse);
      expect(hash.length, 64); // sha256 hex
    });

    test('is stable for the same salt and PIN', () {
      expect(hashPin('salt', '1234'), hashPin('salt', '1234'));
    });

    test('two shops with the same PIN do not share a hash', () {
      // This is what the per-install salt buys: a stolen backup cannot be
      // matched against a precomputed table of common PINs.
      expect(hashPin('saltA', '1234'), isNot(hashPin('saltB', '1234')));
    });

    test('a different PIN gives a different hash', () {
      expect(hashPin('salt', '1234'), isNot(hashPin('salt', '1235')));
    });
  });

  group('newPinSalt', () {
    test('is 128 bits of hex', () {
      expect(newPinSalt().length, 32);
      expect(RegExp(r'^[0-9a-f]{32}$').hasMatch(newPinSalt()), isTrue);
    });

    test('is different every time', () {
      final salts = List.generate(20, (_) => newPinSalt()).toSet();
      expect(salts.length, 20);
    });
  });

  group('pinResetCode', () {
    final day = DateTime(2026, 8, 10);

    test('is always six digits', () {
      for (var i = 0; i < 40; i++) {
        final code = pinResetCode('device$i', day);
        expect(code.length, 6, reason: 'device$i gave "$code"');
        expect(RegExp(r'^\d{6}$').hasMatch(code), isTrue);
      }
    });

    test('is stable — support and the app must compute the same value', () {
      expect(pinResetCode('abc', day), pinResetCode('abc', day));
    });

    test('differs per device', () {
      expect(pinResetCode('abc', day), isNot(pinResetCode('abd', day)));
    });

    test('changes daily, so a shared code is not a permanent key', () {
      expect(pinResetCode('abc', day),
          isNot(pinResetCode('abc', DateTime(2026, 8, 12))));
    });
  });

  group('isValidPinResetCode', () {
    final now = DateTime(2026, 8, 10, 14, 30);

    test("accepts today's code", () {
      final code = pinResetCode('abc', DateTime(2026, 8, 10));
      expect(isValidPinResetCode(code, 'abc', now), isTrue);
    });

    test('accepts yesterday and tomorrow', () {
      // Support and the shop can be either side of midnight, or in different
      // time zones. A code that expires mid-phone-call sends them back for
      // nothing.
      expect(
          isValidPinResetCode(
              pinResetCode('abc', DateTime(2026, 8, 9)), 'abc', now),
          isTrue);
      expect(
          isValidPinResetCode(
              pinResetCode('abc', DateTime(2026, 8, 11)), 'abc', now),
          isTrue);
    });

    test('refuses a code from two days ago', () {
      expect(
          isValidPinResetCode(
              pinResetCode('abc', DateTime(2026, 8, 8)), 'abc', now),
          isFalse);
    });

    test("refuses another device's code", () {
      // Otherwise one leaked code would open every install.
      final other = pinResetCode('other-device', DateTime(2026, 8, 10));
      expect(isValidPinResetCode(other, 'abc', now), isFalse);
    });

    test('tolerates surrounding spaces from a pasted message', () {
      final code = pinResetCode('abc', DateTime(2026, 8, 10));
      expect(isValidPinResetCode('  $code ', 'abc', now), isTrue);
    });

    test('refuses empty and wrong-length input', () {
      expect(isValidPinResetCode('', 'abc', now), isFalse);
      expect(isValidPinResetCode('12345', 'abc', now), isFalse);
      expect(isValidPinResetCode('1234567', 'abc', now), isFalse);
    });

    test('crossing a month end still resolves', () {
      // The ±1 day window is date arithmetic, not string maths — the last day
      // of a month must roll into the first of the next.
      final endOfMonth = DateTime(2026, 8, 31, 23, 50);
      final tomorrow = pinResetCode('abc', DateTime(2026, 9, 1));
      expect(isValidPinResetCode(tomorrow, 'abc', endOfMonth), isTrue);
    });
  });
}
