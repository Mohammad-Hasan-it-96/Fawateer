import '../../../l10n/app_localizations.dart';
import '../domain/entities/cash_transaction_type.dart';
import 'bloc/cashbox_bloc.dart';

/// Localized display name for a cash transaction type.
String cashTransactionTypeText(CashTransactionType type, AppLocalizations l10n) {
  switch (type) {
    case CashTransactionType.openingBalance:
      return l10n.cashTypeOpeningBalance;
    case CashTransactionType.cashSale:
      return l10n.cashTypeCashSale;
    case CashTransactionType.customerDebtPayment:
      return l10n.cashTypeCustomerDebtPayment;
    case CashTransactionType.manualDeposit:
      return l10n.cashTypeManualDeposit;
    case CashTransactionType.expense:
      return l10n.cashTypeExpense;
    case CashTransactionType.personalWithdrawal:
      return l10n.cashTypePersonalWithdrawal;
    case CashTransactionType.purchasePayment:
      return l10n.cashTypePurchasePayment;
    case CashTransactionType.supplierPayment:
      return l10n.cashTypeSupplierPayment;
    case CashTransactionType.manualAdjustment:
      return l10n.cashTypeManualAdjustment;
  }
}

/// Map a [CashboxMessage] to a localized string.
String cashboxMessageText(CashboxMessage m, AppLocalizations l10n) {
  switch (m) {
    case CashboxMessage.transactionAdded:
      return l10n.cashTransactionAdded;
    case CashboxMessage.transactionDeleted:
      return l10n.cashTransactionDeleted;
    case CashboxMessage.deleteNotAllowed:
      return l10n.cashDeleteNotAllowed;
    case CashboxMessage.saveFailed:
      return l10n.cashSaveFailed;
    case CashboxMessage.loadFailed:
      return l10n.cashLoadFailed;
  }
}

/// True for messages shown as an error (red) snackbar.
bool cashboxMessageIsError(CashboxMessage m) =>
    m == CashboxMessage.saveFailed ||
    m == CashboxMessage.loadFailed ||
    m == CashboxMessage.deleteNotAllowed;
