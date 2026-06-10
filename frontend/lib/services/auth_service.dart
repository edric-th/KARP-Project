import 'package:firebase_auth/firebase_auth.dart';

import 'package:frontend/services/api_client.dart';
import 'package:frontend/services/token_store.dart';

class AuthResult {
  AuthResult({required this.uid, this.name, this.email});
  final String uid;
  final String? name;
  final String? email;
}

/// Handles sign-up / login / logout and token persistence.
class AuthService {
  AuthService(this._api, this._tokens);
  final ApiClient _api;
  final TokenStore _tokens;

  Future<AuthResult> signup({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    final data = await _api.post('/auth/signup', body: {
      'name': name,
      'email': email,
      'password': password,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
    });
    return _persist(Map<String, dynamic>.from(data as Map));
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final data = await _api.post('/auth/login', body: {
      'email': email,
      'password': password,
    });
    return _persist(Map<String, dynamic>.from(data as Map));
  }

  Future<AuthResult> _persist(Map<String, dynamic> data) async {
    final user = (data['user'] as Map?) ?? const {};
    await _tokens.saveTokens(
      idToken: data['idToken'] as String?,
      refreshToken: data['refreshToken'] as String?,
      uid: user['uid'] as String?,
    );
    return AuthResult(
      uid: (user['uid'] ?? '') as String,
      name: user['name'] as String?,
      email: user['email'] as String?,
    );
  }

  /// Send a registration OTP to [email]. Returns the raw response, which may
  /// include `devCode` when the backend has no SMTP configured (dev mode).
  Future<Map<String, dynamic>> sendOtp(String email) async {
    final data = await _api.post('/auth/send-otp', body: {'email': email});
    return Map<String, dynamic>.from(data as Map);
  }

  Future<bool> verifyOtp(String email, String code) async {
    final data = await _api.post(
      '/auth/verify-otp',
      body: {'email': email, 'code': code},
    );
    return data is Map && data['verified'] == true;
  }

  /// Change the signed-in user's password (verifies [current] server-side).
  Future<void> changePassword(String current, String newPassword) async {
    await _api.post('/auth/change-password', auth: true, body: {
      'currentPassword': current,
      'newPassword': newPassword,
    });
  }

  /// Flag the signed-in user's email as verified after they complete the OTP.
  Future<void> markEmailVerified() async {
    await _api.post('/auth/verify-email', auth: true);
  }

  Future<bool> get hasSession => _tokens.hasSession;

  Future<void> logout() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {/* Firebase not initialized / no session */}
    await _tokens.clear();
  }
}
