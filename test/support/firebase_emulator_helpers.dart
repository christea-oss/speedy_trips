import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:speedy_trips/firebase_options.dart';
import 'package:speedy_trips/models/auth_session.dart';
import 'package:speedy_trips/models/user_role.dart';
import 'package:speedy_trips/services/auth_service.dart';
import 'package:speedy_trips/services/firebase_bootstrap.dart';

const String kEmulatorHost = '127.0.0.1';
const int kAuthEmulatorPort = 9099;
const int kFirestoreEmulatorPort = 8080;
const String kTestPassword = 'SpeedyTripsTest123!';
const bool runEmulatorTests = bool.fromEnvironment(
  'RUN_EMULATOR_TESTS',
  defaultValue: true,
);

bool _firebaseInitialized = false;
int _emailNonce = 0;

Future<void> initializeFirebaseEmulators() async {
  if (!_firebaseInitialized) {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.web);
    }
    _firebaseInitialized = true;
  }

  FirebaseBootstrap.isEnabled = true;
  FirebaseBootstrap.initializationError = null;

  FirebaseAuth.instance.useAuthEmulator(kEmulatorHost, kAuthEmulatorPort);
  FirebaseFirestore.instance.useFirestoreEmulator(
    kEmulatorHost,
    kFirestoreEmulatorPort,
  );

  await waitForFirebaseEmulators();
}

Future<void> waitForFirebaseEmulators() async {
  final client = HttpClient();
  try {
    await _waitForUri(
      client,
      Uri.parse(
        'http://$kEmulatorHost:$kAuthEmulatorPort/emulator/v1/projects/${DefaultFirebaseOptions.projectId}/config',
      ),
    );
    await _waitForUri(
      client,
      Uri.parse(
        'http://$kEmulatorHost:$kFirestoreEmulatorPort/emulator/v1/projects/${DefaultFirebaseOptions.projectId}/databases/(default)/documents',
      ),
    );
  } finally {
    client.close(force: true);
  }
}

Future<void> clearFirebaseEmulators() async {
  await signOutAndResetAuth();
  await _deleteAuthEmulatorAccounts();
  await _deleteFirestoreEmulatorData();
  _emailNonce = 0;
}

Future<void> disposeFirebaseEmulators() async {
  await signOutAndResetAuth();
  for (final app in Firebase.apps.toList()) {
    try {
      await app.delete();
    } catch (_) {
      // Best-effort cleanup only.
    }
  }
  _firebaseInitialized = false;
}

Future<AuthSession> createRoleFixture({
  required UserRole role,
  required String displayName,
  String? emailPrefix,
}) async {
  final uniqueEmail = _nextTestEmail(prefix: emailPrefix ?? 'day15.${role.id}');

  return AuthService.instance.signUpWithEmail(
    email: uniqueEmail,
    password: kTestPassword,
    role: role,
    name: displayName,
  );
}

String _nextTestEmail({required String prefix}) {
  final nonce = DateTime.now().microsecondsSinceEpoch + (_emailNonce++);
  return '$prefix.$nonce@test.speedytrips.local';
}

Future<void> signOutAndResetAuth() async {
  try {
    await AuthService.instance.signOut();
  } catch (_) {
    // Ignore emulator teardown cleanup errors.
  }
}

Future<void> deleteDocIfExists({
  required String collection,
  required String documentId,
}) async {
  try {
    await FirebaseFirestore.instance
        .collection(collection)
        .doc(documentId)
        .delete();
  } on FirebaseException {
    // Cleanup should never obscure the actual test failure.
  }
}

Future<void> _deleteAuthEmulatorAccounts() async {
  final uri = Uri.parse(
    'http://$kEmulatorHost:$kAuthEmulatorPort/emulator/v1/projects/${DefaultFirebaseOptions.projectId}/accounts',
  );
  await _deleteUri(uri);
}

Future<void> _deleteFirestoreEmulatorData() async {
  final uri = Uri.parse(
    'http://$kEmulatorHost:$kFirestoreEmulatorPort/emulator/v1/projects/${DefaultFirebaseOptions.projectId}/databases/(default)/documents',
  );
  await _deleteUri(uri);
}

Future<void> _deleteUri(Uri uri) async {
  final client = HttpClient();
  try {
    final request = await client
        .deleteUrl(uri)
        .timeout(const Duration(seconds: 10));
    final response = await request.close().timeout(const Duration(seconds: 10));
    await response.drain();
  } catch (_) {
    // Best-effort cleanup only.
  } finally {
    client.close(force: true);
  }
}

Future<void> _waitForUri(HttpClient client, Uri uri) async {
  for (var attempt = 0; attempt < 30; attempt++) {
    try {
      final request = await client
          .getUrl(uri)
          .timeout(const Duration(seconds: 2));
      final response = await request.close().timeout(
        const Duration(seconds: 2),
      );
      await response.drain();
      return;
    } catch (_) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
  }
}
