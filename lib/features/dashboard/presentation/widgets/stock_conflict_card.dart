import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/dashboard_data.dart';
import '../dashboard_format.dart';

/// Products the shop has sold past zero (Plan 002 Q6).
///
/// **This is the flag the sync design promised, not an error report.** Given
/// two tills selling the same item at once, a POS can either lock the sale on a
/// network round trip or let both through and disagree afterwards; Fawateer
/// chose the second — a till must never refuse a customer because the other
/// phone is out of signal. The cost of that choice is a count that can go
/// negative, and the deal was that it would be *surfaced* rather than hidden.
///
/// So the copy has one job beyond listing the products: to say that **nothing
/// was lost**. An owner seeing "-3" assumes a sale went missing, which is the
/// exact opposite of what happened — the movement log recorded both sales,
/// which is why it can tell them at all. What is wrong is the shelf count, and
/// the fix is a stock take, in the world, not in the app. There is deliberately
/// no "resolve" button: tapping something to make the number go away would
/// falsify a count nobody has actually checked.
///
/// Rendered only when it has something to say. A section that sits there
/// permanently reading "no problems" is a section the owner stops seeing, which
/// costs it exactly the attention it exists to get.
class StockConflictCard extends StatelessWidget {
  const StockConflictCard({super.key, required this.items});

  final List<NamedAmount> items;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final tone = theme.colorScheme.error;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        // Tinted rather than a plain surface: it has to read as different from
        // the metric cards below it at a glance, without shouting.
        color: tone.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tone.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.report_problem_outlined, size: 20, color: tone),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.stockConflictTitle,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(color: tone, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(l10n.stockConflictBody, style: theme.textTheme.bodySmall),
          const SizedBox(height: 10),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Expanded(
                      child: Text(item.name,
                          maxLines: 1, overflow: TextOverflow.ellipsis)),
                  Text(
                    // The stored figure is negative; the shopkeeper is told how
                    // many they are *short*, which is the number they will count
                    // against on the shelf.
                    l10n.stockConflictShort(qtyCompact(item.amount.abs())),
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: tone, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
