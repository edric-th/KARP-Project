import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Securely persists the Firebase ID token, refresh token and uid so the
/// session survives app restarts.
class TokenStore {
  TokenStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _kId = 'idToken';
  static const _kRefresh = 'refreshToken';
  static const _kUid = 'uid';

  Future<String?> get idToken => _storage.read(key: _kId);
  Future<String?> get refreshToken => _storage.read(key: _kRefresh);
  Future<String?> get uid => _storage.read(key: _kUid);

  Future<bool> get hasSession async => (await idToken) != null;

  Future<void> saveTokens({
    String? idToken,
    String? refreshToken,
    String? uid,
  }) async {
    if (idToken != null) await _storage.write(key: _kId, value: idToken);
    if (refreshToken != null) {
      await _storage.write(key: _kRefresh, value: refreshToken);
    }
    if (uid != null) await _storage.write(key: _kUid, value: uid);
  }

  Future<void> clear() => _storage.deleteAll();
}
