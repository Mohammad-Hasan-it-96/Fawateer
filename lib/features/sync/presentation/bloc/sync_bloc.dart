import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../data/sync_scheduler.dart';
import '../../data/sync_state_store.dart';
import '../../domain/entities/join_token.dart';
import '../../domain/entities/sync_outcome.dart';
import '../../domain/entities/sync_session.dart';
import '../../domain/repositories/sync_enrollment_repository.dart';
import '../../domain/sync_error.dart';

part 'sync_event.dart';
part 'sync_state.dart';

/// Drives the multi-device screen (Plan 002). Route-scoped to `/settings/sync`
/// — precedent: `LedgerBloc` and `BackupBloc`. Nothing outside that screen needs
/// enrollment state, and a device that never opens it should not be paying for
/// a listener.
///
/// Follows the app's error rule: every failure is stored as a **typed**
/// [SyncError], never a pre-rendered English string; the page maps it to ARB.
class SyncBloc extends Bloc<SyncEvent, SyncState> {
  final SyncEnrollmentRepository _repository;
  final SyncScheduler _scheduler;
  final SyncStateStore _state;

  SyncBloc({
    required SyncEnrollmentRepository repository,
    required SyncScheduler scheduler,
    required SyncStateStore state,
  })  : _repository = repository,
        _scheduler = scheduler,
        _state = state,
        super(const SyncState()) {
    on<LoadSyncStatus>(_onLoad);
    on<EnableSyncAsOwner>(_onEnableAsOwner);
    on<JoinWithToken>(_onJoin);
    on<MintJoinTokenRequested>(_onMintToken);
    on<SyncNowRequested>(_onSyncNow);
    on<LeaveSyncRequested>(_onLeave);
    on<ClearSyncFeedback>(_onClearFeedback);
    on<DismissJoinToken>(_onDismissToken);
  }

  Future<void> _onLoad(LoadSyncStatus event, Emitter<SyncState> emit) async {
    emit(state.copyWith(loading: true));
    final session = await _repository.currentSession();
    emit(state.copyWith(
      loading: false,
      loaded: true,
      session: session,
      clearSession: session == null,
      lastSyncAt: await _state.lastSyncAt(),
      outcome: _scheduler.lastOutcome.value,
    ));
  }

  Future<void> _onEnableAsOwner(
      EnableSyncAsOwner event, Emitter<SyncState> emit) async {
    emit(state.copyWith(busy: true, clearFeedback: true));
    final result = await _repository.establishAsOwner();
    result.match(
      (failure) => emit(state.copyWith(busy: false, error: _errorOf(failure))),
      (outcome) => emit(state.copyWith(
        busy: false,
        loaded: true,
        session: outcome.session,
        message: SyncMessage.enabled,
      )),
    );
    // A device that has just enrolled has a shop's worth of local rows the
    // server has never seen; there is no reason to make it wait for the timer.
    if (result.isRight()) await _scheduler.start();
  }

  Future<void> _onJoin(JoinWithToken event, Emitter<SyncState> emit) async {
    final token = event.token.trim();
    if (token.isEmpty) {
      emit(state.copyWith(error: SyncError.invalidJoinToken));
      return;
    }
    emit(state.copyWith(busy: true, clearFeedback: true));
    final result = await _repository.joinBusiness(token);
    result.match(
      (failure) => emit(state.copyWith(busy: false, error: _errorOf(failure))),
      (outcome) => emit(state.copyWith(
        busy: false,
        loaded: true,
        session: outcome.session,
        message: SyncMessage.joined,
      )),
    );
    if (result.isRight()) await _scheduler.start();
  }

  Future<void> _onMintToken(
      MintJoinTokenRequested event, Emitter<SyncState> emit) async {
    emit(state.copyWith(busy: true, clearFeedback: true, clearToken: true));
    final result = await _repository.mintJoinToken();
    result.match(
      (failure) => emit(state.copyWith(busy: false, error: _errorOf(failure))),
      (token) => emit(state.copyWith(busy: false, joinToken: token)),
    );
  }

  Future<void> _onSyncNow(
      SyncNowRequested event, Emitter<SyncState> emit) async {
    emit(state.copyWith(busy: true, clearFeedback: true));
    final outcome = await _scheduler.syncNow();
    emit(state.copyWith(
      busy: false,
      outcome: outcome,
      lastSyncAt: await _state.lastSyncAt(),
      // A pass that failed reports its reason; one that succeeded says so even
      // when nothing moved, because "already up to date" is a real answer and
      // silence reads as a broken button.
      error: outcome?.error,
      message: outcome != null && outcome.isSuccess ? SyncMessage.synced : null,
    ));
  }

  Future<void> _onLeave(
      LeaveSyncRequested event, Emitter<SyncState> emit) async {
    emit(state.copyWith(busy: true, clearFeedback: true));
    await _repository.leave();
    emit(const SyncState(loaded: true, message: SyncMessage.left));
  }

  void _onClearFeedback(ClearSyncFeedback event, Emitter<SyncState> emit) =>
      emit(state.copyWith(clearFeedback: true));

  void _onDismissToken(DismissJoinToken event, Emitter<SyncState> emit) =>
      emit(state.copyWith(clearToken: true));

  /// Unwrap the typed sync error a repository put inside a [SyncFailure];
  /// anything else is a transport-shaped failure the taxonomy already names.
  static SyncError _errorOf(Failure failure) {
    if (failure is SyncFailure) return failure.error;
    if (failure is NetworkFailure) return SyncError.offline;
    return SyncError.server;
  }
}
