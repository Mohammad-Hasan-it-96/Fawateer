import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../billing/domain/entities/sales_filter.dart';
import '../../domain/entities/dashboard_data.dart';
import '../../domain/repositories/dashboard_repository.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

/// Drives the analytics dashboard (Plan 008). Loads a composite [DashboardData]
/// for the current range + product metric, and reloads live off the
/// repository's change ticker (sale / cash / debt / stock). Route-scoped to the
/// Reports tab.
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final DashboardRepository _repo;
  StreamSubscription<void>? _changes;

  DashboardBloc({required DashboardRepository repository})
      : _repo = repository,
        super(DashboardState(
          filter: SalesFilter.initial().withPreset(DatePreset.last7Days),
        )) {
    on<LoadDashboard>((e, emit) => _load(emit, showSpinner: true));
    on<DashboardRangeChanged>((e, emit) async {
      emit(state.copyWith(filter: e.filter));
      await _load(emit, showSpinner: true);
    });
    on<DashboardMetricChanged>((e, emit) async {
      emit(state.copyWith(metric: e.metric));
      await _load(emit);
    });
    on<_DashboardDataChanged>((e, emit) => _load(emit));

    // Reload live when underlying tables change.
    _changes = _repo.watchChanges().listen((_) {
      if (!isClosed) add(const _DashboardDataChanged());
    });
  }

  Future<void> _load(Emitter<DashboardState> emit,
      {bool showSpinner = false}) async {
    // Keep the previous data visible; only show the full spinner on first load.
    if (showSpinner && state.status == DashboardStatus.initial) {
      emit(state.copyWith(status: DashboardStatus.loading, clearError: true));
    }
    final result = await _repo.load(state.filter, metric: state.metric);
    result.match(
      (failure) =>
          emit(state.copyWith(status: DashboardStatus.error, error: failure)),
      (data) => emit(state.copyWith(
          status: DashboardStatus.loaded, data: data, clearError: true)),
    );
  }

  @override
  Future<void> close() {
    _changes?.cancel();
    return super.close();
  }
}
