// Tests for the analytics dashboard (Plan 008): the pure delta-percent logic on
// DashboardData, and the DashboardBloc's load / metric-change / live-refresh
// behavior against a fake repository (no Drift / native SQLite).
import 'dart:async';

import 'package:billing_app/core/error/failure.dart';
import 'package:billing_app/features/billing/domain/entities/sales_filter.dart';
import 'package:billing_app/features/dashboard/domain/entities/dashboard_data.dart';
import 'package:billing_app/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:billing_app/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeDashboardRepository implements DashboardRepository {
  DashboardData data;
  final _changes = StreamController<void>.broadcast();

  ProductMetric? lastMetric;
  SalesFilter? lastFilter;
  int loadCount = 0;

  _FakeDashboardRepository(this.data);

  @override
  Future<Either<Failure, DashboardData>> load(SalesFilter range,
      {required ProductMetric metric}) async {
    loadCount++;
    lastMetric = metric;
    lastFilter = range;
    return Right(data);
  }

  List<TopProduct> breakdown = const [];
  String? lastFieldId;

  @override
  Future<Either<Failure, List<TopProduct>>> salesByAttribute(
      SalesFilter range, String definitionId,
      {required ProductMetric metric}) async {
    lastFieldId = definitionId;
    lastMetric = metric;
    return Right(breakdown);
  }

  @override
  Stream<void> watchChanges() => _changes.stream;

  void tick() => _changes.add(null);
  Future<void> dispose() => _changes.close();
}

void main() {
  group('DashboardData', () {
    test('delta percent: up, down, and null when there is no baseline', () {
      expect(
          const DashboardData(revenue: 150, revenuePrev: 100).revenueDeltaPct,
          50);
      expect(
          const DashboardData(revenue: 80, revenuePrev: 100).revenueDeltaPct,
          -20);
      // No previous data → no meaningful percentage (avoids +∞%).
      expect(const DashboardData(revenue: 150, revenuePrev: 0).revenueDeltaPct,
          isNull);
      expect(const DashboardData(profit: 60, profitPrev: 40).profitDeltaPct,
          closeTo(50, 0.001));
    });
  });

  group('DashboardBloc', () {
    test('LoadDashboard emits loaded with the repository data', () async {
      final repo =
          _FakeDashboardRepository(const DashboardData(revenue: 100, profit: 40));
      final bloc = DashboardBloc(repository: repo);

      bloc.add(const LoadDashboard());
      final loaded =
          await bloc.stream.firstWhere((s) => s.status == DashboardStatus.loaded);

      expect(loaded.data.revenue, 100);
      expect(repo.lastMetric, ProductMetric.revenue);

      await bloc.close();
      await repo.dispose();
    });

    test('metric change re-queries with the new metric', () async {
      final repo = _FakeDashboardRepository(const DashboardData());
      final bloc = DashboardBloc(repository: repo);

      bloc.add(const LoadDashboard());
      await bloc.stream.firstWhere((s) => s.status == DashboardStatus.loaded);

      bloc.add(const DashboardMetricChanged(ProductMetric.profit));
      final s = await bloc.stream
          .firstWhere((s) => s.metric == ProductMetric.profit);

      expect(s.metric, ProductMetric.profit);
      expect(repo.lastMetric, ProductMetric.profit);

      await bloc.close();
      await repo.dispose();
    });

    test('selecting a report field loads its breakdown; null turns it off',
        () async {
      final repo = _FakeDashboardRepository(const DashboardData())
        ..breakdown = const [
          TopProduct(name: 'أسود', quantity: 3, revenue: 300, profit: 90),
          TopProduct(name: 'أبيض', quantity: 1, revenue: 100, profit: 30),
        ];
      final bloc = DashboardBloc(repository: repo);
      bloc.add(const LoadDashboard());
      await bloc.stream.firstWhere((s) => s.status == DashboardStatus.loaded);

      bloc.add(const SelectReportField('color'));
      // Wait for the breakdown to actually load (the handler emits the selection
      // first, then _load emits again with the fetched rows).
      final s = await bloc.stream.firstWhere(
          (s) => s.selectedFieldId == 'color' && s.attributeBreakdown.isNotEmpty);
      expect(repo.lastFieldId, 'color');
      expect(s.attributeBreakdown.length, 2);
      expect(s.attributeBreakdown.first.name, 'أسود');

      // Turning it off clears the selection and the breakdown.
      bloc.add(const SelectReportField(null));
      final off = await bloc.stream.firstWhere(
          (s) => s.selectedFieldId == null && s.attributeBreakdown.isEmpty);
      expect(off.attributeBreakdown, isEmpty);

      await bloc.close();
      await repo.dispose();
    });

    test('a data-change tick reloads the dashboard live', () async {
      final repo = _FakeDashboardRepository(const DashboardData());
      final bloc = DashboardBloc(repository: repo);

      bloc.add(const LoadDashboard());
      await bloc.stream.firstWhere((s) => s.status == DashboardStatus.loaded);
      final before = repo.loadCount;

      repo.tick();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(repo.loadCount, greaterThan(before));

      await bloc.close();
      await repo.dispose();
    });
  });
}
