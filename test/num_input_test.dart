import 'package:billing_app/core/utils/num_input.dart';
import 'package:billing_app/core/utils/format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NumInput.parseFlexibleNumber', () {
    test('parses plain ASCII numbers', () {
      expect(NumInput.parseFlexibleNumber('12'), 12);
      expect(NumInput.parseFlexibleNumber('12.5'), 12.5);
      expect(NumInput.parseFlexibleNumber('  3.0 '), 3.0);
    });

    test('normalizes Arabic-Indic digits and separators', () {
      expect(NumInput.parseFlexibleNumber('١٢'), 12); // ١٢ = 12
      expect(NumInput.parseFlexibleNumber('١٢٫٥'), 12.5); // Arabic decimal ٫
      expect(NumInput.parseFlexibleNumber('12,5'), 12.5); // comma decimal
    });

    test('rejects non-finite and non-numeric input (never crashes callers)', () {
      expect(NumInput.parseFlexibleNumber('Infinity'), isNull);
      expect(NumInput.parseFlexibleNumber('NaN'), isNull);
      expect(NumInput.parseFlexibleNumber('1e309'), isNull); // overflows to inf
      expect(NumInput.parseFlexibleNumber('abc'), isNull);
      expect(NumInput.parseFlexibleNumber(''), isNull);
      expect(NumInput.parseFlexibleNumber(null), isNull);
    });
  });

  group('formatQty non-finite guard', () {
    test('does not throw on Infinity/NaN', () {
      expect(formatQty(double.infinity), '0');
      expect(formatQty(double.nan), '0');
    });

    test('still formats normal quantities', () {
      expect(formatQty(2), '2');
      expect(formatQty(1.5), '1.5');
    });
  });
}
