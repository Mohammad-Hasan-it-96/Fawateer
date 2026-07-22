/// Shape and spacing scale.
///
/// These exist so "how round is a card" and "how much padding does a page get"
/// have one answer instead of a literal at each call site — the same reason the
/// colours in `AppTheme` are named. Radii are referenced by the theme itself,
/// so changing [radiusCard] restyles every `Card` in the app.
class AppTokens {
  const AppTokens._();

  // ── Radii ─────────────────────────────────────────────────────────────
  /// Buttons and inputs share a radius so a field and the button under it line
  /// up visually; [radiusCard] and [radiusSheet] are deliberately larger.
  static const double radiusButton = 12;
  static const double radiusField = 12;
  static const double radiusCard = 16;
  static const double radiusSheet = 20;

  // ── Spacing ───────────────────────────────────────────────────────────
  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 12;
  static const double spaceLg = 16;
  static const double spaceXl = 24;

  /// Standard page gutter. Matches the 16pt padding pages already use.
  static const double pagePadding = spaceLg;
}
