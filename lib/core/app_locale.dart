import 'package:flutter/widgets.dart';

/// The locale the app runs in.
///
/// Fawateer is Arabic-first and **pins** its locale rather than following the
/// phone: the shop's staff read Arabic whatever language the handset is set to,
/// and a receipt that suddenly prints in English because someone changed a
/// system setting is a support call. English stays a supported locale for
/// development and for a future in-app language switch.
///
/// Named here rather than written inline in `main.dart` because code outside
/// the widget tree needs it too — a background service has no `BuildContext` to
/// ask, and `AppLocalizations.delegate.load(kAppLocale)` is how it still speaks
/// the same language as the UI.
const Locale kAppLocale = Locale('ar');
