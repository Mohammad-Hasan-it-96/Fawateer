import 'package:flutter/material.dart';

import '../../../../core/utils/money_display.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../product/domain/entities/product.dart';

/// "Which one?" — asked when a scanned barcode matches more than one product
/// (Plan 015 Case A).
///
/// The shop sells the same packet at two prices from two piles on the shelf,
/// and the factory gave both the same code. Guessing would silently ring the
/// wrong price, and the till would only disagree with the shelf at closing
/// time — so the cashier is asked, every time, for that one code.
///
/// **Price is the largest thing on the row.** It is the only reason these two
/// products exist separately, so it is what the cashier is actually choosing
/// between; the name is usually identical on both. Stock is shown underneath
/// because "which pile is this from" and "which pile has any left" are the same
/// question at the counter.
///
/// Returns the chosen product, or null if dismissed. Dismissal is a real answer
/// — a cashier who scanned the wrong shelf label needs a way out that does not
/// add a line.
Future<Product?> showBarcodeChoiceSheet(
  BuildContext context,
  List<Product> choices,
) =>
    showModalBottomSheet<Product>(
      context: context,
      // Not dismissible by dragging alone: a sheet that vanishes mid-reach on a
      // busy counter looks like the scan was lost.
      isScrollControlled: true,
      builder: (_) => _BarcodeChoiceSheet(choices: choices),
    );

class _BarcodeChoiceSheet extends StatelessWidget {
  final List<Product> choices;
  const _BarcodeChoiceSheet({required this.choices});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final currency = currencyOf(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Text(l10n.barcodeChoiceTitle,
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(l10n.barcodeChoiceHint,
                style: TextStyle(
                    fontSize: 12.5, color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 14),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: choices.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _choiceTile(context, l10n, choices[i],
                    currency: currency),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
          ],
        ),
      ),
    );
  }

  Widget _choiceTile(
    BuildContext context,
    AppLocalizations l10n,
    Product product, {
    required String currency,
  }) {
    final theme = Theme.of(context);
    // A USD-priced variant prints its own symbol, never the shop's — the same
    // rule the rest of the app follows.
    final price = product.priceCurrency.label(product.price, currency);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.pop(context, product),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    product.isOutOfStock
                        ? l10n.outOfStockBadge
                        : l10n.stockCountLabel(
                            product.quantity.toStringAsFixed(0)),
                    style: TextStyle(
                      fontSize: 11.5,
                      color: product.isOutOfStock
                          ? theme.colorScheme.error
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(price,
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary)),
          ],
        ),
      ),
    );
  }
}
