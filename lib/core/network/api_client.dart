import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_config.dart';

/// The kind of transport-level failure an [ApiClient] call hit. The repository
/// layer maps these onto the app's `Failure` taxonomy.
enum ApiErrorKind {
  /// No connectivity (DNS/socket) — the request never reached the server.
  network,

  /// The request reached out but timed out waiting for a response.
  timeout,

  /// The server responded with a non-2xx status.
  server,

  /// The response body wasn't the expected JSON object.
  badResponse,
}

class ApiException implements Exception {
  final ApiErrorKind kind;
  final String message;
  const ApiException(this.kind, this.message);

  /// True when the server was never reached — the app is effectively offline
  /// and may fall back to cached state within the offline-grace window.
  bool get isOffline =>
      kind == ApiErrorKind.network || kind == ApiErrorKind.timeout;

  @override
  String toString() => 'ApiException($kind): $message';
}

/// Minimal JSON-over-HTTP client — the app's only networking primitive. Keeps
/// no auth/token state (the current backend is unauthenticated; identity is the
/// hashed device id sent in the body). Base URL is overridable so staging/prod
/// or a future Fawateer server can be swapped in without touching callers.
class ApiClient {
  final String baseUrl;
  final http.Client _client;

  ApiClient({String? baseUrl, http.Client? client})
      : baseUrl = baseUrl ?? ApiConfig.defaultBaseUrl,
        _client = client ?? http.Client();

  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Uri _uri(String endpoint) {
    final clean = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    return Uri.parse('$baseUrl/$clean');
  }

  Future<Map<String, dynamic>> postJson(
    String endpoint,
    Map<String, dynamic> body, {
    Duration timeout = const Duration(seconds: 12),
  }) async {
    http.Response res;
    try {
      res = await _client
          .post(_uri(endpoint), headers: _headers, body: jsonEncode(body))
          .timeout(timeout);
    } on TimeoutException {
      throw const ApiException(ApiErrorKind.timeout, 'Request timed out');
    } on SocketException catch (e) {
      throw ApiException(ApiErrorKind.network, e.message);
    } catch (e) {
      throw ApiException(ApiErrorKind.network, e.toString());
    }
    return _decode(res);
  }

  Future<Map<String, dynamic>> getJson(
    String endpoint, {
    Duration timeout = const Duration(seconds: 15),
  }) async {
    http.Response res;
    try {
      res = await _client.get(_uri(endpoint), headers: _headers).timeout(timeout);
    } on TimeoutException {
      throw const ApiException(ApiErrorKind.timeout, 'Request timed out');
    } on SocketException catch (e) {
      throw ApiException(ApiErrorKind.network, e.message);
    } catch (e) {
      throw ApiException(ApiErrorKind.network, e.toString());
    }
    return _decode(res);
  }

  Map<String, dynamic> _decode(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(ApiErrorKind.server, 'HTTP ${res.statusCode}');
    }
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) return decoded;
      throw const ApiException(
          ApiErrorKind.badResponse, 'Expected a JSON object');
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(ApiErrorKind.badResponse, 'Invalid JSON body');
    }
  }
}
