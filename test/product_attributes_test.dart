import 'package:billing_app/core/attributes/product_attributes.dart';
import 'package:billing_app/features/attributes/domain/entities/attribute_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProductAttributes', () {
    test('empty round-trips to blank JSON', () {
      expect(ProductAttributes.empty.toJson(), '');
      expect(ProductAttributes.empty.isEmpty, true);
    });

    test('trims and drops blank keys/values on construction', () {
      final a = ProductAttributes(const {' color ': ' red ', 'x': '', 'y': '  '});
      expect(a.values, {'color': 'red'});
    });

    test('encodes and decodes symmetrically', () {
      final a = ProductAttributes(const {'color': 'أسود', 'storage': '128'});
      final decoded = ProductAttributes.fromJson(a.toJson());
      expect(decoded.values, a.values);
      expect(decoded['color'], 'أسود');
      expect(decoded['storage'], '128');
    });

    test('defensive: null / blank / garbage JSON → empty (never throws)', () {
      expect(ProductAttributes.fromJson(null).isEmpty, true);
      expect(ProductAttributes.fromJson('').isEmpty, true);
      expect(ProductAttributes.fromJson('not json {').isEmpty, true);
      expect(ProductAttributes.fromJson('[1,2,3]').isEmpty, true); // not a map
    });

    test('coerces non-string JSON values to strings', () {
      final decoded = ProductAttributes.fromJson('{"ram":16,"orig":true}');
      expect(decoded['ram'], '16');
      expect(decoded['orig'], 'true');
    });

    test('withValue sets, and a blank value clears', () {
      final a = ProductAttributes(const {'color': 'red'});
      expect(a.withValue('size', 'L').values, {'color': 'red', 'size': 'L'});
      expect(a.withValue('color', '').values, isEmpty);
    });
  });

  group('AttributeType', () {
    test('persists and parses by name; unknown falls back to text', () {
      for (final t in AttributeType.values) {
        expect(AttributeType.fromName(t.name), t);
      }
      expect(AttributeType.fromName('multiSelect'), AttributeType.text);
      expect(AttributeType.fromName(null), AttributeType.text);
    });

    test('only select is optioned', () {
      expect(AttributeType.select.isOptioned, true);
      expect(AttributeType.text.isOptioned, false);
      expect(AttributeType.number.isOptioned, false);
    });
  });
}
