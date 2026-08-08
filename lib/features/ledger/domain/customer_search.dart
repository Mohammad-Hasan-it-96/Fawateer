import '../../../core/utils/arabic_search.dart';
import 'entities/customer_account.dart';

/// Pure predicate for the customers list search (Plan 013 #2), kept out of the
/// widget so it can be unit-tested — the `productMatchesSearch` precedent.
///
/// Matches **name or phone**. Phone matters as much as name: a shopkeeper often
/// knows the number from a WhatsApp message and not the spelling of the name,
/// and two customers called أحمد are told apart by their number.
///
/// Both sides go through [normalizeForSearch], which is what makes `احمد` find
/// `أحمد` and Arabic-Indic digits find a Latin-digit phone number.
///
/// An empty query matches everything, so clearing the box restores the list.
bool customerMatchesSearch(CustomerAccount account, String query) {
  if (query.isEmpty) return true;
  final needle = normalizeForSearch(query);
  if (needle.isEmpty) return true;
  final customer = account.customer;
  return normalizeForSearch(customer.name).contains(needle) ||
      normalizeForSearch(customer.phone).contains(needle);
}
