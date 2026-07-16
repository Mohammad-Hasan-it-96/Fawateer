import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../billing/domain/entities/sales_filter.dart';
import '../entities/dashboard_data.dart';

abstract class DashboardRepository {
  /// Compose the whole dashboard for [range] (its from/to bounds) with the
  /// top-products chart ranked by [metric]. Runs all aggregates together.
  Future<Either<Failure, DashboardData>> load(
    SalesFilter range, {
    required ProductMetric metric,
  });

  /// Emits whenever underlying data changes (sale, cash move, debt, stock) so
  /// the dashboard can reload live.
  Stream<void> watchChanges();
}
