// Pure list surgery on a `select` field's option list (Plan 014 step 3).
//
// Kept out of the repository so the merge rule — the part that is easy to get
// subtly wrong — can be unit-tested without a database.

/// The option list after renaming [from] to [to].
///
/// Renaming onto an option that **already exists** folds the two into one entry
/// instead of listing it twice. That is not an edge case to defend against, it
/// is the feature: an owner who renames "مشروبات" to their existing "عصائر" is
/// merging two categories on purpose, and the products of both end up in one
/// place. Order is preserved, and the surviving entry keeps the earlier
/// position — the chips do not jump around after a tidy-up.
///
/// If [from] is not in the list the list comes back unchanged: the products
/// still get moved (they may hold a value whose option was removed earlier),
/// but nothing is invented in the option list to explain it.
List<String> renameOptionInList(List<String> options, String from, String to) {
  final target = to.trim();
  if (target.isEmpty || target == from) return List.of(options);
  final out = <String>[];
  for (final option in options) {
    final next = option == from ? target : option;
    if (!out.contains(next)) out.add(next);
  }
  return out;
}

/// The option list with [value] removed. Used together with clearing the value
/// off every product that held it — see `AttributesDao.removeOptionEverywhere`.
List<String> removeOptionFromList(List<String> options, String value) =>
    options.where((o) => o != value).toList();

/// The option list with [value] appended, unless it is blank or already there.
/// Used when a new category is typed straight into the bulk-assign sheet.
List<String> addOptionToList(List<String> options, String value) {
  final v = value.trim();
  if (v.isEmpty || options.contains(v)) return List.of(options);
  return [...options, v];
}
