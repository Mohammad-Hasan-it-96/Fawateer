import 'package:fpdart/fpdart.dart';

import '../../../../core/database/daos/dashboard_dao.dart';
import '../../../../core/error/failure.dart';
import '../../../billing/domain/entities/sales_filter.dart';
import '../../domain/entities/dashboard_data.dart';
import '../../domain/repositories/dashboard_repository.dart';

class DashboardRepositoryDriftImpl implements DashboardRepository {
  final DashboardDao _dao;
  const DashboardRepositoryDriftImpl(this._dao);

  static String _metricColumn(ProductMetric m) => switch (m) {
        ProductMetric.revenue => 'revenue',
        ProductMetric.quantity => 'qty',
        ProductMetric.profit => 'profit',
      };

  @override
  Stream<void> watchChanges() => _dao.watchChanges();

  @override
  Future<Either<Failure, DashboardData>> load(
    SalesFilter range, {
    required ProductMetric metric,
  }) async {
    try {
      final fromMs = range.from.millisecondsSinceEpoch;
      final toMs = range.to.millisecondsSinceEpoch;

      // Previous equal-length window immediately before this one.
      final length = toMs - fromMs;
      final prevToMs = fromMs - 1;
      final prevFromMs = prevToMs - length;

      // Run every aggregate together.
      final results = await Future.wait([
        _dao.periodTotals(fromMs, toMs), // 0
        _dao.periodTotals(prevFromMs, prevToMs), // 1
        _dao.invoiceStamps(fromMs, toMs), // 2
        _dao.topProducts(fromMs, toMs,
            orderByColumn: _metricColumn(metric)), // 3
        _dao.cashFlow(fromMs, toMs), // 4
        _dao.cashBalance(), // 5
        _dao.outstandingDebts(), // 6
        _dao.inventoryValue(), // 7
        _dao.lowStockProducts(), // 8
        _dao.topDebtors(), // 9
      ]);

      final totals = results[0] as PeriodTotalsRow;
      final prev = results[1] as PeriodTotalsRow;
      final stamps = results[2] as List<InvoiceStampRow>;
      final top = results[3] as List<TopProductRow>;
      final cash = results[4] as CashFlowRow;
      final cashBalance = results[5] as double;
      final debts = results[6] as double;
      final inventory = results[7] as double;
      final lowStock = results[8] as List<NamedQtyRow>;
      final debtors = results[9] as List<NamedQtyRow>;

      return Right(DashboardData(
        revenue: totals.revenue,
        profit: totals.profit,
        invoiceCount: totals.count,
        revenuePrev: prev.revenue,
        profitPrev: prev.profit,
        cashBalance: cashBalance,
        outstandingDebts: debts,
        inventoryValue: inventory,
        salesTrend: _bucketByDay(range.from, range.to, stamps),
        topProducts: top
            .map((r) => TopProduct(
                  name: r.productName,
                  quantity: r.quantity,
                  revenue: r.revenue,
                  profit: r.profit,
                ))
            .toList(),
        cashIn: cash.cashIn,
        cashOut: cash.cashOut,
        expenses: cash.expenses,
        withdrawals: cash.withdrawals,
        lowStock: lowStock
            .map((r) => NamedAmount(name: r.name, amount: r.value))
            .toList(),
        topDebtors: debtors
            .map((r) => NamedAmount(name: r.name, amount: r.value))
            .toList(),
      ));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Bucket invoice stamps into **local** calendar days across [from]..[to].
  /// Day keys are generated with `DateTime(y, m, d+1)` (midnight local, DST-safe
  /// and month-rollover-safe) rather than epoch division.
  static List<SalesBucket> _bucketByDay(
      DateTime from, DateTime to, List<InvoiceStampRow> stamps) {
    final startDay = DateTime(from.year, from.month, from.day);
    final endDay = DateTime(to.year, to.month, to.day);

    final totals = <DateTime, double>{};
    var d = startDay;
    while (!d.isAfter(endDay)) {
      totals[d] = 0;
      d = DateTime(d.year, d.month, d.day + 1);
    }
    for (final s in stamps) {
      final dt = DateTime.fromMillisecondsSinceEpoch(s.createdAt);
      final key = DateTime(dt.year, dt.month, dt.day);
      totals[key] = (totals[key] ?? 0) + s.total;
    }
    final keys = totals.keys.toList()..sort();
    return keys.map((k) => SalesBucket(day: k, total: totals[k]!)).toList();
  }
}
