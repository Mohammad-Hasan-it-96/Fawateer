import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/api_config.dart';
import 'remote_config.dart';

/// Fetches the hosted `fawateer_version.json`, applies it (API base URL +
/// support contacts) and works out whether an app update is available.
///
/// It's resilient by design: the network fetch is time-boxed and falls back to
/// the last cached copy, and a total failure just leaves the baked-in
/// [ApiConfig] defaults in place — startup is never blocked or broken by it.
class RemoteConfigService {
  RemoteConfigService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  /// Google-Drive direct-download endpoint for the shared `fawateer_version.json`
  /// (file id `1pVMkNYKAGjiO8tRSG3nEcVGvEQS8xcVk`).
  static const String _configUrl =
      'https://drive.google.com/uc?export=download&id=1pVMkNYKAGjiO8tRSG3nEcVGvEQS8xcVk';

  static const String _kCache = 'remote_config_json';

  /// The most recently resolved config (from network or cache); null until a
  /// [refresh] runs.
  RemoteConfig? current;

  /// True when [current] advertises a newer version than the installed build.
  bool updateAvailable = false;

  /// The APK URL matching this device's ABI (or the first available), when an
  /// update is available.
  String? downloadUrl;

  Future<void>? _ready;

  /// Run [refresh] exactly once and share the same future with every caller, so
  /// `main()` (which applies the base URL early) and the update-checker widget
  /// don't each trigger a separate fetch.
  Future<void> ensureLoaded() => _ready ??= refresh();

  /// Fetch → parse → apply → compute update status. Never throws.
  Future<void> refresh() async {
    RemoteConfig? config = await _fetch();
    config ??= await _loadCached();
    if (config == null) return; // keep baked-in defaults

    current = config;
    _apply(config);
    await _computeUpdate(config);
  }

  // ── networking ─────────────────────────────────────────────────────────────

  Future<RemoteConfig?> _fetch() async {
    try {
      final res = await _client
          .get(Uri.parse(_configUrl))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode < 200 || res.statusCode >= 300) return null;
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      if (decoded is! Map<String, dynamic>) return null;
      await _cache(res.bodyBytes);
      return RemoteConfig.fromJson(decoded);
    } catch (_) {
      return null; // offline / bad payload → caller falls back to cache
    }
  }

  Future<void> _cache(List<int> bytes) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_kCache, utf8.decode(bytes));
    } catch (_) {/* non-fatal */}
  }

  Future<RemoteConfig?> _loadCached() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_kCache);
      if (raw == null) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return RemoteConfig.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  // ── apply ───────────────────────────────────────────────────────────────────

  void _apply(RemoteConfig cfg) {
    if (cfg.baseUrl.isNotEmpty) ApiConfig.baseUrl = cfg.baseUrl;
    if (cfg.supportEmail.isNotEmpty) ApiConfig.supportEmail = cfg.supportEmail;
    if (cfg.supportWhatsApp.isNotEmpty) {
      ApiConfig.supportWhatsApp = cfg.supportWhatsApp;
    }
    if (cfg.supportTelegram.isNotEmpty) {
      ApiConfig.supportTelegram = cfg.supportTelegram;
    }
  }

  // ── update check ─────────────────────────────────────────────────────────────

  Future<void> _computeUpdate(RemoteConfig cfg) async {
    updateAvailable = false;
    downloadUrl = null;
    if (cfg.latestVersion.isEmpty) return;
    try {
      final info = await PackageInfo.fromPlatform();
      if (!_isNewer(cfg.latestVersion, info.version)) return;
      updateAvailable = true;
      downloadUrl = await _pickDownload(cfg.downloads);
    } catch (_) {
      updateAvailable = false;
    }
  }

  /// Pick the APK URL for this device's ABI, falling back to any available one.
  Future<String?> _pickDownload(Map<String, String> downloads) async {
    if (downloads.isEmpty) return null;
    try {
      if (Platform.isAndroid) {
        final abis = (await DeviceInfoPlugin().androidInfo).supportedAbis;
        for (final abi in abis) {
          final url = downloads[abi];
          if (url != null && url.isNotEmpty) return url;
        }
      }
    } catch (_) {/* fall through */}
    return downloads.values.firstWhere((u) => u.isNotEmpty,
        orElse: () => '');
  }

  /// Dotted-version compare: true when [remote] is strictly newer than
  /// [installed] (e.g. "1.2.0" > "1.1.9"). Non-numeric parts count as 0.
  static bool _isNewer(String remote, String installed) {
    List<int> parts(String v) =>
        v.split('.').map((p) => int.tryParse(p.trim()) ?? 0).toList();
    final r = parts(remote);
    final i = parts(installed);
    final n = r.length > i.length ? r.length : i.length;
    for (var k = 0; k < n; k++) {
      final rv = k < r.length ? r[k] : 0;
      final iv = k < i.length ? i[k] : 0;
      if (rv != iv) return rv > iv;
    }
    return false;
  }
}
