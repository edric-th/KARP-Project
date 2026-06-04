import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:frontend/config/google_auth_config.dart';
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

  /// Google sign-in via the Firebase client SDK. Produces a Firebase idToken
  /// that the backend verifies; `/auth/google` ensures a patient profile.
  Future<AuthResult> signInWithGoogle() async {
    final googleSignIn = GoogleSignIn(
      scopes: const ['email', 'profile'],
      clientId:
          kIsWeb && GoogleAuthConfig.configured ? GoogleAuthConfig.webClientId : null,
      serverClientId: !kIsWeb && GoogleAuthConfig.configured
          ? GoogleAuthConfig.webClientId
          : null,
    );

    final account = await googleSignIn.signIn();
    if (account == null) {
      throw ApiException(0, 'Google sign-in was cancelled.');
    }
    final gAuth = await account.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: gAuth.idToken,
      accessToken: gAuth.accessToken,
    );
    final userCred =
        await FirebaseAuth.instance.signInWithCredential(credential);
    final fbUser = userCred.user;
    if (fbUser == null) throw ApiException(0, 'Google sign-in failed.');

    final idToken = await fbUser.getIdToken();
    await _tokens.saveTokens(
      idToken: idToken,
      refreshToken: fbUser.refreshToken,
      uid: fbUser.uid,
    );
    // Ensure a users/{uid} patient profile exists server-side.
    await _api.post('/auth/google', auth: true);
    return AuthResult(
      uid: fbUser.uid,
      name: fbUser.displayName,
      email: fbUser.email,
    );
  }

  Future<bool> get hasSession => _tokens.hasSession;

  Future<void> logout() async {
    try {
      await GoogleSignIn().signOut();
      await FirebaseAuth.instance.signOut();
    } catch (_) {/* Firebase not initialized / no Google session */}
    await _tokens.clear();
  }
}
