import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import 'invoice_share_card.dart' show ShareCardShell, ShareCardDivider;

/// A shareable sales-summary card for the current audit filter: invoice count,
/// total, cash / credit split, average, and estimated profit.
class SalesSummaryShareCard extends StatelessWidget {
  final AppLocalizations l10n;
  final String currency;
  final String shopName;
  final String periodText;

  final int count;
  final double total;
  final double cashTotal;
  final double creditTotal;
  final double average;
  final double profit;

  const SalesSummaryShareCard({
    super.key,
    required this.l10n,
    required this.currency,
    required this.shopName,
    required this.periodText,
    required this.count,
    required this.total,
    required this.cashTotal,
    required this.creditTotal,
    required this.average,
    required this.profit,
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
          child: Text(l10n.salesSummaryTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600)),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text('${l10n.reportPeriodLabel}: $periodText',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        ),
        const SizedBox(height: 14),

        // Hero: total + invoice count.
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.summaryTotal,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(_m(total),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('$count',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                  Text(l10n.summaryInvoices,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 11)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        _kv(l10n.summaryCash, _m(cashTotal), color: Colors.green.shade700),
        _kv(l10n.summaryCredit, _m(creditTotal), color: Colors.orange.shade800),
        _kv(l10n.summaryAverage, _m(average)),
        const SizedBox(height: 8),
        const ShareCardDivider(),
        const SizedBox(height: 8),
        _kv(l10n.estimatedProfit, _m(profit),
            bold: true,
            color: profit >= 0 ? Colors.green.shade700 : Colors.red.shade600),
      ],
    );
  }

  Widget _kv(String label, String value, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: bold ? 14 : 13, color: Colors.grey[700])),
          Text(value,
              style: TextStyle(
                  fontSize: bold ? 16 : 13,
                  fontWeight: bold ? FontWeight.bold : FontWeight.w600,
                  color: color ?? Colors.grey[800])),
        ],
      ),
    );
  }
}
