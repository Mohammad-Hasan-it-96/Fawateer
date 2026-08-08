// Arabic-aware search matching (Plan 013 #2).
//
// This is the layer that decides whether a search box in an Arabic-first app
// feels working or broken. Nobody types the hamza consistently, so `احمد` must
// find `أحمد`; a keyboard set to Arabic digits must still find a phone number
// stored in Latin digits. Every case here is a search a shopkeeper would type
// and expect to work.
import 'package:billing_app/core/utils/arabic_search.dart';
import 'package:billing_app/features/ledger/domain/customer_search.dart';
import 'package:billing_app/features/ledger/domain/entities/customer.dart';
import 'package:billing_app/features/ledger/domain/entities/customer_account.dart';
import 'package:flutter_test/flutter_test.dart';

CustomerAccount _acc(String name, {String phone = ''}) => CustomerAccount(
      customer: Customer(id: 'c1', name: name, phone: phone, createdAt: DateTime(2026, 1, 1)),
      balance: 0,
    );

void main() {
  group('normalizeForSearch', () {
    test('the hamza forms all collapse to plain alef', () {
      // The single most common cause of a failed Arabic search.
      for (final spelling in const ['أحمد', 'إحمد', 'آحمد', 'ٱحمد']) {
        expect(normalizeForSearch(spelling), 'احمد');
      }
    });

    test('taa marbuta reads as haa', () {
      // فاطمة / فاطمه are the same name to everyone except String.contains.
      expect(normalizeForSearch('فاطمة'), normalizeForSearch('فاطمه'));
    });

    test('alef maqsura reads as yaa', () {
      expect(normalizeForSearch('مصطفى'), normalizeForSearch('مصطفي'));
    });

    test('tashkeel and tatweel are dropped', () {
      // A product typed with vowel marks would otherwise be unreachable by
      // anyone typing it plainly — which is everyone.
      expect(normalizeForSearch('مِيَاه'), normalizeForSearch('مياه'));
      expect(normalizeForSearch('مـيـاه'), normalizeForSearch('مياه'));
    });

    test('Arabic-Indic and Persian digits become Latin digits', () {
      // Phone search: the number is stored as typed on one keyboard and
      // searched on another.
      expect(normalizeForSearch('٠٩٣٣'), '0933');
      expect(normalizeForSearch('۰۹۳۳'), '0933');
    });

    test('Latin text is lower-cased', () {
      expect(normalizeForSearch('Pepsi'), 'pepsi');
    });

    test('an empty string stays empty and never throws', () {
      expect(normalizeForSearch(''), '');
    });
  });

  group('searchMatches', () {
    test('an empty needle matches everything', () {
      // Clearing the box must restore the full list, not empty it.
      expect(searchMatches('anything', ''), isTrue);
    });

    test('it matches on a substring, both sides normalised', () {
      expect(searchMatches('أحمد العلي', 'احمد'), isTrue);
      expect(searchMatches('احمد العلي', 'أحمد'), isTrue);
    });

    test('it does not match unrelated text', () {
      // The rules must not be so loose that everything matches everything.
      expect(searchMatches('أحمد', 'محمد'), isFalse);
    });
  });

  group('customerMatchesSearch', () {
    test('finds a customer by name despite the hamza', () {
      expect(customerMatchesSearch(_acc('أحمد العلي'), 'احمد'), isTrue);
    });

    test('finds a customer by phone', () {
      // A shopkeeper often has the number from WhatsApp and not the spelling
      // of the name — and two customers called أحمد are told apart by it.
      expect(customerMatchesSearch(_acc('أحمد', phone: '0933123456'), '0933'),
          isTrue);
    });

    test('finds a Latin-digit phone typed in Arabic digits', () {
      expect(customerMatchesSearch(_acc('أحمد', phone: '0933123456'), '٠٩٣٣'),
          isTrue);
    });

    test('an empty query keeps everyone', () {
      expect(customerMatchesSearch(_acc('أحمد'), ''), isTrue);
    });

    test('a customer with no phone is not a crash and not a match', () {
      expect(customerMatchesSearch(_acc('أحمد'), '0933'), isFalse);
    });

    test('a non-matching name is excluded', () {
      expect(customerMatchesSearch(_acc('أحمد'), 'سامر'), isFalse);
    });
  });
}
