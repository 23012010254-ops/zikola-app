// DUMMY FILE
// This file will be replaced when you run `flutterfire configure`.
// Do not modify manually unless necessary.

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
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the flutterfire cli.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBY9km5-ttCNxABx-K_1bR0N_Nhp2wh2CM',
    appId: '1:510792598386:web:1ede3f867ac7d1365c93eb',
    messagingSenderId: '510792598386',
    projectId: 'anak-app',
    authDomain: 'anak-app.firebaseapp.com',
    storageBucket: 'anak-app.firebasestorage.app',
    measurementId: 'G-1YDQHHT6T3',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB0Qg-vtyQewPpqjxypDbxl-yeFQ2jpbxE',
    appId: '1:510792598386:android:89a81105ba4e66c75c93eb',
    messagingSenderId: '510792598386',
    projectId: 'anak-app',
    storageBucket: 'anak-app.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAQXgziaAW-Dbwex3NT4JqkjKmyuxv_ke0',
    appId: '1:510792598386:ios:a735542eab2e50475c93eb',
    messagingSenderId: '510792598386',
    projectId: 'anak-app',
    storageBucket: 'anak-app.firebasestorage.app',
    iosBundleId: 'com.anakapp.anakApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'your-api-key',
    appId: 'your-app-id',
    messagingSenderId: 'your-sender-id',
    projectId: 'your-project-id',
    storageBucket: 'your-project-id.appspot.com',
    iosBundleId: 'com.example.anakApp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'your-api-key',
    appId: 'your-app-id',
    messagingSenderId: 'your-sender-id',
    projectId: 'your-project-id',
    authDomain: 'your-project-id.firebaseapp.com',
    storageBucket: 'your-project-id.appspot.com',
  );
}