import 'package:flutter/material.dart';

import 'app_tokens.dart';

/// The app's single source of colour, shape and typography.
///
/// [lightTheme] and [darkTheme] are produced by the same [_build] function from
/// a different palette, rather than being two hand-maintained copies — a change
/// to a radius or a button's padding can't land in one mode and miss the other.
///
/// **Dark mode is not finished at the page level.** The chrome themed here
/// (app bar, cards, inputs, sheets, dialogs, buttons) adapts, but page bodies
/// still hold ~370 hardcoded colour literals and will render light-on-dark
/// until they're migrated onto the named colours below. Until that lands,
/// [ThemeMode.light] must stay the default.
///
/// Typography is bundled Cairo (see `pubspec.yaml`), applied **once** via
/// [ThemeData.fontFamily] rather than repeated on every `TextStyle` — anything
/// not explicitly styled (dialog bodies, chips, snack bars) still gets Arabic
/// shaping instead of silently falling back to Roboto.
class AppTheme {
  const AppTheme._();

  static const String fontFamily = 'Cairo';

  // ── Brand ─────────────────────────────────────────────────────────────
  static const Color primaryColor = Color(0xFF6C63FF);

  /// The brand purple lightened for dark surfaces. The light-mode primary is
  /// legible on white but muddy against a near-black scaffold, so dark mode
  /// steps it up rather than reusing it.
  static const Color primaryColorDark = Color(0xFF8B84FF);

  static const Color secondaryColor = Color(0xFF03DAC6);
  static const Color errorColor = Color(0xFFB00020);
  static const Color errorColorDark = Color(0xFFCF6679);

  /// Semantic status colours. Named here because pages currently reach for
  /// `Colors.green`/`Colors.orange` ad hoc, which is what makes them
  /// theme-resistant; prefer these so both palettes have one place to swap.
  static const Color successColor = Color(0xFF2E7D32);
  static const Color warningColor = Color(0xFFE65100);

  // ── Light surfaces ────────────────────────────────────────────────────
  static const Color backgroundColor = Color(0xFFF2F2F7);
  static const Color surfaceColor = Colors.white;
  static const Color borderColor = Color(0xFFE3E3EA);

  static const Color textPrimary = Color(0xFF1C1B1F);
  static const Color textSecondary = Color(0xFF5F5D67);
  static const Color textTertiary = Color(0xFF8E8C96);

  // ── Dark surfaces ─────────────────────────────────────────────────────
  // Not pure black: an OLED-black scaffold makes the elevated card surface
  // hard to distinguish, and the app is card-heavy.
  static const Color darkBackground = Color(0xFF121218);
  static const Color darkSurface = Color(0xFF1E1E26);
  static const Color darkBorder = Color(0xFF32323C);

  static const Color darkTextPrimary = Color(0xFFF2F1F6);
  static const Color darkTextSecondary = Color(0xFFB9B7C4);
  static const Color darkTextTertiary = Color(0xFF8E8C96);

  static ThemeData get lightTheme => _build(
        brightness: Brightness.light,
        primary: primaryColor,
        error: errorColor,
        background: backgroundColor,
        surface: surfaceColor,
        border: borderColor,
        onSurface: textPrimary,
        onSurfaceVariant: textSecondary,
        hint: textTertiary,
      );

  static ThemeData get darkTheme => _build(
        brightness: Brightness.dark,
        primary: primaryColorDark,
        error: errorColorDark,
        background: darkBackground,
        surface: darkSurface,
        border: darkBorder,
        onSurface: darkTextPrimary,
        onSurfaceVariant: darkTextSecondary,
        hint: darkTextTertiary,
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color primary,
    required Color error,
    required Color background,
    required Color surface,
    required Color border,
    required Color onSurface,
    required Color onSurfaceVariant,
    required Color hint,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: brightness,
      primary: primary,
      secondary: secondaryColor,
      surface: surface,
      error: error,
      onSurface: onSurface,
    );

