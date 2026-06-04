import 'package:flutter/foundation.dart';

/// Base URL for the FastAPI backend.
///
/// Override at build/run time, e.g. for a physical phone on your Wi‑Fi:
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.50:8000
///
/// Defaults are platform-aware:
///   • Android emulator → 10.0.2.2 (the emulator's alias for the host's localhost)
///   • Web / Windows / desktop → localhost
class ApiConfig {
  ApiConfig._();

  static const String _override =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    if (kIsWeb) return 'http://localhost:8000';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://localhost:8000';
  }

  /// All endpoints live under the `/api` prefix.
  static String get apiBase => '$baseUrl/api';
}
