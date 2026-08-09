// Option-list surgery behind category rename/delete (Plan 014 step 3).
//
// Pure, so a host unit test. The SQL half — actually moving the products —
// needs the real engine and lives in integration_test/category_propagation_test.
import 'package:billing_app/features/attributes/domain/attribute_options.dart';
import 'package:billing_app/features/attributes/domain/product_category.dart';
import 'package:billing_app/features/attributes/domain/entities/attribute_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('rename', () {
    test('replaces the option in place', () {
      expect(
        renameOptionInList(['مشروبات', 'ألبان', 'تنظيف'], 'مشروبات', 'عصائر'),
        ['عصائر', 'ألبان', 'تنظيف'],
      );
    });

    test('renaming onto an existing option merges instead of duplicating', () {
      // The owner tidying "مشروبات" into their existing "عصائر" means the two
      // become one section. Listing "عصائر" twice would be the bug.
      expect(
        renameOptionInList(['عصائر', 'مشروبات', 'ألبان'], 'مشروبات', 'عصائر'),
        ['عصائر', 'ألبان'],
      );
    });

    test('the surviving entry keeps the earlier position', () {
      // Chips must not jump around after a tidy-up.
      expect(
        renameOptionInList(['أ', 'ب', 'ج'], 'أ', 'ج'),
        ['ج', 'ب'],
      );
    });

    test('a blank or unchanged target leaves the list alone', () {
      expect(renameOptionInList(['أ', 'ب'], 'أ', '   '), ['أ', 'ب']);
      expect(renameOptionInList(['أ', 'ب'], 'أ', 'أ'), ['أ', 'ب']);
    });

    test('renaming something that is not in the list invents nothing', () {
      // Products may still hold a value whose option was deleted earlier; they
      // get moved, but the option list is not fabricated to explain it.
      expect(renameOptionInList(['أ', 'ب'], 'ج', 'د'), ['أ', 'ب']);
    });

    test('trims the new name', () {
      expect(renameOptionInList(['أ'], 'أ', '  ب  '), ['ب']);
    });
  });

  group('remove and add', () {
    test('remove drops only that option', () {
      expect(removeOptionFromList(['أ', 'ب', 'ج'], 'ب'), ['أ', 'ج']);
    });

    test('add appends, and refuses blanks and duplicates', () {
      expect(addOptionToList(['أ'], 'ب'), ['أ', 'ب']);
      expect(addOptionToList(['أ'], '  '), ['أ']);
      expect(addOptionToList(['أ'], 'أ'), ['أ']);
      expect(addOptionToList(['أ'], '  ب '), ['أ', 'ب']);
    });
  });

  group('the category field', () {
    test('is found by id, never by label', () {
      // The owner can rename the field itself; the tab must keep working.
      final renamed = newCategoryField(['أ']).copyWith(label: 'التصنيف');
      expect(categoryFieldOf([renamed])?.id, kCategoryFieldId);
      expect(categoryFieldOf([]), isNull);
    });

    test('is a select field, in the list, off the receipt', () {
      final field = newCategoryField(['مشروبات']);
      expect(field.type, AttributeType.select);
      expect(field.showInList, isTrue);
      // Plan 014: a customer does not need the shelf layout on their receipt.
      expect(field.showOnReceipt, isFalse);
    });

    test('the JSON path is quoted, so a uuid id is safe', () {
      expect(attributeJsonPath('category'), r'$."category"');
      expect(attributeJsonPath('3f2a-9c'), r'$."3f2a-9c"');
    });

    test('an empty value is the "no category" bucket', () {
      expect(isUncategorized(''), isTrue);
      expect(isUncategorized('مشروبات'), isFalse);
    });
  });
}
