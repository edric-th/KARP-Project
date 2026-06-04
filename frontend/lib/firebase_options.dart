// Firebase configuration for the Mero Palo patient app.
//
// The WEB values below are the real ones from the shared Firebase project
// (same project the admin panel uses). For ANDROID, run `flutterfire configure`
// (or drop in google-services.json) to register the Android app and get its
// correct appId — the placeholder below just lets the app compile until then.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  DefaultFirebaseOptions._();

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        // iOS / macOS / desktop — replace via `flutterfire configure`.
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDFD9TvfzAnxqNIXAg6mL2bEUw0xEKO6g4',
    appId: '1:536199467076:web:d3aefe02abeedb241cec11',
    messagingSenderId: '536199467076',
    projectId: 'hospital-queue-managemen-67208',
    authDomain: 'hospital-queue-managemen-67208.firebaseapp.com',
    storageBucket: 'hospital-queue-managemen-67208.firebasestorage.app',
  );

  // TODO(setup): replace `appId` with the Android app id produced by
  // `flutterfire configure` (it registers the Android app + writes
  // android/app/google-services.json). Until then Google sign-in works on web.
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDFD9TvfzAnxqNIXAg6mL2bEUw0xEKO6g4',
    appId: '1:536199467076:web:d3aefe02abeedb241cec11',
    messagingSenderId: '536199467076',
    projectId: 'hospital-queue-managemen-67208',
    storageBucket: 'hospital-queue-managemen-67208.firebasestorage.app',
  );
}
