import 'package:equatable/equatable.dart';

/// A backup that exists on the remote target (one Google Drive file), described
/// well enough to display and to validate a restore without downloading first.
class BackupInfo extends Equatable {
  /// Provider file id (Drive file id).
  final String id;
  final String name;
  final DateTime createdAt;
  final int sizeBytes;

  /// From the file's manifest (see [BackupManifest]).
  final int schemaVersion;
  final String sha256;
  final String deviceId;
  final String summary;

  /// True when this backup came from the device currently running the app.
  final bool fromThisDevice;

  const BackupInfo({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.sizeBytes,
    required this.schemaVersion,
    required this.sha256,
    required this.deviceId,
    required this.summary,
    required this.fromThisDevice,
  });

  @override
  List<Object?> get props => [id];
}
