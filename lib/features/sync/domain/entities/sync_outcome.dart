import 'package:equatable/equatable.dart';

import '../sync_error.dart';

/// What one sync pass did (Plan 002, Phase 1).
///
/// Reported rather than logged because the shopkeeper's mental model is "is my
/// other till up to date?", and the honest answer needs both directions and the
/// failure reason. A pass that pushed nothing and pulled nothing is a *success*
/// — everything is already in step — and the UI must not present that as
/// nothing having happened.
class SyncOutcome extends Equatable {
  final int pushed;
  final int pulled;

  /// Rows the server refused. Non-zero means something is stuck and will be
  /// retried; it is not fatal, but it must not be reported as a clean sync.
  final int rejected;

  /// Rows the server took but flagged as conflicting with another device's
  /// version of the same row (`device_conflicts`, ADR 0011 §11.2).
  ///
  /// Carried out rather than folded into [pushed], where it used to be silently
  /// lost: the row landed, so it is not a rejection, but "12 changes sent" and
  /// "12 sent, 2 of them disagreed with the other phone" are different answers
  /// and only one of them is true. Counted here even though there is no
  /// resolution screen yet — a count the owner can see is what makes the missing
  /// screen a known gap instead of an invisible one.
  final int conflicts;

  /// Set when the pass failed. Push and pull counts may still be non-zero — a
  /// pass that pushed successfully and then lost the network mid-pull did real
  /// work, and saying otherwise would make the user retry something that
  /// already landed.
  final SyncError? error;

  /// The server's own words for [error] — its `error.message`, or the transport
  /// failure text. **Never shown as ordinary copy**: it is untranslated and
  /// means nothing to a shopkeeper. It is what the long-press detail on the sync
  /// status row reveals.
  ///
  /// It exists because [SyncError] is a deliberately coarse taxonomy: everything
  /// the server does not give a typed code to lands on [SyncError.server], which
  /// renders as "something went wrong, try again". That is the right thing to
  /// show a shop and the wrong thing to debug with — a validation refusal naming
  /// the exact field, a 404 on a route that moved and a genuine outage are one
  /// message. Dropping the detail here cost a full field session: the server was
  /// answering `VALIDATION_FAILED` with the offending field in the message, and
  /// nothing carried it as far as a screen.
  final String? errorDetail;

  const SyncOutcome({
    this.pushed = 0,
    this.pulled = 0,
    this.rejected = 0,
    this.conflicts = 0,
    this.error,
    this.errorDetail,
  });

  bool get isSuccess => error == null;

  /// Whether anything actually moved. Distinct from [isSuccess]: "up to date"
  /// and "synced 12 changes" are both successes but read very differently.
  bool get didWork => pushed > 0 || pulled > 0;

  SyncOutcome copyWith({
    int? pushed,
    int? pulled,
    int? rejected,
    int? conflicts,
    SyncError? error,
    String? errorDetail,
  }) =>
      SyncOutcome(
        pushed: pushed ?? this.pushed,
        pulled: pulled ?? this.pulled,
        rejected: rejected ?? this.rejected,
        conflicts: conflicts ?? this.conflicts,
        error: error ?? this.error,
        errorDetail: errorDetail ?? this.errorDetail,
      );

  @override
  List<Object?> get props =>
      [pushed, pulled, rejected, conflicts, error, errorDetail];

  @override
  String toString() => 'SyncOutcome(pushed: $pushed, pulled: $pulled, '
      'rejected: $rejected, conflicts: $conflicts, error: $error)';
}