    // One shape and one padding across all four button roles, so a page can
    // swap FilledButton→OutlinedButton without the layout shifting.
    //
    // Built with `styleFrom` rather than by `copyWith`-ing a shared ButtonStyle:
    // `WidgetStatePropertyAll(primary)` would paint the brand colour in *every*
    // state, so a disabled button would still look tappable. `styleFrom` leaves
    // the disabled state unset, which lets M3's greyed-out defaults through —
    // load-bearing on the POS screen, where "review order" is disabled until
    // the cart has items.
    const buttonPadding = EdgeInsets.symmetric(vertical: 16, horizontal: 24);
    final buttonShape = RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusButton));
    const buttonTextStyle = TextStyle(
        fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.bold);

    OutlineInputBorder inputBorder(Color color, {double width = 1}) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusField),
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: fontFamily,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      // Pages read this for hairlines and card borders; keeping it on
      // ThemeData (not just dividerTheme) means `Theme.of(c).dividerColor`
      // works at any call site without reaching for the divider theme.
      dividerColor: border,
      colorScheme: colorScheme,
      textTheme: _textTheme(onSurface, onSurfaceVariant, hint),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        // M3 tints the bar as content scrolls under it; against a transparent
        // background that reads as a colour glitch rather than elevation.
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          color: onSurface,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
        iconTheme: IconThemeData(color: onSurface),
      ),
      cardTheme: CardThemeData(
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusCard)),
        color: surface,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: TextStyle(
            color: hint, fontWeight: FontWeight.normal, fontSize: 14),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: inputBorder(border),
        enabledBorder: inputBorder(border),
        focusedBorder: inputBorder(primary, width: 2),
        errorBorder: inputBorder(error, width: 2),
        focusedErrorBorder: inputBorder(error, width: 2),
      ),
      // Sheets must render on an opaque surface — a transparent default makes
      // any sheet that doesn't set its own background render over the scrim
      // and look hidden/see-through. Individual sheets may still override.
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppTokens.radiusSheet)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusSheet)),
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: onSurface,
        ),
        contentTextStyle: TextStyle(
            fontFamily: fontFamily, fontSize: 14, color: onSurfaceVariant),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusField)),
        contentTextStyle:
            const TextStyle(fontFamily: fontFamily, fontSize: 14),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: onSurfaceVariant,
        titleTextStyle: TextStyle(
            fontFamily: fontFamily, fontSize: 15, color: onSurface),
        subtitleTextStyle: TextStyle(
            fontFamily: fontFamily, fontSize: 12, color: onSurfaceVariant),
      ),
      dividerTheme:
          DividerThemeData(color: border, thickness: 1, space: 1),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: buttonPadding,
          shape: buttonShape,
          textStyle: buttonTextStyle,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: primary.withValues(alpha: 0.4),
          padding: buttonPadding,
          shape: buttonShape,
          textStyle: buttonTextStyle,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          padding: buttonPadding,
          shape: buttonShape,
          textStyle: buttonTextStyle.copyWith(fontWeight: FontWeight.w600),
        ).copyWith(
          // styleFrom's `side` is fixed across states, which would keep a
          // bright brand border on a disabled button; resolve per state.
          side: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.disabled)
                  ? BorderSide(color: hint.withValues(alpha: 0.4))
                  : BorderSide(color: primary)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: buttonShape,
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // Family comes from ThemeData.fontFamily; only size/weight/colour here.
  static TextTheme _textTheme(
          Color primary, Color secondary, Color tertiary) =>
      TextTheme(
        headlineMedium: TextStyle(
            fontSize: 20, fontWeight: FontWeight.bold, color: primary),
        titleLarge: TextStyle(
            fontSize: 18, fontWeight: FontWeight.bold, color: primary),
        titleMedium: TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold, color: primary),
        bodyLarge: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w500, color: primary),
        bodyMedium: TextStyle(fontSize: 14, color: primary),
        bodySmall: TextStyle(fontSize: 12, color: secondary),
        labelLarge:
            const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        labelSmall: TextStyle(fontSize: 11, color: tertiary),
      );
}
