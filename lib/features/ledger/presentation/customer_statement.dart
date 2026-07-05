import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/entities/customer.dart';
import '../domain/entities/ledger_entry.dart';

/// Build a plain-text account statement for a customer, ready to share (e.g.
/// via WhatsApp). Arabic-first, mirrors the reference Accounts-Ledger app:
/// header, chronological entries (oldest first), then debit/credit totals and
/// the final balance.
String buildCustomerStatement({
  required AppLocalizations l10n,
  required String shopName,
  required Customer customer,
  required List<LedgerEntry> entries,
  required double balance,
  required String currency,
}) {
  final df = DateFormat('yyyy/MM/dd', 'ar');
  String money(double v) {
    final n = v.abs().toStringAsFixed(2);
    return currency.isEmpty ? n : '$n $currency';
  }

  final b = StringBuffer();
  b.writeln(l10n.statementHeader(shopName.isEmpty ? '—' : shopName));
  b.writeln('${l10n.customerNameLabel}: ${customer.name}');
  if (customer.phone.isNotEmpty) {
    b.writeln('${l10n.customerPhoneLabel}: ${customer.phone}');
  }
  b.writeln('${l10n.statementDate}: ${df.format(DateTime.now())}');
  b.writeln('--------------------------------');

  // Oldest-first for a readable running statement.
  final sorted = [...entries]
    ..sort((a, c) => a.createdAt.compareTo(c.createdAt));
  double charges = 0;
  double payments = 0;
  for (final e in sorted) {
    final isCharge = e.type == LedgerEntryType.charge;
    if (isCharge) {
      charges += e.amount;
    } else {
      payments += e.amount;
    }
    final label = isCharge ? l10n.entryDebt : l10n.entryPayment;
    final sign = isCharge ? '+' : '-';
    final noteSuffix = e.note.isEmpty ? '' : '  (${e.note})';
    b.writeln('${df.format(e.createdAt)}  $label  $sign${money(e.amount)}$noteSuffix');
  }

  b.writeln('--------------------------------');
  b.writeln('${l10n.statementTotalDebts}: ${money(charges)}');
  b.writeln('${l10n.statementTotalPaid}: ${money(payments)}');

  final settled = balance.abs() < 0.005;
  final balLabel = settled
      ? l10n.balanceSettled
      : (balance > 0 ? l10n.balanceOwedLabel : l10n.balanceCreditLabel);
  b.writeln('${l10n.statementBalance}: ${money(balance)} ($balLabel)');
  return b.toString();
}
