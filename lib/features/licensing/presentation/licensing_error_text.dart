import '../../../l10n/app_localizations.dart';
import 'bloc/license_bloc.dart';

/// Map a [LicenseError] to a localized, user-facing message. Keeps activation
/// pages free of hard-coded English (mirrors `billingErrorText`).
String licenseErrorText(LicenseError error, AppLocalizations l10n) {
  switch (error) {
    case LicenseError.network:
      return l10n.licenseErrorNetwork;
    case LicenseError.server:
      return l10n.licenseErrorServer;
    case LicenseError.unexpected:
      return l10n.licenseErrorUnexpected;
  }
}
