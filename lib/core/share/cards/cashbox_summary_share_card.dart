import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import 'invoice_share_card.dart' show ShareCardShell, ShareCardDivider;

/// One line in the cashbox breakdown: a localized type label, its total
/// magnitude, and whether it was an inflow (green +) or outflow (red −).
class CashboxBreakdownRow {
  final String label;
  final double amount; // magnitude (already summed for the type)
  final bool isInflow;
  const CashboxBreakdownRow({
    required this.label,
    required this.amount,
    required this.isInflow,
  });
}

/// A shareable "daily cashbox summary" card: opening/closing balance, total in
/// and out, and a per-type breakdown for the day.
class CashboxSummaryShareCard extends StatelessWidget {
  final AppLocalizations l10n;
  final String currency;
  final String shopName;
  final String dateText;

  final double opening;
  final double closing;
  final double totalIn;
  final double totalOut;
  final List<CashboxBreakdownRow> breakdown;

  const CashboxSummaryShareCard({
    super.key,
    required this.l10n,
    required this.currency,
    required this.shopName,
    required this.dateText,
    required this.opening,
    required this.closing,
    required this.totalIn,
    required this.totalOut,
    required this.breakdown,
  });

  String _m(double v) => '$currency${v.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
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
          child: Text(l10n.cashboxDailySummaryTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600)),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(dateText,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        ),
        const SizedBox(height: 14),

        // In / out headline pair.
        Row(
          children: [
            Expanded(
              child: _statTile(l10n.todayCashIn, _m(totalIn),
                  Colors.green.shade600, Icons.south_west),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statTile(l10n.todayCashOut, _m(totalOut),
                  Colors.red.shade600, Icons.north_east),
            ),
          ],
        ),
        const SizedBox(height: 12),

        _kv(l10n.openingBalance, _m(opening)),
        _kv(l10n.closingBalance, _m(closing), bold: true),

        if (breakdown.isNotEmpty) ...[
          const SizedBox(height: 10),
          const ShareCardDivider(),
          const SizedBox(height: 8),
          for (final row in breakdown)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(row.label,
                      style: const TextStyle(fontSize: 13)),
                  Text(
                    '${row.isInflow ? '+' : '-'} ${_m(row.amount)}',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: row.isInflow
                            ? Colors.green.shade700
                            : Colors.red.shade600),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }

  Widget _statTile(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Text(label,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600])),
            ),
          ]),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _kv(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(fontSize: 13, color: Colors.grey[700])),
          Text(value,
              style: TextStyle(
                  fontSize: bold ? 15 : 13,
                  fontWeight: bold ? FontWeight.bold : FontWeight.w600)),
        ],
      ),
    );
  }
}
