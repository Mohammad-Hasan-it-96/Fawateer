import 'package:equatable/equatable.dart';

/// Which metric ranks the top-products chart.
enum ProductMetric { revenue, quantity, profit }

/// One day (or bucket) on the sales-trend chart.
class SalesBucket extends Equatable {
  final DateTime day; // local day start
  final double total;
  const SalesBucket({required this.day, required this.total});

  @override
  List<Object?> get props => [day, total];
}

/// A ranked product row for the top-products chart.
class TopProduct extends Equatable {
  final String name;
  final double quantity;
  final double revenue;
  final double profit;
  const TopProduct({
    required this.name,
    required this.quantity,
    required this.revenue,
    required this.profit,
  });

  /// The value for the currently-selected metric.
  double valueFor(ProductMetric m) => switch (m) {
        ProductMetric.revenue => revenue,
        ProductMetric.quantity => quantity,
        ProductMetric.profit => profit,
      };

  @override
  List<Object?> get props => [name, quantity, revenue, profit];
}

/// A name + amount row (low-stock quantity, or a debtor's balance).
class NamedAmount extends Equatable {
  final String name;
  final double amount;
  const NamedAmount({required this.name, required this.amount});

  @override
  List<Object?> get props => [name, amount];
}

/// Everything the dashboard renders, computed for one time range in a single
/// composite load. Point-in-time figures (cash balance, debts, inventory value)
/// are all-time snapshots; revenue/profit are for the selected period and carry
/// a previous-period counterpart for the delta arrow.
class DashboardData extends Equatable {
  // Period (flow) metrics + previous equal period for deltas.
  final double revenue;
  final double profit;
  final int invoiceCount;
  final double revenuePrev;
  final double profitPrev;

  // Point-in-time (stock) metrics.
  final double cashBalance;
  final double outstandingDebts;
  final double inventoryValue;

  // Charts / breakdowns.
  final List<SalesBucket> salesTrend;
  final List<TopProduct> topProducts;
  final double cashIn;
  final double cashOut;
  final double expenses;
  final double withdrawals;

  // Mini-lists.
  final List<NamedAmount> lowStock;
  final List<NamedAmount> topDebtors;

  /// Products sold past zero, with their **negative** on-hand (Plan 002 Q6).
  ///
  /// Point-in-time, like `inventoryValue` — it does not move with the range
  /// picker, because "you are three short right now" is not a fact about last
  /// week. `amount` is negative by construction; the UI shows the shortfall.
  final List<NamedAmount> oversold;

  const DashboardData({
    this.revenue = 0,
    this.profit = 0,
    this.invoiceCount = 0,
    this.revenuePrev = 0,
    this.profitPrev = 0,
    this.cashBalance = 0,
    this.outstandingDebts = 0,
    this.inventoryValue = 0,
    this.salesTrend = const [],
    this.topProducts = const [],
    this.cashIn = 0,
    this.cashOut = 0,
    this.expenses = 0,
    this.withdrawals = 0,
    this.lowStock = const [],
    this.topDebtors = const [],
    this.oversold = const [],
  });

  /// Whether anything needs the owner's eye before they read the numbers.
  bool get hasStockConflicts => oversold.isNotEmpty;

  /// Signed percent change vs the previous period (null when there's no
  /// baseline — avoids a meaningless "+∞%").
  double? get revenueDeltaPct => _pct(revenue, revenuePrev);
  double? get profitDeltaPct => _pct(profit, profitPrev);

  static double? _pct(double now, double prev) {
    if (prev.abs() < 0.005) return null;
    return (now - prev) / prev.abs() * 100;
  }

  @override
  List<Object?> get props => [
        revenue,
        profit,
        invoiceCount,
        revenuePrev,
        profitPrev,
        cashBalance,
        outstandingDebts,
        inventoryValue,
        salesTrend,
        topProducts,
        cashIn,
        cashOut,
        expenses,
        withdrawals,
        lowStock,
        topDebtors,
        oversold,
      ];
}
