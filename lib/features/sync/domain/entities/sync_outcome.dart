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

  /// Set when the pass failed. Push and pull counts may still be non-zero — a
  /// pass that pushed successfully and then lost the network mid-pull did real
  /// work, and saying otherwise would make the user retry something that
  /// already landed.
  final SyncError? error;

  const SyncOutcome({
    this.pushed = 0,
    this.pulled = 0,
    this.rejected = 0,
    this.error,
  });

  bool get isSuccess => error == null;

  /// Whether anything actually moved. Distinct from [isSuccess]: "up to date"
  /// and "synced 12 changes" are both successes but read very differently.
  bool get didWork => pushed > 0 || pulled > 0;

  SyncOutcome copyWith({int? pushed, int? pulled, int? rejected, SyncError? error}) =>
      SyncOutcome(
        pushed: pushed ?? this.pushed,
        pulled: pulled ?? this.pulled,
        rejected: rejected ?? this.rejected,
        error: error ?? this.error,
      );

  @override
  List<Object?> get props => [pushed, pulled, rejected, error];

  @override
  String toString() =>
      'SyncOutcome(pushed: $pushed, pulled: $pulled, rejected: $rejected, error: $error)';
}
