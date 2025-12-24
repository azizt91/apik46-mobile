import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCbS4nJGXnJD0fF4L6g8i1CQJpzC31F8NI',
    appId: '1:661760736056:android:6cb2f5923e38f43a82dfcd',
    messagingSenderId: '661760736056',
    projectId: 'selinggonet-push-notification',
    storageBucket: 'selinggonet-push-notification.firebasestorage.app',
  );

  // Web config - perlu ditambahkan dari Firebase Console jika mau support web
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCbS4nJGXnJD0fF4L6g8i1CQJpzC31F8NI',
    appId: '1:661760736056:web:YOUR_WEB_APP_ID', // Ganti dengan web app ID dari Firebase Console
    messagingSenderId: '661760736056',
    projectId: 'selinggonet-push-notification',
    storageBucket: 'selinggonet-push-notification.firebasestorage.app',
  );
}
