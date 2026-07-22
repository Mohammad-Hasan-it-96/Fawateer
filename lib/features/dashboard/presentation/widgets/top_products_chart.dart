import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/dashboard_data.dart';
import '../dashboard_format.dart';

/// Ranked horizontal bars for the top products. Hand-drawn proportional bars
/// (no chart lib) so they lay out natively in RTL and stay readable on a phone.
class TopProductsChart extends StatelessWidget {
  final List<TopProduct> products;
  final ProductMetric metric;
  final String currency;
  final String emptyText;

  const TopProductsChart({
    super.key,
    required this.products,
    required this.metric,
    required this.currency,
    required this.emptyText,
  });

  String _value(double v) =>
      metric == ProductMetric.quantity ? qtyCompact(v) : moneyCompact(currency, v);

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return _empty(context);
    }
    final maxV = products.fold<double>(
        0, (m, p) => p.valueFor(metric) > m ? p.valueFor(metric) : m);

    return Column(
      children: [
        for (final p in products)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(p.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w500)),
                    ),
                    const SizedBox(width: 8),
                    Text(_value(p.valueFor(metric)),
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: maxV <= 0
                        ? 0
                        : (p.valueFor(metric) / maxV).clamp(0.0, 1.0),
                    minHeight: 7,
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    valueColor: const AlwaysStoppedAnimation(
                        AppTheme.primaryColor),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _empty(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Center(
          child: Text(emptyText,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 13)),
        ),
      );
}
