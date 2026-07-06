/// Parsed contents of the hosted `fawateer_version.json` remote config.
///
/// Drives two things at startup: the API base URL (so the server can move
/// without a new build) and the in-app update prompt (compare [latestVersion]
/// against the installed version, then hand the user the right-ABI APK).
class RemoteConfig {
  /// Newest published app version, e.g. "1.0.0".
  final String latestVersion;

  /// API base URL to use for all server calls.
  final String baseUrl;

  /// Per-ABI APK download URLs, keyed by Android ABI (e.g. "arm64-v8a").
  final Map<String, String> downloads;

  /// Human-readable (Arabic) release notes, shown in the update dialog.
  final List<String> updateNotes;

  final String supportEmail;
  final String supportWhatsApp;
  final String supportTelegram;

  const RemoteConfig({
    required this.latestVersion,
    required this.baseUrl,
    required this.downloads,
    required this.updateNotes,
    required this.supportEmail,
    required this.supportWhatsApp,
    required this.supportTelegram,
  });

  /// Defensive parse — any missing/malformed field degrades to a safe default
  /// rather than throwing, so a bad publish can't hard-fail startup.
  factory RemoteConfig.fromJson(Map<String, dynamic> json) {
    final api = json['api'];
    final support = json['support'];
    final rawDownloads = json['downloads'];
    final rawNotes = json['update_notes'];

    String str(dynamic v) => v?.toString().trim() ?? '';
    Map<String, dynamic>? asMap(dynamic v) =>
        v is Map ? v.cast<String, dynamic>() : null;

    return RemoteConfig(
      latestVersion: str(json['latest_version']),
      baseUrl: str(asMap(api)?['base_url']),
      downloads: {
        if (asMap(rawDownloads) != null)
          for (final e in asMap(rawDownloads)!.entries)
            e.key: str(e.value),
      },
      updateNotes: rawNotes is List
          ? rawNotes.map(str).where((s) => s.isNotEmpty).toList()
          : const [],
      supportEmail: str(asMap(support)?['email']),
      supportWhatsApp: str(asMap(support)?['whatsapp']),
      supportTelegram: str(asMap(support)?['telegram']),
    );
  }
}
