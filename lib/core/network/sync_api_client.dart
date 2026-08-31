import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'api_client.dart';
import 'api_config.dart';

/// Debug-build wire log for every sync call: method, URL, status, and the body
/// the server sent back.
///
/// **Not diagnostics for a shop — diagnostics for a two-phone field test.**
/// `SyncError` is a coarse taxonomy and almost everything lands on `server`,
/// whose copy is "something went wrong, try again". The in-app detail dialog
/// exists for this, but it is behind a long press on one row, which is no help
/// when the phone is plugged into Android Studio and the person holding it is
/// the developer. Two separate wire mismatches (the route names, the snapshot
/// hash field) each cost a field session that this line would have ended.
///
/// Stripped from release builds by `kDebugMode`, and the Bearer is never
/// included — the seat token is a durable credential and logcat is readable by
/// any app with the right tooling attached.
void _wireLog(String line) {
  if (kDebugMode) debugPrint('[sync] $line');
}

/// A transport-level failure from the sync API, carrying the server's
/// machine-readable error **code** when there was one.
///
/// The licensing [ApiClient] collapses every non-2xx into `HTTP <status>` because
/// its endpoints have no typed error contract. The sync endpoints do: the
/// platform envelope is `{"error": {"code": "ALLOWANCE_EXCEEDED", ...}}`, and the
/// app must act on that code (show "upgrade your plan", not a generic error). So
/// this client parses it and preserves it here for the repository to map onto a
/// typed [SyncError].
class SyncApiException implements Exception {
  final ApiErrorKind kind;

  /// The server's `error.code` (e.g. `ALLOWANCE_EXCEEDED`), or null for transport
  /// failures that never reached a JSON error body.
  final String? code;

  final String message;

  const SyncApiException(this.kind, this.message, {this.code});

  /// True when the server was never reached — offline/timeout.
  bool get isOffline =>
      kind == ApiErrorKind.network || kind == ApiErrorKind.timeout;

  @override
  String toString() => 'SyncApiException($kind, code: $code): $message';
}

/// Authenticated JSON-over-HTTP client for the versioned, authenticated sync API
/// (`/api/v1/sync/*`) — a sibling to the unauthenticated licensing [ApiClient].
///
/// Two things differ from licensing and are why this is its own client rather
/// than a flag on [ApiClient]:
///  - **A different base path.** Licensing lives under the app namespace
///    (`…/api/fawateer`, Profile A); sync lives at the versioned root
///    (`…/api/v1`, Profile B). The base is derived from [ApiConfig.baseUrl] at
///    request time, so a remote-config repoint of the host still applies.
///  - **A Bearer credential.** Every guarded call carries the device's durable
///    seat token; the licensing client is unauthenticated (device id in the body).
class SyncApiClient {
  final http.Client _client;

  /// Test/staging override of the derived base. Null in production so the base
  /// tracks [ApiConfig.baseUrl] (remote-config mutable) per request.
  final String? _baseUrlOverride;

