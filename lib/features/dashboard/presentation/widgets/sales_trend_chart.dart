import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
// intl also exports a `TextDirection` that shadows dart:ui's — hide it so
// `TextDirection.ltr` (used for the forced-LTR chart box) resolves correctly.
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/dashboard_data.dart';

/// Daily sales as a bar chart. Rendered in a forced-LTR box so the time axis is
/// stable (oldest → newest, left → right) regardless of the app's RTL locale —
/// same approach used for the POS exchange-rate chip.
class SalesTrendChart extends StatelessWidget {
  final List<SalesBucket> buckets;
  final String locale;
  const SalesTrendChart({super.key, required this.buckets, required this.locale});

  @override
  Widget build(BuildContext context) {
    if (buckets.isEmpty) {
      return const SizedBox(height: 160);
    }
    final maxY = buckets.fold<double>(0, (m, b) => b.total > m ? b.total : m);
    // A little headroom above the tallest bar; guard the all-zero case.
    final top = maxY <= 0 ? 1.0 : maxY * 1.2;

    // With many days, label only a few ticks to avoid overlap.
    final n = buckets.length;
    final labelEvery = n <= 8 ? 1 : (n / 6).ceil();
    final df = DateFormat.Md(locale);

    return SizedBox(
      height: 170,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: BarChart(
          BarChartData(
            maxY: top,
            minY: 0,
            alignment: BarChartAlignment.spaceBetween,
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: top / 3,
              getDrawingHorizontalLine: (_) =>
                  FlLine(color: Colors.grey.shade200, strokeWidth: 1),
            ),
            titlesData: FlTitlesData(
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 22,
                  getTitlesWidget: (value, meta) {
                    final i = value.toInt();
                    if (i < 0 || i >= n || i % labelEvery != 0) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(df.format(buckets[i].day),
                          style: TextStyle(
                              fontSize: 9, color: Colors.grey[600])),
                    );
                  },
                ),
              ),
            ),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => Colors.black87,
                getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                  NumberFormat('#,##0', 'en').format(rod.toY.round()),
                  const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            barGroups: [
              for (var i = 0; i < n; i++)
                BarChartGroupData(x: i, barRods: [
                  BarChartRodData(
                    toY: buckets[i].total,
                    color: AppTheme.primaryColor,
                    width: n > 20 ? 5 : 12,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(3)),
                  ),
                ]),
            ],
          ),
        ),
      ),
    );
  }
}
