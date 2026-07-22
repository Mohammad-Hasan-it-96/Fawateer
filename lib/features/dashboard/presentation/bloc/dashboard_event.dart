part of 'dashboard_bloc.dart';

sealed class DashboardEvent extends Equatable {
  const DashboardEvent();
  @override
  List<Object?> get props => [];
}

/// First load (dispatched when the dashboard mounts).
class LoadDashboard extends DashboardEvent {
  const LoadDashboard();
}

/// The time-range filter changed.
class DashboardRangeChanged extends DashboardEvent {
  final SalesFilter filter;
  const DashboardRangeChanged(this.filter);
  @override
  List<Object?> get props => [filter];
}

/// The top-products metric toggle changed.
class DashboardMetricChanged extends DashboardEvent {
  final ProductMetric metric;
  const DashboardMetricChanged(this.metric);
  @override
  List<Object?> get props => [metric];
}

/// The "Sales by field" report field changed (Plan 010). Null turns it off.
class SelectReportField extends DashboardEvent {
  final String? definitionId;
  const SelectReportField(this.definitionId);
  @override
  List<Object?> get props => [definitionId];
}

/// Internal: underlying data changed (a sale / cash move / debt / stock edit) —
/// reload keeping the current filter + metric.
class _DashboardDataChanged extends DashboardEvent {
  const _DashboardDataChanged();
}
