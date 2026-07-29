import 'package:equatable/equatable.dart';

/// The seed a device receives at enrollment so it does not come up blank in an
/// existing shop (ADR 0011, Decision 13).
///
/// [cursor] is the seq to pull from **after** applying the snapshot — the owner's
/// own local pull cursor, never a server `last_seq`. [snapshotUrl] and
/// [snapshotSha256] are present only when the owner attached a snapshot; a first
/// device (owner onboarding) joins an empty shop with cursor 0 and no snapshot.
///
/// This slice only carries the handoff; restoring the snapshot and pulling from
/// [cursor] is a later slice (it reuses Plan 001's `BackupEngine.restoreSnapshot`
/// and the SHA-256 check for genuine owner→joiner integrity).
class BootstrapHandoff extends Equatable {
  final int cursor;
  final String? snapshotUrl;
  final String? snapshotSha256;

  const BootstrapHandoff({
    required this.cursor,
    this.snapshotUrl,
    this.snapshotSha256,
  });

  /// True when there is a snapshot to restore before pulling from [cursor].
  bool get hasSnapshot =>
      snapshotUrl != null && (snapshotSha256?.isNotEmpty ?? false);

  factory BootstrapHandoff.fromJson(Map<String, dynamic> json) {
    final cursor = json['cursor'];
    return BootstrapHandoff(
      cursor: cursor is int ? cursor : int.tryParse('$cursor') ?? 0,
      snapshotUrl: json['snapshot_url']?.toString(),
      snapshotSha256: json['snapshot_sha256']?.toString(),
    );
  }

  @override
  List<Object?> get props => [cursor, snapshotUrl, snapshotSha256];
}
