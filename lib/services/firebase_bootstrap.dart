import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../firebase_options.dart';

class FirebaseBootstrap {
  FirebaseBootstrap._();

  static bool isEnabled = false;
  static Object? initializationError;

  static void disable(Object error) {
    initializationError = error;
    isEnabled = false;
  }

  static Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();

    final options = DefaultFirebaseOptions.currentPlatform;

    if (kIsWeb && options == null) {
      isEnabled = false;
      return;
    }

    try {
      await Firebase.initializeApp(options: options);
      if (kIsWeb) {
        await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
      }
      isEnabled = true;
    } catch (error) {
      disable(error);
    }
  }
}
