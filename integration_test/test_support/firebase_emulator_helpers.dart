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

Future<void> initializeFirebaseEmulators() async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.web);
  }

  FirebaseBootstrap.isEnabled = true;
  FirebaseBootstrap.initializationError = null;

  FirebaseAuth.instance.useAuthEmulator(kEmulatorHost, kAuthEmulatorPort);
  FirebaseFirestore.instance.useFirestoreEmulator(
    kEmulatorHost,
    kFirestoreEmulatorPort,
  );
}

Future<AuthSession> createRoleFixture({
  required UserRole role,
  required String displayName,
  String? emailPrefix,
}) async {
  final suffix = DateTime.now().microsecondsSinceEpoch;
  final prefix = emailPrefix ?? 'day15.${role.id}';
  final email = '$prefix.$suffix@example.test';

  return AuthService.instance.signUpWithEmail(
    email: email,
    password: kTestPassword,
    role: role,
    name: displayName,
  );
}

Future<void> signOutAndResetAuth() async {
  await AuthService.instance.signOut();
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
