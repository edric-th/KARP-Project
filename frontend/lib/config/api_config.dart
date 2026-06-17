import 'package:flutter/foundation.dart';

/// Base URL for the FastAPI backend.
///
/// Override at build/run time without editing this file:
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.50:8000
///
/// Defaults are platform-aware:
///   • Android (physical phone) → the dev machine's LAN IP ([_lanHost])
///   • Web / Windows / desktop → localhost
class ApiConfig {
  ApiConfig._();

  /// The dev machine's LAN IP (same Wi‑Fi as the phone). A physical device
  /// can't reach `localhost` or the emulator alias `10.0.2.2` — those resolve
  /// to the phone itself — so it must use the host computer's address.
  /// Update this when your network changes: run `ipconfig` and use the IPv4
  /// address of your active Wi‑Fi adapter.
  ///
  /// Using the Android EMULATOR instead of a phone? Either set this to
  /// `10.0.2.2` or pass `--dart-define=API_BASE_URL=http://10.0.2.2:8000`.
  static const String _lanHost = '192.168.1.53';

  static const String _override =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    if (kIsWeb) return 'http://localhost:8000';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://$_lanHost:8000';
    }
    return 'http://localhost:8000';
  }

  /// All endpoints live under the `/api` prefix.
  static String get apiBase => '$baseUrl/api';
}
