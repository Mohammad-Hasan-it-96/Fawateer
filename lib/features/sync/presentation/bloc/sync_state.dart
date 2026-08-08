part of 'sync_bloc.dart';

/// One-shot successes. Typed, like the errors — the page owns the wording.
enum SyncMessage { enabled, joined, left, synced, deviceRevoked }

class SyncState extends Equatable {
  /// True during the initial read, so the page can hold a spinner instead of
  /// flashing the "not enrolled" pitch at a device that *is* enrolled.
  final bool loading;

  /// True once the first read has completed. Distinct from `session != null`:
  /// "we have not looked yet" and "we looked, and there is no seat" are
  /// different screens.
  final bool loaded;

  /// This device's seat, or null when it has not enrolled.
  final SyncSession? session;

  /// An action is in flight (enrolling, joining, minting, syncing).
  final bool busy;

  final SyncError? error;
  final SyncMessage? message;

  /// A freshly minted invitation, shown until dismissed or the page leaves.
  final JoinInvite? invite;

  /// Which stage of the owner's invite preparation is running. Preparing an
  /// invite is a sync, a vacuum and a multi-megabyte upload — on a shop's 3G
  /// that is long enough that an unlabelled spinner reads as a hang.
  final BootstrapStep? step;

  /// The database was replaced by a bootstrap snapshot, so SQLite is closed and
  /// the app has to be restarted. Terminal: nothing else on this screen works
  /// from here.
  final bool restartRequired;

  final SyncOutcome? outcome;
  final DateTime? lastSyncAt;

  /// Every seat in the business, owner-only and network-fetched.
  ///
  /// Empty means "we have nothing to show", **not** "there are no devices" — the
  /// registry only exists on the server, so an offline owner sees this empty.
  /// That is why the page keys its empty/retry copy on [devicesLoading] and
  /// [devicesError] rather than on the list being short.
  final List<SyncDevice> devices;

  final bool devicesLoading;

  /// Why the registry could not be read. Deliberately **separate** from [error]:
  /// [error] drives a snackbar for something the owner just did, and a registry
  /// fetch nobody asked for must not throw a snackbar over the screen. It shows
  /// inline, on the section that failed.
  final SyncError? devicesError;

  /// The seat currently being revoked, so only its row spins.
  final String? revoking;

  const SyncState({
    this.loading = false,
    this.loaded = false,
    this.session,
    this.busy = false,
    this.error,
    this.message,
    this.invite,
    this.step,
    this.restartRequired = false,
    this.outcome,
    this.lastSyncAt,
    this.devices = const [],
    this.devicesLoading = false,
    this.devicesError,
    this.revoking,
  });

  bool get isEnrolled => session != null;
  bool get isOwner => session?.isOwner ?? false;

  SyncState copyWith({
    bool? loading,
    bool? loaded,
    SyncSession? session,
    bool? busy,
    SyncError? error,
    SyncMessage? message,
    JoinInvite? invite,
    BootstrapStep? step,
    bool? restartRequired,
    SyncOutcome? outcome,
    DateTime? lastSyncAt,
    List<SyncDevice>? devices,
    bool? devicesLoading,
    SyncError? devicesError,
    String? revoking,
    bool clearSession = false,
    bool clearFeedback = false,
    bool clearToken = false,
    bool clearStep = false,
    bool clearDevicesError = false,
    bool clearRevoking = false,
  }) {
    return SyncState(
      loading: loading ?? this.loading,
      loaded: loaded ?? this.loaded,
      session: clearSession ? null : (session ?? this.session),
      busy: busy ?? this.busy,
      // Feedback is one-shot: an explicit clear beats a carried-over value, so
      // a snackbar cannot fire again on the next unrelated rebuild.
      error: clearFeedback ? null : (error ?? this.error),
      message: clearFeedback ? null : (message ?? this.message),
      invite: clearToken ? null : (invite ?? this.invite),
      step: clearStep ? null : (step ?? this.step),
      restartRequired: restartRequired ?? this.restartRequired,
      outcome: outcome ?? this.outcome,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      devices: devices ?? this.devices,
      devicesLoading: devicesLoading ?? this.devicesLoading,
      devicesError: clearDevicesError ? null : (devicesError ?? this.devicesError),
      revoking: clearRevoking ? null : (revoking ?? this.revoking),
    );
  }

  @override
  List<Object?> get props => [
        loading,
        loaded,
        session,
        busy,
        error,
        message,
        invite,
        step,
        restartRequired,
        outcome,
        lastSyncAt,
        devices,
        devicesLoading,
        devicesError,
        revoking,
      ];
}
