import '../../../l10n/app_localizations.dart';
import 'bloc/billing_bloc.dart';

/// Map a [BillingError] to a localized, user-facing message. Shared by the POS
/// and checkout pages so error wording stays consistent and translated.
String billingErrorText(
    BillingError error, String? barcode, AppLocalizations l10n) {
  switch (error) {
    case BillingError.productNotFound:
      return l10n.productNotFound(barcode ?? '');
    case BillingError.saveFailed:
      return l10n.saleSaveFailed;
    case BillingError.printerUnavailable:
      return l10n.printerUnavailable;
    case BillingError.printFailed:
      return l10n.printFailed;
    case BillingError.emptyCart:
      return l10n.cartEmptyError;
  }
}
