part of 'sync_bloc.dart';

/// One-shot successes. Typed, like the errors — the page owns the wording.
enum SyncMessage { enabled, joined, left, synced, deviceRevoked, deviceRenamed }

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

  /// The raw technical reason behind [error] or [devicesError] — the server's
  /// message, its typed code, or `HTTP <status>`.
  ///
  /// **Never shown as ordinary UI copy.** It is untranslated and means nothing
  /// to a shopkeeper; the screen still renders only the localized text mapped
  /// from the typed error. It is reachable on purpose (a long press on the
  /// status card) because most of [SyncError]'s members are unreachable in
  /// normal running, so `server` — the catch-all — is what a shop actually
  /// hits, and "something went wrong, try again" says nothing at all about
  /// which of a wrong URL, a rejected payload, an expired token or a real
  /// outage it was. Those need completely different fixes, and telling them
  /// apart from a support message otherwise costs a round trip per attempt.
  ///
  /// This exists because of a real one: the client called `/sync/push` and
  /// `/sync/pull`, the names in the 2026-07-27 design, while the shipped routes
  /// are `POST|GET /sync/changes`. Every pass 404'd, every 404 fell to
  /// `SyncError.server`, and the shop was told to try again — forever.
  final String? errorDetail;

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

  /// The business's seats and allowance, owner-only and network-fetched.
  ///
  /// **Null means "we have not been told", never "there are none".** The
  /// registry lives only on the server, so an offline owner has none — and a
  /// screen that renders that as "0 of 3 phones used" is stating something false
  /// about a shop that may have three. Nullable so the two cannot be confused.
  final SyncDeviceRegistry? registry;

  final bool devicesLoading;

  /// Why the registry could not be read. Deliberately **separate** from [error]:
  /// [error] drives a snackbar for something the owner just did, and a registry
  /// fetch nobody asked for must not throw a snackbar over the screen. It shows
  /// inline, on the section that failed.
  final SyncError? devicesError;

  /// The seat currently being revoked, so only its row spins.
  final String? revoking;

  /// The seat currently being renamed. Separate from [revoking] so a rename
  /// cannot make a row look like it is being removed — the two are one tap
  /// apart and the destructive reading is the one that alarms an owner.
  final String? renaming;

  const SyncState({
    this.loading = false,
    this.loaded = false,
    this.session,
    this.busy = false,
    this.error,
    this.message,
    this.errorDetail,
    this.invite,
    this.step,
    this.restartRequired = false,
    this.outcome,
    this.lastSyncAt,
    this.registry,
    this.devicesLoading = false,
    this.devicesError,
    this.revoking,
    this.renaming,
  });

  bool get isEnrolled => session != null;
  bool get isOwner => session?.isOwner ?? false;

  List<SyncDevice> get devices => registry?.devices ?? const [];

  /// Seats this business may hold — the server's current number, falling back to
  /// the one cached when this device enrolled. Null when neither is known.
  ///
  /// The server's wins because a plan upgrade changes it and the cached one is
  /// from enrollment day: an owner who has just paid for five seats must not be
  /// told they have three.
  int? get allowance {
    final fresh = registry?.allowance;
    if (fresh != null && fresh > 0) return fresh;
    final cached = session?.deviceAllowance ?? 0;
    return cached > 0 ? cached : null;
  }

  /// True only when the registry has actually been read **and** it is full.
  /// Never true on an unknown allowance or an unread registry — a gate that
  /// fires on missing information locks an owner out of their own plan.
  bool get isAtCap {
    final r = registry;
    final limit = allowance;
    return r != null && limit != null && r.used >= limit;
  }

  SyncState copyWith({
    bool? loading,
    bool? loaded,
    SyncSession? session,
    bool? busy,
    SyncError? error,
    SyncMessage? message,
    String? errorDetail,
    JoinInvite? invite,
    BootstrapStep? step,
    bool? restartRequired,
    SyncOutcome? outcome,
    DateTime? lastSyncAt,
    SyncDeviceRegistry? registry,
    bool? devicesLoading,
    SyncError? devicesError,
    String? revoking,
    String? renaming,
    bool clearSession = false,
    bool clearFeedback = false,
    bool clearToken = false,
    bool clearStep = false,
    bool clearDevicesError = false,
    bool clearRevoking = false,
    bool clearRenaming = false,
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
      // **Deliberately NOT cleared with the feedback.** It used to be, on the
      // reasoning that a detail riding with its error can never be read against
      // a newer one — which was right about the risk and fatal in practice: the
      // page dispatches `ClearSyncFeedback` immediately after showing every
      // snackbar, so the detail lived for exactly one frame and the long-press
      // dialog always said "no details". The whole mechanism was inert from the
      // day it shipped, and the field failure it exists for hit anyway.
      //
      // The desync it guarded against is closed a better way: the detail is
      // recorded already carrying its own typed error name (`SyncBloc._detailOf`),
      // so it is self-describing and cannot be misread against whatever `error`
      // happens to hold now. It is only ever replaced by a newer failure, never
      // resurrected.
      errorDetail: errorDetail ?? this.errorDetail,
      invite: clearToken ? null : (invite ?? this.invite),
      step: clearStep ? null : (step ?? this.step),
      restartRequired: restartRequired ?? this.restartRequired,
      outcome: outcome ?? this.outcome,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      registry: registry ?? this.registry,
      devicesLoading: devicesLoading ?? this.devicesLoading,
      devicesError: clearDevicesError ? null : (devicesError ?? this.devicesError),
      revoking: clearRevoking ? null : (revoking ?? this.revoking),
      renaming: clearRenaming ? null : (renaming ?? this.renaming),
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
        errorDetail,
        invite,
        step,
        restartRequired,
        outcome,
        lastSyncAt,
        registry,
        devicesLoading,
        devicesError,
        revoking,
        renaming,
      ];
}
