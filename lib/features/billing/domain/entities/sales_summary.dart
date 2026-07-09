import 'package:equatable/equatable.dart';

/// Aggregate totals for the currently-filtered set of invoices, shown in the
/// audit-center summary cards. Computed by a single SQL aggregate query over the
/// same filter as the list, so it always matches what's on screen.
class SalesSummary extends Equatable {
  /// Number of invoices in the filtered set.
  final int count;

  /// Sum of every invoice total in the set.
  final double total;

  /// Portion of [total] from cash sales.
  final double cashTotal;

  /// Portion of [total] from credit sales.
  final double creditTotal;

  const SalesSummary({
    this.count = 0,
    this.total = 0,
    this.cashTotal = 0,
    this.creditTotal = 0,
  });

  /// Average invoice value (0 when there are no invoices — never divides by 0).
  double get average => count == 0 ? 0 : total / count;

  @override
  List<Object?> get props => [count, total, cashTotal, creditTotal];
}
