import 'package:flutter/foundation.dart';

import 'package:frontend/models/profile_model.dart';
import 'package:frontend/services/api_client.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/services/profile_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._auth, this._profiles);
  final AuthService _auth;
  final ProfileService _profiles;

  AuthStatus status = AuthStatus.unknown;
  ProfileModel? profile;
  String? error;
  bool busy = false;

  bool get isAuthenticated => status == AuthStatus.authenticated;

  /// Restore a stored session on app start.
  Future<void> bootstrap() async {
    if (await _auth.hasSession) {
      try {
        profile = await _profiles.getProfile();
        status = AuthStatus.authenticated;
      } catch (_) {
        await _auth.logout();
        status = AuthStatus.unauthenticated;
      }
    } else {
      status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) => _run(() async {
        await _auth.login(email: email, password: password);
        profile = await _profiles.getProfile();
      });

  Future<bool> signup({
    required String name,
    required String email,
    required String password,
    String? phone,
    Map<String, dynamic>? profileFields,
  }) =>
      _run(() async {
        await _auth.signup(
            name: name, email: email, password: password, phone: phone);
        if (profileFields != null && profileFields.isNotEmpty) {
          profile = await _profiles.updateProfile(profileFields);
        } else {
          profile = await _profiles.getProfile();
        }
      });

  Future<void> refreshProfile() async {
    try {
      profile = await _profiles.getProfile();
      notifyListeners();
    } catch (_) {/* keep existing profile */}
  }

  /// Persist edited profile fields (flat camelCase map) and refresh state.
  Future<bool> saveProfile(Map<String, dynamic> fields) async {
    try {
      profile = await _profiles.updateProfile(fields);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Change the account password. Returns null on success, else an error msg.
  Future<String?> changePassword(String current, String newPassword) async {
    try {
      await _auth.changePassword(current, newPassword);
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Could not change password. Please try again.';
    }
  }

  /// Send an email-verification OTP to the signed-in user's email.
  /// Returns the (dev) code when the server has no SMTP configured, else null.
  Future<String?> sendEmailOtp(String email) async {
    final resp = await _auth.sendOtp(email);
    return resp['devCode'] as String?;
  }

  /// Verify the OTP for [email] then flag the profile as verified.
  Future<bool> confirmEmailVerification(String email, String code) async {
    final ok = await _auth.verifyOtp(email, code);
    if (!ok) return false;
    await _auth.markEmailVerified();
    await refreshProfile();
    return true;
  }

  Future<void> logout() async {
    await _auth.logout();
    profile = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<bool> _run(Future<void> Function() action) async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      await action();
      status = AuthStatus.authenticated;
      busy = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      error = e.message;
      busy = false;
      notifyListeners();
      return false;
    } catch (_) {
      error = 'Something went wrong. Please try again.';
      busy = false;
      notifyListeners();
      return false;
    }
  }
}
