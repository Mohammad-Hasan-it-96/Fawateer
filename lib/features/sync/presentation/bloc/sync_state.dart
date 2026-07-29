part of 'sync_bloc.dart';

/// One-shot successes. Typed, like the errors — the page owns the wording.
enum SyncMessage { enabled, joined, left, synced }

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
  final JoinToken? joinToken;

  final SyncOutcome? outcome;
  final DateTime? lastSyncAt;

  const SyncState({
    this.loading = false,
    this.loaded = false,
    this.session,
    this.busy = false,
    this.error,
    this.message,
    this.joinToken,
    this.outcome,
    this.lastSyncAt,
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
    JoinToken? joinToken,
    SyncOutcome? outcome,
    DateTime? lastSyncAt,
    bool clearSession = false,
    bool clearFeedback = false,
    bool clearToken = false,
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
      joinToken: clearToken ? null : (joinToken ?? this.joinToken),
      outcome: outcome ?? this.outcome,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
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
        joinToken,
        outcome,
        lastSyncAt,
      ];
}