  SyncApiClient({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrlOverride = baseUrl;

  /// The versioned API root, derived from the licensing base by swapping the app
  /// namespace segment for `v1`: `…/api/fawateer` → `…/api/v1`.
  String get baseUrl {
    final override = _baseUrlOverride;
    if (override != null) return override;
    final base = ApiConfig.baseUrl.replaceAll(RegExp(r'/+$'), '');
    final cut = base.lastIndexOf('/');
    final root = cut > 0 ? base.substring(0, cut) : base; // ".../api"
    return '$root/v1';
  }

  Uri _uri(String endpoint) {
    final clean = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    return Uri.parse('$baseUrl/$clean');
  }

  Map<String, String> _headers(String? token) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

  Future<Map<String, dynamic>> postJson(
    String endpoint,
    Map<String, dynamic> body, {
    String? token,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    return _send('POST ${_uri(endpoint)}', () => _client
        .post(_uri(endpoint), headers: _headers(token), body: jsonEncode(body))
        .timeout(timeout));
  }

  Future<Map<String, dynamic>> getJson(
    String endpoint, {
    String? token,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    return _send('GET ${_uri(endpoint)}',
        () => _client.get(_uri(endpoint), headers: _headers(token)).timeout(timeout));
  }

  Future<Map<String, dynamic>> delete(
    String endpoint, {
    String? token,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    return _send('DELETE ${_uri(endpoint)}', () =>
        _client.delete(_uri(endpoint), headers: _headers(token)).timeout(timeout));
  }

  /// Partial update (`PATCH`) — currently only the seat rename.
  ///
  /// A separate verb rather than reusing [postJson]: the seat routes are
  /// method-dispatched server-side, and POSTing to `sync/devices/{seat}` would
  /// be a 405, not a rename.
  Future<Map<String, dynamic>> patchJson(
    String endpoint,
    Map<String, dynamic> body, {
    String? token,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    return _send('PATCH ${_uri(endpoint)}', () => _client
        .patch(_uri(endpoint), headers: _headers(token), body: jsonEncode(body))
        .timeout(timeout));
  }

  /// Upload a file with accompanying form fields.
  ///
  /// Multipart rather than a JSON body with base64: the bootstrap snapshot is
  /// the shop's whole database, and base64 would inflate it by a third and force
  /// both ends to hold the entire thing in memory as a string.
  ///
  /// [endpoint] may be an absolute URL — the server hands back an upload target
  /// rather than us assuming the path.
  ///
  /// The timeout is far longer than the JSON default: this is a multi-megabyte
  /// body on a shop's 3G, and 15 seconds would fail every real upload.
  Future<Map<String, dynamic>> postFile(
    String endpoint,
    File file, {
    Map<String, String> fields = const {},
    String field = 'snapshot',
    String? token,
    Duration timeout = const Duration(minutes: 5),
  }) async {
    final target =
        endpoint.startsWith('http') ? Uri.parse(endpoint) : _uri(endpoint);
    // Logged before the send, not only after: a multi-megabyte upload on a
    // shop's 3G can sit here for minutes, and a line that only appears on
    // completion makes a slow upload and a hung one look identical.
    _wireLog('POST(file) $target '
        'fields=${fields.keys.toList()} '
        'size=${await file.length()}B');
    return _send('POST(file) $target', () async {
      final uri = target;
      final request = http.MultipartRequest('POST', uri)
        ..headers.addAll({
          'Accept': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        })
        ..fields.addAll(fields)
        ..files.add(await http.MultipartFile.fromPath(field, file.path));
      final streamed = await _client.send(request).timeout(timeout);
      return http.Response.fromStream(streamed);
    });
  }

  /// Fetch raw bytes from a **signed URL the server gave us**, not from an
  /// endpoint on this API — so it deliberately sends no Bearer token and does no
  /// JSON decoding. The signature in the URL is the credential.
  Future<List<int>> downloadBytes(
    String url, {
    Duration timeout = const Duration(minutes: 5),
  }) async {
    http.Response res;
    try {
      res = await _client.get(Uri.parse(url)).timeout(timeout);
    } on TimeoutException {
      throw const SyncApiException(ApiErrorKind.timeout, 'Download timed out');
    } on SocketException catch (e) {
      throw SyncApiException(ApiErrorKind.network, e.message);
    } catch (e) {
      throw SyncApiException(ApiErrorKind.network, e.toString());
    }
    _wireLog('GET(bytes) $url -> ${res.statusCode} ${res.bodyBytes.length}B');
    if (res.statusCode < 200 || res.statusCode >= 300) {
      // A signed URL that has expired comes back as a plain 403 with no JSON
      // envelope, so there is no typed code to preserve here.
      throw SyncApiException(
          ApiErrorKind.server, 'HTTP ${res.statusCode}', code: 'SNAPSHOT_GONE');
    }
    return res.bodyBytes;
  }

  Future<Map<String, dynamic>> _send(
      String label, Future<http.Response> Function() request) async {
    http.Response res;
    try {
      res = await request();
    } on TimeoutException {
      _wireLog('$label -> TIMEOUT');
      throw const SyncApiException(ApiErrorKind.timeout, 'Request timed out');
    } on SocketException catch (e) {
      _wireLog('$label -> SOCKET ${e.message}');
      throw SyncApiException(ApiErrorKind.network, e.message);
    } catch (e) {
      _wireLog('$label -> $e');
      throw SyncApiException(ApiErrorKind.network, e.toString());
    }
    // The whole body on a refusal, truncated on success. A 4xx body is the
    // thing worth reading; a 200 page of 200 rows is not, and would bury it.
    final ok = res.statusCode >= 200 && res.statusCode < 300;
    _wireLog('$label -> ${res.statusCode} '
        '${ok ? '${res.body.length}B' : res.body}');
    return _decode(res);
  }

  Map<String, dynamic> _decode(http.Response res) {
    // Parse the body first — an error response carries the typed code we need.
    Map<String, dynamic>? json;
    try {
      final decoded = res.body.isEmpty ? null : jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) json = decoded;
    } catch (_) {
      json = null;
    }

    if (res.statusCode < 200 || res.statusCode >= 300) {
      final error = json?['error'];
      final code = error is Map ? error['code']?.toString() : null;
      final message =
          (error is Map ? error['message']?.toString() : null) ?? 'HTTP ${res.statusCode}';
      throw SyncApiException(ApiErrorKind.server, message, code: code);
    }

    if (json == null) {
      throw const SyncApiException(
          ApiErrorKind.badResponse, 'Expected a JSON object');
    }
    return json;
  }
}
