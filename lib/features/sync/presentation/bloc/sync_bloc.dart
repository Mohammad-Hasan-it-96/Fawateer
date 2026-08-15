import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../data/bootstrap_service.dart';
import '../../data/sync_scheduler.dart';
import '../../data/sync_state_store.dart';
import '../../domain/entities/enrollment_outcome.dart';
import '../../domain/entities/join_invite.dart';
import '../../domain/entities/sync_device.dart';
import '../../domain/entities/sync_device_registry.dart';
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
  final BootstrapService _bootstrap;

  SyncBloc({
    required SyncEnrollmentRepository repository,
    required SyncScheduler scheduler,
    required SyncStateStore state,
    required BootstrapService bootstrap,
  })  : _repository = repository,
        _scheduler = scheduler,
        _state = state,
        _bootstrap = bootstrap,
        super(const SyncState()) {
    on<LoadSyncStatus>(_onLoad);
    on<EnableSyncAsOwner>(_onEnableAsOwner);
    on<JoinWithToken>(_onJoin);
    on<MintJoinTokenRequested>(_onMintToken);
    on<SyncNowRequested>(_onSyncNow);
    on<LoadDevicesRequested>(_onLoadDevices);
    on<RevokeDeviceRequested>(_onRevokeDevice);
    on<RenameDeviceRequested>(_onRenameDevice);
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
    // The registry needs the network; everything above it does not. Emitting
    // the seat first means the screen is usable immediately and an offline
    // owner gets a working page with one section that says it could not load —
    // rather than a spinner that ends in a blank screen.
    if (session?.isOwner ?? false) await _loadDevices(emit);
  }

  Future<void> _onLoadDevices(
          LoadDevicesRequested event, Emitter<SyncState> emit) =>
      _loadDevices(emit);

  /// Read the registry into the current handler's [emit].
  ///
  /// Called inline rather than by dispatching [LoadDevicesRequested] to
  /// ourselves: `add` on a BLoC whose event controller has already closed
  /// throws, and every caller here sits behind a network round trip the
  /// shopkeeper can walk away from mid-flight.
  Future<void> _loadDevices(Emitter<SyncState> emit) async {
    emit(state.copyWith(devicesLoading: true, clearDevicesError: true));
    final result = await _repository.listDevices();
    result.match(
      (failure) => emit(state.copyWith(
          devicesLoading: false, devicesError: _errorOf(failure))),
      (registry) =>
          emit(state.copyWith(devicesLoading: false, registry: registry)),
    );
  }

  Future<void> _onRevokeDevice(
      RevokeDeviceRequested event, Emitter<SyncState> emit) async {
    emit(state.copyWith(revoking: event.seatUuid, clearFeedback: true));
    final result = await _repository.revokeDevice(event.seatUuid);
    await result.match(
      (failure) async => emit(state.copyWith(
          clearRevoking: true, error: _errorOf(failure))),
      (_) async {
        // Drop the row immediately rather than waiting for the re-read: the
        // owner just watched themselves remove it, and a row that lingers for
        // the length of a network round trip reads as the button not working.
        emit(state.copyWith(
          clearRevoking: true,
          registry: state.registry?.copyWith(
            devices:
                state.devices.where((d) => d.uuid != event.seatUuid).toList(),
          ),
          message: SyncMessage.deviceRevoked,
        ));
        // The server is the authority on what a seat freed — the allowance, and
        // whether anything else changed with it.
        await _loadDevices(emit);
      },
    );
  }

  /// Rename a seat, then re-read the registry.
  ///
  /// **The row is NOT updated optimistically**, which is the opposite of the
  /// revoke above, and deliberately so. A revoke has one outcome — the row is
  /// gone — so showing it immediately can only be right or be corrected. A
  /// rename has three: the server trims it, caps it at 40 characters, or stores
  /// NULL for a blank. Painting the typed text and then replacing it with the
  /// server's version a second later shows the owner two different names for
  /// their phone and leaves them unsure which one it now has. So the row waits,
  /// spinning, and shows only what the server confirms.
  Future<void> _onRenameDevice(
      RenameDeviceRequested event, Emitter<SyncState> emit) async {
    emit(state.copyWith(renaming: event.seatUuid, clearFeedback: true));
    final result = await _repository.renameDevice(event.seatUuid, event.name);
    await result.match(
      (failure) async =>
          emit(state.copyWith(clearRenaming: true, error: _errorOf(failure))),
      (_) async {
        emit(state.copyWith(
            clearRenaming: true, message: SyncMessage.deviceRenamed));
        await _loadDevices(emit);
      },
    );
  }

  Future<void> _onEnableAsOwner(
      EnableSyncAsOwner event, Emitter<SyncState> emit) async {
    emit(state.copyWith(busy: true, clearFeedback: true));
    final result = await _repository.establishAsOwner();
    await result.match(
      (failure) async =>
          emit(state.copyWith(busy: false, error: _errorOf(failure))),
      (outcome) async {
        // Cursor-only: a shop's first device is establishing the business, not
        // joining one, so there is no snapshot and nothing to restart for.
        await _bootstrap.adopt(outcome.bootstrap);
        emit(state.copyWith(
          busy: false,
          loaded: true,
          session: outcome.session,
          message: SyncMessage.enabled,
        ));
      },
    );
    // A device that has just enrolled has a shop's worth of local rows the
    // server has never seen; there is no reason to make it wait for the timer.
    if (result.isRight()) {
      await _scheduler.start();
      await _loadDevices(emit);
    }
  }

  Future<void> _onJoin(JoinWithToken event, Emitter<SyncState> emit) async {
    // Whatever arrived — a scanned payload carrying the owner's snapshot hash,
    // or a bare token someone typed in.
    final scanned = JoinInvite.decode(event.token);
    if (scanned.token.isEmpty) {
      emit(state.copyWith(error: SyncError.invalidJoinToken));
      return;
    }
    emit(state.copyWith(busy: true, clearFeedback: true));
    final result = await _repository.joinBusiness(scanned.token);
    await result.match(
      (failure) async =>
          emit(state.copyWith(busy: false, error: _errorOf(failure))),
      (outcome) => _adoptSeed(outcome, scanned.sha256, emit),
    );
  }

  /// Apply the shop the owner left for us, and deal with the two ways it can go
  /// wrong — which are genuinely different situations.
  Future<void> _adoptSeed(
    EnrollmentOutcome outcome,
    String? expectedSha256,
    Emitter<SyncState> emit,
  ) async {
    emit(state.copyWith(step: BootstrapStep.syncing));
    final adopted = await _bootstrap.adopt(
      outcome.bootstrap,
      expectedSha256: expectedSha256,
    );

    await adopted.match(
      (failure) async {
        if (failure is RestoreIncompleteFailure) {
          // The swap began and broke. SQLite is closed, so nothing can be
          // undone from here and no other button on this screen will work —
          // only a restart will, and `<db>.pre-restore` holds the old data.
          emit(state.copyWith(
              busy: false,
              clearStep: true,
              restartRequired: true,
              error: _errorOf(failure)));
          return;
        }
        // The seat is real but the shop never arrived, and the join code was
        // single-use — so this device would sit enrolled, empty, with no way
        // back except a code it can no longer obtain. Hand the seat back
        // instead: the owner mints a fresh code and it is simply retried.
        await _repository.leave();
        emit(const SyncState(loaded: true)
            .copyWith(error: _errorOf(failure)));
      },
      (result) async {
        emit(state.copyWith(
          busy: false,
          loaded: true,
          clearStep: true,
          session: outcome.session,
          message: SyncMessage.joined,
          restartRequired: result == BootstrapResult.restartRequired,
        ));
        // Only when the database survived. After a restore there is no SQLite
        // to sync against, and the scheduler would throw on its first read.
        if (result == BootstrapResult.cursorOnly) await _scheduler.start();
      },
    );
  }

  Future<void> _onMintToken(
      MintJoinTokenRequested event, Emitter<SyncState> emit) async {
    emit(state.copyWith(busy: true, clearFeedback: true, clearToken: true));
    final result = await _bootstrap.prepareInvite(
      // Safe to emit from: the callback only fires while this handler is
      // awaiting, never after it returns.
      onStep: (step) => emit(state.copyWith(step: step)),
    );
    result.match(
      (failure) => emit(state.copyWith(
          busy: false, clearStep: true, error: _errorOf(failure))),
      (invite) =>
          emit(state.copyWith(busy: false, clearStep: true, invite: invite)),
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
    // The scheduler has already dropped the dead credential; without this the
    // screen would keep offering "Sync now" on a seat that no longer exists,
    // and the shopkeeper would tap it repeatedly to the same red message. The
    // page flips to the not-enrolled pitch, which is both true and the way back
    // in — the owner mints a fresh code.
    if (outcome?.error == SyncError.deviceRevoked) {
      emit(const SyncState(loaded: true, error: SyncError.deviceRevoked));
    }
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
