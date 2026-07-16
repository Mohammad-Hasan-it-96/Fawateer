part of 'dashboard_bloc.dart';

enum DashboardStatus { initial, loading, loaded, error }

class DashboardState extends Equatable {
  final DashboardStatus status;
  final DashboardData data;
  final SalesFilter filter;
  final ProductMetric metric;

  /// Typed failure (mapped to an ARB string by the page — no English here).
  final Failure? error;

  const DashboardState({
    this.status = DashboardStatus.initial,
    this.data = const DashboardData(),
    required this.filter,
    this.metric = ProductMetric.revenue,
    this.error,
  });

  DashboardState copyWith({
    DashboardStatus? status,
    DashboardData? data,
    SalesFilter? filter,
    ProductMetric? metric,
    Failure? error,
    bool clearError = false,
  }) {
    return DashboardState(
      status: status ?? this.status,
      data: data ?? this.data,
      filter: filter ?? this.filter,
      metric: metric ?? this.metric,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [status, data, filter, metric, error];
}
