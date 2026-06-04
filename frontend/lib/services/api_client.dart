import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'token_store.dart';

/// Thrown for any non-2xx response (or a network failure with statusCode 0).
/// [message] is the backend's `detail` field when present.
class ApiException implements Exception {
  ApiException(this.statusCode, this.message);
  final int statusCode;
  final String message;

  bool get isUnauthorized => statusCode == 401;
  bool get isNetwork => statusCode == 0;

  @override
  String toString() => message;
}

/// Thin JSON HTTP client over the FastAPI backend.
///
///  • Injects `Authorization: Bearer <idToken>` when `auth: true`.
///  • Decodes JSON and maps non-2xx responses to [ApiException] (using the
///    backend's `detail`).
///  • On a 401 for an authed request, transparently refreshes the ID token
///    via `/auth/refresh` and retries once.
class ApiClient {
  ApiClient(this._tokens);

  final TokenStore _tokens;
  final http.Client _http = http.Client();

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final uri = Uri.parse('${ApiConfig.apiBase}$path');
    if (query == null || query.isEmpty) return uri;
    final qp = <String, String>{};
    query.forEach((k, v) {
      if (v != null) qp[k] = v.toString();
    });
    return qp.isEmpty ? uri : uri.replace(queryParameters: qp);
  }

  Future<Map<String, String>> _headers({required bool auth}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      String? token;
      // Google sessions: take the auto-refreshed token from the Firebase SDK.
      try {
        final fbUser = FirebaseAuth.instance.currentUser;
        if (fbUser != null) token = await fbUser.getIdToken();
      } catch (_) {/* Firebase not initialized — fall back to stored token */}
      // Email/password sessions: backend-issued token from secure storage.
      token ??= await _tokens.idToken;
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<dynamic> get(String path,
          {Map<String, dynamic>? query, bool auth = false}) =>
      _request('GET', path, query: query, auth: auth);

  Future<dynamic> post(String path, {Object? body, bool auth = false}) =>
      _request('POST', path, body: body, auth: auth);

  Future<dynamic> put(String path, {Object? body, bool auth = false}) =>
      _request('PUT', path, body: body, auth: auth);

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, dynamic>? query,
    Object? body,
    bool auth = false,
  }) async {
    try {
      var res = await _raw(method, path, query: query, body: body, auth: auth);

      if (res.statusCode == 401 && auth && await _tryRefresh()) {
        res = await _raw(method, path, query: query, body: body, auth: auth);
      }
      return _decode(res);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException(0, 'Could not reach the server. Is the backend running?');
    }
  }

  Future<http.Response> _raw(
    String method,
    String path, {
    Map<String, dynamic>? query,
    Object? body,
    bool auth = false,
  }) async {
    final uri = _uri(path, query);
    final headers = await _headers(auth: auth);
    final encoded = body == null ? null : jsonEncode(body);
    switch (method) {
      case 'GET':
        return _http.get(uri, headers: headers);
      case 'POST':
        return _http.post(uri, headers: headers, body: encoded);
      case 'PUT':
        return _http.put(uri, headers: headers, body: encoded);
      default:
        throw ArgumentError('Unsupported method $method');
    }
  }

  dynamic _decode(http.Response res) {
    dynamic data;
    if (res.body.isNotEmpty) {
      try {
        data = jsonDecode(res.body);
      } catch (_) {
        data = res.body;
      }
    }
    if (res.statusCode >= 200 && res.statusCode < 300) return data;

    var message = 'Request failed (${res.statusCode})';
    if (data is Map && data['detail'] != null) {
      final detail = data['detail'];
      message = detail is String ? detail : detail.toString();
    }
    throw ApiException(res.statusCode, message);
  }

  /// Exchange the stored refresh token for a fresh ID token. Clears the
  /// session and returns false if it can't (caller should then log out).
  Future<bool> _tryRefresh() async {
    final rt = await _tokens.refreshToken;
    if (rt == null) return false;
    try {
      final res = await _http.post(
        _uri('/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': rt}),
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        await _tokens.saveTokens(
          idToken: data['idToken'] as String?,
          refreshToken: data['refreshToken'] as String?,
          uid: (data['user'] as Map?)?['uid'] as String?,
        );
        return true;
      }
    } catch (_) {/* fall through to clear */}
    await _tokens.clear();
    return false;
  }
}
