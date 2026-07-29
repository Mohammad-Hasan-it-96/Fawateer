import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_client.dart';
import 'api_config.dart';

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
    return _send(() => _client
        .post(_uri(endpoint), headers: _headers(token), body: jsonEncode(body))
        .timeout(timeout));
  }

  Future<Map<String, dynamic>> getJson(
    String endpoint, {
    String? token,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    return _send(
        () => _client.get(_uri(endpoint), headers: _headers(token)).timeout(timeout));
  }

  Future<Map<String, dynamic>> _send(
      Future<http.Response> Function() request) async {
    http.Response res;
    try {
      res = await request();
    } on TimeoutException {
      throw const SyncApiException(ApiErrorKind.timeout, 'Request timed out');
    } on SocketException catch (e) {
      throw SyncApiException(ApiErrorKind.network, e.message);
    } catch (e) {
      throw SyncApiException(ApiErrorKind.network, e.toString());
    }
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
