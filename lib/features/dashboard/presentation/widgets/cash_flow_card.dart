import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../dashboard_format.dart';

/// Cash in vs out for the period: two headline figures + a single proportional
/// in/out bar, then the two main outflow types (expenses, withdrawals).
class CashFlowCard extends StatelessWidget {
  final AppLocalizations l10n;
  final String currency;
  final double cashIn;
  final double cashOut;
  final double expenses;
  final double withdrawals;

  const CashFlowCard({
    super.key,
    required this.l10n,
    required this.currency,
    required this.cashIn,
    required this.cashOut,
    required this.expenses,
    required this.withdrawals,
  });

  @override
  Widget build(BuildContext context) {
    final total = cashIn + cashOut;
    final inFlex = total <= 0 ? 1 : (cashIn / total * 1000).round().clamp(1, 999);
    final outFlex =
        total <= 0 ? 1 : (cashOut / total * 1000).round().clamp(1, 999);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _figure(context, l10n.cashInLabel, cashIn, Colors.green.shade600,
                  Icons.south_west),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _figure(context, l10n.cashOutLabel, cashOut, Colors.red.shade600,
                  Icons.north_east),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: SizedBox(
            height: 9,
            child: Row(
              children: [
                Expanded(flex: inFlex, child: Container(color: Colors.green.shade500)),
                Expanded(flex: outFlex, child: Container(color: Colors.red.shade400)),
              ],
            ),
          ),
        ),
        if (expenses > 0.005 || withdrawals > 0.005) ...[
          const SizedBox(height: 10),
          if (expenses > 0.005) _outRow(context, l10n.expensesLabel, expenses),
          if (withdrawals > 0.005) _outRow(context, l10n.withdrawalsLabel, withdrawals),
        ],
      ],
    );
  }

  Widget _figure(BuildContext context, String label, double value, Color color,
      IconData icon) {
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
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Expanded(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ),
          ]),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(moneyCompact(currency, value),
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          ),
        ],
      ),
    );
  }

  Widget _outRow(BuildContext context, String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          Text(moneyCompact(currency, value),
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
