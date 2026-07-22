import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:speedy_trips/models/ride_status.dart';
import 'package:speedy_trips/models/user_role.dart';
import 'package:speedy_trips/models/vehicle_type.dart';
import 'package:speedy_trips/repositories/ride_repository.dart';
import 'package:speedy_trips/services/auth_service.dart';
import 'package:speedy_trips/services/firebase_bootstrap.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late FirebaseAuth auth;
  late FirebaseFirestore firestore;
  late String email;
  String? cleanupRideId;
  String? cleanupUserUid;
  const password = 'SpeedyTripsTest123!';
  const displayName = 'SpeedyTrips E2E Rider';

  setUpAll(() async {
    await FirebaseBootstrap.initialize();

    expect(
      FirebaseBootstrap.isEnabled,
      isTrue,
      reason:
          'Firebase must initialize before end-to-end auth and ride tests run. '
          'Check firebase_options.dart and google-services.json.',
    );

    auth = FirebaseAuth.instance;
    firestore = FirebaseFirestore.instance;
  });

  setUp(() async {
    email =
        'speedytrips.e2e.${DateTime.now().microsecondsSinceEpoch}'
        '@example.com';
    cleanupRideId = null;
    cleanupUserUid = null;
    await auth.signOut();
  });

  tearDown(() async {
    await _signInForCleanup(
      auth: auth,
      email: email,
      password: password,
      uid: cleanupUserUid,
    );
    await _deleteDocument(
      firestore: firestore,
      collection: 'rides',
      documentId: cleanupRideId,
    );
    await _deleteDocument(
      firestore: firestore,
      collection: 'users',
      documentId: cleanupUserUid,
    );
    await _deleteCurrentFirebaseUser(auth);
  });

  testWidgets(
    'Firebase Auth sign-up, sign-in, role profile, and ride persistence work',
    (_) async {
      final signUpSession = await AuthService.instance.signUpWithEmail(
        email: email,
        password: password,
        role: UserRole.rider,
        name: displayName,
      );

      expect(signUpSession.role, UserRole.rider);
      expect(signUpSession.user.email, email);
      await signUpSession.user.reload();
      expect(auth.currentUser?.displayName, displayName);

      final uid = signUpSession.user.uid;
      cleanupUserUid = uid;

      final profile = await firestore.collection('users').doc(uid).get();
      expect(profile.exists, isTrue);
      expect(profile.data()?['uid'], uid);
      expect(profile.data()?['email'], email);
      expect(profile.data()?['displayName'], displayName);
      expect(profile.data()?['role'], UserRole.rider.id);

      await AuthService.instance.signOut();
      expect(auth.currentUser, isNull);

      final signInSession = await AuthService.instance.signInWithEmail(
        email: email,
        password: password,
        role: UserRole.rider,
      );

      expect(signInSession.user.uid, uid);
      expect(signInSession.role, UserRole.rider);

      await expectLater(
        AuthService.instance.signInWithEmail(
          email: email,
          password: password,
          role: UserRole.driver,
        ),
        throwsA(
          isA<FirebaseAuthException>().having(
            (error) => error.code,
            'code',
            'role-mismatch',
          ),
        ),
      );

      final riderSession = await AuthService.instance.signInWithEmail(
        email: email,
        password: password,
        role: UserRole.rider,
      );
      expect(riderSession.user.uid, uid);

      final scheduledDate = DateTime(2026, 5, 26);
      const scheduledTime = TimeOfDay(hour: 14, minute: 30);
      final createdRide = await RideRepository.instance.createRide(
        pickupLocation: 'BHM Airport E2E Pickup',
        dropoffLocation: 'Downtown Birmingham E2E Dropoff',
        zone: 'Zone 1 - Central Birmingham',
        vehicleType: VehicleType.blackSuv,
        rideType: 'Scheduled Ride',
        fare: 52,
        scheduledDate: scheduledDate,
        scheduledTime: scheduledTime,
      );
      cleanupRideId = createdRide.id;

      expect(createdRide.status, RideStatus.pending);

      final savedRide = await firestore
          .collection('rides')
          .doc(createdRide.id)
          .get(const GetOptions(source: Source.server));
      final savedRideData = savedRide.data();

      expect(savedRide.exists, isTrue);
      expect(savedRideData?['pickupLocation'], 'BHM Airport E2E Pickup');
      expect(
        savedRideData?['dropoffLocation'],
        'Downtown Birmingham E2E Dropoff',
      );
      expect(savedRideData?['zone'], 'Zone 1 - Central Birmingham');
      expect(savedRideData?['vehicleType'], VehicleType.blackSuv.id);
      expect(savedRideData?['rideType'], 'Scheduled Ride');
      expect(savedRideData?['fare'], 52);
      expect(savedRideData?['status'], RideStatus.pending.id);
      expect(savedRideData?['riderId'], uid);
      expect(savedRideData?['riderUid'], uid);
      expect(savedRideData?['createdAt'], isA<Timestamp>());
      expect(savedRideData?['scheduledDate'], isA<Timestamp>());
      expect(savedRideData?['scheduledTime'], {
        'hour': scheduledTime.hour,
        'minute': scheduledTime.minute,
      });

      final updatedRide = await RideRepository.instance.updateRideStatus(
        rideId: createdRide.id,
        status: RideStatus.accepted,
      );

      expect(updatedRide.status, RideStatus.accepted);

      final updatedRideSnapshot = await firestore
          .collection('rides')
          .doc(createdRide.id)
          .get(const GetOptions(source: Source.server));

      expect(updatedRideSnapshot.data()?['status'], RideStatus.accepted.id);
      expect(updatedRideSnapshot.data()?['updatedAt'], isA<Timestamp>());
    },
  );
}

Future<void> _signInForCleanup({
  required FirebaseAuth auth,
  required String email,
  required String password,
  required String? uid,
}) async {
  if (auth.currentUser != null &&
      (uid == null || auth.currentUser?.uid == uid)) {
    return;
  }

  try {
    await auth.signInWithEmailAndPassword(email: email, password: password);
  } on FirebaseAuthException {
    // If the test failed before creating the user, there is nothing to clean up.
  }
}

Future<void> _deleteDocument({
  required FirebaseFirestore firestore,
  required String collection,
  required String? documentId,
}) async {
  if (documentId == null) return;

  try {
    await firestore.collection(collection).doc(documentId).delete();
  } on FirebaseException {
    // Cleanup should not hide the original test failure.
  }
}

Future<void> _deleteCurrentFirebaseUser(FirebaseAuth auth) async {
  final user = auth.currentUser;
  if (user == null) return;

  try {
    await user.delete();
  } on FirebaseAuthException catch (error) {
    if (error.code != 'requires-recent-login') {
      rethrow;
    }
  } finally {
    await auth.signOut();
  }
}
