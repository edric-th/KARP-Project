/// OAuth **Web client ID** from Google Cloud Console
/// (APIs & Services → Credentials → OAuth 2.0 Client IDs → "Web client").
///
/// Used by `google_sign_in`:
///   • Web: passed as `clientId`.
///   • Android: passed as `serverClientId` so we receive a Firebase-usable idToken.
///
/// Provide it at build/run time (keeps it out of source):
///   flutter run --dart-define=GOOGLE_WEB_CLIENT_ID=xxxx.apps.googleusercontent.com
class GoogleAuthConfig {
  GoogleAuthConfig._();

  static const String webClientId =
      String.fromEnvironment('GOOGLE_WEB_CLIENT_ID', defaultValue: '');

  static bool get configured => webClientId.isNotEmpty;
}
