import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

// Firebase options for the SpeedyTrips Firebase project.
// Pass FIREBASE_WEB_* dart-defines to override the web app fields.
class DefaultFirebaseOptions {
  static FirebaseOptions? get currentPlatform {
    if (kIsWeb) {
      return web;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return null;
    }
  }

  static const String projectId = 'speedytrips-5b584';
  static const String messagingSenderId = '677273835452';
  static const String storageBucket = 'speedytrips-5b584.firebasestorage.app';
  static const String androidApiKey = 'AIzaSyB2a9bW-SBgXklKRy_7K2HAbrWXfSalk4k';
  static const String androidAppId =
      '1:677273835452:android:7cf76bd04d4b98e0acfdb9';

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: androidApiKey,
    appId: androidAppId,
    messagingSenderId: messagingSenderId,
    projectId: projectId,
    storageBucket: storageBucket,
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: String.fromEnvironment(
      'FIREBASE_WEB_API_KEY',
      defaultValue: androidApiKey,
    ),
    appId: String.fromEnvironment(
      'FIREBASE_WEB_APP_ID',
      defaultValue: androidAppId,
    ),
    messagingSenderId: String.fromEnvironment(
      'FIREBASE_WEB_MESSAGING_SENDER_ID',
      defaultValue: '677273835452',
    ),
    projectId: String.fromEnvironment(
      'FIREBASE_WEB_PROJECT_ID',
      defaultValue: 'speedytrips-5b584',
    ),
    authDomain: String.fromEnvironment(
      'FIREBASE_WEB_AUTH_DOMAIN',
      defaultValue: 'speedytrips-5b584.firebaseapp.com',
    ),
    storageBucket: String.fromEnvironment(
      'FIREBASE_WEB_STORAGE_BUCKET',
      defaultValue: 'speedytrips-5b584.firebasestorage.app',
    ),
  );
}
