import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import 'invoice_share_card.dart' show ShareCardShell, ShareCardDivider;

/// One movement on the statement: a date, a label, and a signed amount.
class StatementShareLine {
  final String dateText;
  final String label;
  final double amount; // magnitude
  final bool isCharge; // true = the customer took goods, false = they paid
  final String note;

  const StatementShareLine({
    required this.dateText,
    required this.label,
    required this.amount,
    required this.isCharge,
    this.note = '',
  });
}

/// A shareable customer account statement (Plan 013 #8).
///
/// The text share stays — this is an *additional* format, not a replacement.
/// The two are genuinely different tools: an image survives WhatsApp's
/// formatting and looks like a document the customer can show someone else,
/// while text stays searchable and copyable. Some customers ask for one, some
/// the other, so the page offers both.
///
/// **The row list is capped by the caller.** A statement can run to hundreds of
/// entries; captured at `pixelRatio: 3.0` that becomes a PNG tall enough that
/// some apps refuse to attach it. [omittedCount] renders the honest "…and N
/// more" line, because a silently truncated financial statement is worse than
/// no statement — the customer would count the rows and find money missing.
class CustomerStatementShareCard extends StatelessWidget {
  final AppLocalizations l10n;
  final String currency;
  final String shopName;
  final String customerName;
  final String customerPhone;
  final String dateText;

  final List<StatementShareLine> lines;
  final int omittedCount;

  final double totalCharges;
  final double totalPayments;
  final double balance;

  const CustomerStatementShareCard({
    super.key,
    required this.l10n,
    required this.currency,
    required this.shopName,
    required this.customerName,
    required this.customerPhone,
    required this.dateText,
    required this.lines,
    required this.totalCharges,
    required this.totalPayments,
    required this.balance,
    this.omittedCount = 0,
  });

  String _m(double v) {
    final n = v.abs().toStringAsFixed(2);
    return currency.isEmpty ? n : '$n $currency';
  }

  @override
  Widget build(BuildContext context) {
    final settled = balance.abs() < 0.005;
    final owes = balance > 0;
    final balanceColor = settled
        ? Colors.grey.shade600
        : (owes ? Colors.red.shade600 : Colors.green.shade600);
    final balanceLabel = settled
        ? l10n.balanceSettled
        : (owes ? l10n.balanceOwedLabel : l10n.balanceCreditLabel);

    return ShareCardShell(
      accent: AppTheme.primaryColor,
      children: [
        if (shopName.isNotEmpty)
          Text(shopName,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(l10n.statementCardTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 12),

        _kv(l10n.customerNameLabel, customerName, bold: true),
        if (customerPhone.isNotEmpty)
          _kv(l10n.customerPhoneLabel, customerPhone),
        _kv(l10n.statementDate, dateText),

        const SizedBox(height: 10),
        const ShareCardDivider(),
        const SizedBox(height: 8),

        for (final line in lines)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 74,
                  child: Text(line.dateText,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(line.label, style: const TextStyle(fontSize: 13)),
                      if (line.note.isNotEmpty)
                        Text(line.note,
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey[500])),
                    ],
                  ),
                ),
                Text(
                  '${line.isCharge ? '+' : '-'} ${_m(line.amount)}',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: line.isCharge
                          ? Colors.red.shade600
                          : Colors.green.shade700),
                ),
              ],
            ),
          ),

        if (omittedCount > 0)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(l10n.statementMoreEntries(omittedCount),
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic)),
          ),

        const SizedBox(height: 10),
        const ShareCardDivider(),
        const SizedBox(height: 8),

        _kv(l10n.statementTotalDebts, _m(totalCharges)),
        _kv(l10n.statementTotalPaid, _m(totalPayments)),

        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          decoration: BoxDecoration(
            color: balanceColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(balanceLabel,
                  style: TextStyle(fontSize: 12, color: Colors.grey[700])),
              const SizedBox(height: 4),
              Text(_m(balance),
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: balanceColor)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _kv(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.end,
                style: TextStyle(
                    fontSize: bold ? 15 : 13,
                    fontWeight: bold ? FontWeight.bold : FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
