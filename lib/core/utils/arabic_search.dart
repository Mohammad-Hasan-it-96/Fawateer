/// Text normalisation for search in an Arabic-first app (Plan 013 #2).
///
/// **Without this, roughly half of all Arabic searches fail** for reasons the
/// user cannot see. `أحمد` and `احمد` are the same name to a shopkeeper and
/// different strings to `String.contains`; so are `فاطمة` and `فاطمه`. Nobody
/// types the hamza consistently, and a search box that finds nothing looks
/// broken rather than picky.
///
/// The rules are the standard, conservative set:
///
/// | Written | Normalised | Why |
/// |---|---|---|
/// | `أ إ آ ٱ` | `ا` | the hamza is routinely omitted when typing |
/// | `ة` | `ه` | `فاطمة` / `فاطمه` are the same name |
/// | `ى` | `ي` | `مصطفى` / `مصطفي` |
/// | `ؤ ئ` | `و ي` | same reason, less common |
/// | tashkeel, tatweel `ـ` | removed | decoration, never typed in a search |
/// | `٠-٩` `۰-۹` | `0-9` | **phone numbers** — a keyboard set to Arabic digits |
/// | Latin | lower-cased | `Pepsi` / `pepsi` |
///
/// **Deliberately not** a full Unicode normalisation, and not stemming. This is
/// a shop's contact list and product catalogue, not a search engine; the failure
/// mode of being too clever (matching things the user did not ask for) is worse
/// here than missing an exotic spelling.
///
/// Applied to **both** sides — the query and the field — so it must be cheap and
/// total: it never throws and never returns null.
String normalizeForSearch(String raw) {
  if (raw.isEmpty) return raw;
  const arabicIndic = '٠١٢٣٤٥٦٧٨٩';
  const persian = '۰۱۲۳۴۵۶۷۸۹';

  final buf = StringBuffer();
  for (final ch in raw.toLowerCase().split('')) {
    switch (ch) {
      case 'أ':
      case 'إ':
      case 'آ':
      case 'ٱ':
        buf.write('ا');
      case 'ة':
        buf.write('ه');
      case 'ى':
        buf.write('ي');
      case 'ؤ':
        buf.write('و');
      case 'ئ':
        buf.write('ي');
      // Tatweel is a typographic stretch, not a letter.
      case 'ـ':
        break;
      default:
        final ai = arabicIndic.indexOf(ch);
        if (ai >= 0) {
          buf.write(ai);
          break;
        }
        final fa = persian.indexOf(ch);
        if (fa >= 0) {
          buf.write(fa);
          break;
        }
        // Tashkeel (U+064B..U+0652) and the superscript alef (U+0670).
        final code = ch.codeUnitAt(0);
        if ((code >= 0x064B && code <= 0x0652) || code == 0x0670) break;
        buf.write(ch);
    }
  }
  return buf.toString();
}

/// True when [haystack] contains [needle], both normalised. An empty needle
/// matches everything, so a cleared search box shows the whole list.
bool searchMatches(String haystack, String needle) {
  if (needle.isEmpty) return true;
  return normalizeForSearch(haystack).contains(normalizeForSearch(needle));
}
