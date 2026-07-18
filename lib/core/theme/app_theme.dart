import 'package:flutter/material.dart';

import 'app_tokens.dart';

/// The app's single source of colour, shape and typography.
///
/// Only [lightTheme] exists. Dark mode is deliberately **not** shipped yet:
/// ~370 colour literals still live inside the page widgets, so adding a
/// `darkTheme` today would restyle the chrome (app bar, cards, inputs) while
/// most page bodies stayed light — worse than having no dark mode at all. The
/// colours here are named rather than inlined so pages can migrate onto them
/// one at a time, and a dark theme can then be added without a second palette
/// rewrite. See `AppTokens` for the shape/spacing scale.
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
  static const Color secondaryColor = Color(0xFF03DAC6);
  static const Color errorColor = Color(0xFFB00020);

  /// Semantic status colours. Named here because pages currently reach for
  /// `Colors.green`/`Colors.orange` ad hoc, which is what makes them
  /// theme-resistant; prefer these so a later dark theme has one place to swap.
  static const Color successColor = Color(0xFF2E7D32);
  static const Color warningColor = Color(0xFFE65100);

  // ── Surfaces ──────────────────────────────────────────────────────────
  static const Color backgroundColor = Color(0xFFF2F2F7);
  static const Color surfaceColor = Colors.white;
  static const Color borderColor = Color(0xFFE3E3EA);

  // ── Text ramp ─────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1C1B1F);
  static const Color textSecondary = Color(0xFF5F5D67);
  static const Color textTertiary = Color(0xFF8E8C96);

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryColor,
      secondary: secondaryColor,
      surface: surfaceColor,
      error: errorColor,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: fontFamily,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: colorScheme,
      textTheme: _textTheme,
      appBarTheme: _appBarTheme,
      cardTheme: _cardTheme,
      inputDecorationTheme: _inputDecorationTheme,
      // Sheets must render on an opaque surface — a transparent default makes
      // any sheet that doesn't set its own background render over the scrim
      // and look hidden/see-through. Individual sheets may still override.
      bottomSheetTheme: _bottomSheetTheme,
      dialogTheme: _dialogTheme,
      snackBarTheme: _snackBarTheme,
      listTileTheme: _listTileTheme,
      dividerTheme: _dividerTheme,
      filledButtonTheme: _filledButtonTheme,
      elevatedButtonTheme: _elevatedButtonTheme,
      outlinedButtonTheme: _outlinedButtonTheme,
      textButtonTheme: _textButtonTheme,
    );
  }

  // ── Typography ────────────────────────────────────────────────────────
  // Family comes from ThemeData.fontFamily; only size/weight/colour here.
  static const TextTheme _textTheme = TextTheme(
    headlineMedium: TextStyle(
        fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary),
    titleLarge: TextStyle(
        fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
    titleMedium: TextStyle(
        fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
    bodyLarge: TextStyle(
        fontSize: 16, fontWeight: FontWeight.w500, color: textPrimary),
    bodyMedium: TextStyle(fontSize: 14, color: textPrimary),
    bodySmall: TextStyle(fontSize: 12, color: textSecondary),
    labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    labelSmall: TextStyle(fontSize: 11, color: textTertiary),
  );

  // ── Chrome ────────────────────────────────────────────────────────────
  static const AppBarTheme _appBarTheme = AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    centerTitle: true,
    // M3 tints the bar as content scrolls under it; against a transparent
    // background that reads as a colour glitch rather than elevation.
    surfaceTintColor: Colors.transparent,
    titleTextStyle: TextStyle(
      fontFamily: fontFamily,
      color: textPrimary,
      fontWeight: FontWeight.bold,
      fontSize: 18,
    ),
    iconTheme: IconThemeData(color: textPrimary),
  );

  static final CardThemeData _cardTheme = CardThemeData(
    elevation: 4,
    shadowColor: Colors.black.withValues(alpha: 0.1),
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusCard)),
    color: surfaceColor,
  );

  static final InputDecorationTheme _inputDecorationTheme =
      InputDecorationTheme(
    filled: true,
    fillColor: surfaceColor,
    hintStyle: const TextStyle(
        color: textTertiary, fontWeight: FontWeight.normal, fontSize: 14),
    contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: _inputBorder(borderColor),
    enabledBorder: _inputBorder(borderColor),
    focusedBorder: _inputBorder(primaryColor, width: 2),
    errorBorder: _inputBorder(errorColor, width: 2),
    focusedErrorBorder: _inputBorder(errorColor, width: 2),
  );

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusField),
        borderSide: BorderSide(color: color, width: width),
      );

  static const BottomSheetThemeData _bottomSheetTheme = BottomSheetThemeData(
    backgroundColor: surfaceColor,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius:
          BorderRadius.vertical(top: Radius.circular(AppTokens.radiusSheet)),
    ),
  );

  static final DialogThemeData _dialogTheme = DialogThemeData(
    backgroundColor: surfaceColor,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusSheet)),
    titleTextStyle: const TextStyle(
      fontFamily: fontFamily,
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: textPrimary,
    ),
    contentTextStyle: const TextStyle(
        fontFamily: fontFamily, fontSize: 14, color: textSecondary),
  );

  static final SnackBarThemeData _snackBarTheme = SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusField)),
    contentTextStyle:
        const TextStyle(fontFamily: fontFamily, fontSize: 14),
  );

  static const ListTileThemeData _listTileTheme = ListTileThemeData(
    iconColor: textSecondary,
    titleTextStyle: TextStyle(
        fontFamily: fontFamily, fontSize: 15, color: textPrimary),
    subtitleTextStyle: TextStyle(
        fontFamily: fontFamily, fontSize: 12, color: textSecondary),
  );

  static const DividerThemeData _dividerTheme =
      DividerThemeData(color: borderColor, thickness: 1, space: 1);

  // ── Buttons ───────────────────────────────────────────────────────────
  // One shape and one padding across all four roles, so a page can swap
  // FilledButton→OutlinedButton without the layout shifting.
  //
  // These are built with `styleFrom` rather than by `copyWith`-ing a shared
  // ButtonStyle: `WidgetStatePropertyAll(primaryColor)` would paint the brand
  // colour in *every* state, so a disabled button would still look tappable.
  // `styleFrom` leaves the disabled state unset, which lets M3's greyed-out
  // defaults through — load-bearing on the POS screen, where "review order" is
  // disabled until the cart has items.
  static const EdgeInsets _buttonPadding =
      EdgeInsets.symmetric(vertical: 16, horizontal: 24);

  static final RoundedRectangleBorder _buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppTokens.radiusButton));

  static const TextStyle _buttonTextStyle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );

  static final FilledButtonThemeData _filledButtonTheme =
      FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      padding: _buttonPadding,
      shape: _buttonShape,
      textStyle: _buttonTextStyle,
    ),
  );

  static final ElevatedButtonThemeData _elevatedButtonTheme =
      ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 4,
      shadowColor: primaryColor.withValues(alpha: 0.4),
      padding: _buttonPadding,
      shape: _buttonShape,
      textStyle: _buttonTextStyle,
    ),
  );

  static final OutlinedButtonThemeData _outlinedButtonTheme =
      OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: primaryColor,
      padding: _buttonPadding,
      shape: _buttonShape,
      textStyle: _buttonTextStyle.copyWith(fontWeight: FontWeight.w600),
    ).copyWith(
      // styleFrom's `side` is fixed across states, which would keep a bright
      // brand border on a disabled button; resolve it per state instead.
      side: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.disabled)
              ? BorderSide(color: textTertiary.withValues(alpha: 0.4))
              : const BorderSide(color: primaryColor)),
    ),
  );

  static final TextButtonThemeData _textButtonTheme = TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: primaryColor,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusButton)),
      textStyle: const TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
