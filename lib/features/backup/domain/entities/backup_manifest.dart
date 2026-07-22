/// Metadata that travels with every backup so a restore can be validated
/// *before* it touches the live database. Stored as Google Drive
/// `appProperties` on the uploaded file (private to this app), and rebuilt from
/// them when listing backups.
///
/// Key guard it powers: [schemaVersion] lets us refuse to restore a backup made
/// by a NEWER app build into an OLDER one (a silent-corruption trap), since
/// Drift migrations are forward-only.
class BackupManifest {
  final int schemaVersion;
  final String appVersion;
  final DateTime createdAt;
  final String deviceId;

  /// Hex SHA-256 of the snapshot bytes — verified after download.
  final String sha256;

  /// Short human summary of record counts, e.g. "inv:120 cust:30 prod:80".
  final String summary;

  const BackupManifest({
    required this.schemaVersion,
    required this.appVersion,
    required this.createdAt,
    required this.deviceId,
    required this.sha256,
    required this.summary,
  });

  /// A tag so `list()` only surfaces this app's backups.
  static const appTag = 'fawateer';

  /// Serialize to Drive `appProperties` (all values are short strings, each well
  /// under Drive's per-property byte limit).
  Map<String, String> toDriveProperties() => {
        'app': appTag,
        'schemaVersion': schemaVersion.toString(),
        'appVersion': appVersion,
        'createdAt': createdAt.toIso8601String(),
        'deviceId': deviceId,
        'sha256': sha256,
        'summary': summary,
      };

  factory BackupManifest.fromDriveProperties(Map<String, String> p) =>
      BackupManifest(
        schemaVersion: int.tryParse(p['schemaVersion'] ?? '') ?? 0,
        appVersion: p['appVersion'] ?? '',
        createdAt:
            DateTime.tryParse(p['createdAt'] ?? '')?.toLocal() ?? DateTime(2000),
        deviceId: p['deviceId'] ?? '',
        sha256: p['sha256'] ?? '',
        summary: p['summary'] ?? '',
      );
}
