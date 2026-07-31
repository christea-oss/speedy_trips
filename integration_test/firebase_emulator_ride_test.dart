import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedy_trips/models/ride_status.dart';
import 'package:speedy_trips/models/user_role.dart';
import 'package:speedy_trips/models/vehicle_type.dart';
import 'package:speedy_trips/repositories/ride_repository.dart';
import 'package:speedy_trips/services/auth_service.dart';

import '../test/support/firebase_emulator_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  String? riderUid;
  String? rideId;

  setUpAll(() async {
    await initializeFirebaseEmulators();
    await clearFirebaseEmulators();
  });

  setUp(() async {
    riderUid = null;
    rideId = null;
    await signOutAndResetAuth();
  });

  tearDown(() async {
    if (riderUid != null) {
      await deleteDocIfExists(collection: 'users', documentId: riderUid!);
    }
    if (rideId != null) {
      await deleteDocIfExists(collection: 'rides', documentId: rideId!);
    }
    await signOutAndResetAuth();
  });

  tearDownAll(() async {
    await disposeFirebaseEmulators();
  });

  testWidgets('ride document creation and scheduled ride persistence work', (
    tester,
  ) async {
    final rider = await createRoleFixture(
      role: UserRole.rider,
      displayName: 'Ride Rider',
    );
    riderUid = rider.user.uid;

    await signOutAndResetAuth();
    await AuthService.instance.signInWithEmail(
      email: rider.user.email!,
      password: kTestPassword,
      role: UserRole.rider,
    );

    final ride = await RideRepository.instance.createRide(
      pickupLocation: 'BHM Airport E2E Pickup',
      dropoffLocation: 'Downtown Birmingham E2E Dropoff',
      zone: 'Zone 1 - Central Birmingham',
      vehicleType: VehicleType.blackSuv,
      rideType: 'Scheduled Ride',
      fare: 52,
      scheduledDate: DateTime(2026, 5, 26),
      scheduledTime: const TimeOfDay(hour: 14, minute: 30),
    );
    rideId = ride.id;

    final snapshot = await FirebaseFirestore.instance
        .collection('rides')
        .doc(ride.id)
        .get(const GetOptions(source: Source.server));

    expect(snapshot.exists, isTrue);
    expect(snapshot.data()?['riderId'], rider.user.uid);
    expect(snapshot.data()?['rideType'], 'Scheduled Ride');
    expect(snapshot.data()?['status'], RideStatus.pending.id);
    expect(snapshot.data()?['scheduledDate'], isA<Timestamp>());
    expect(snapshot.data()?['scheduledTime'], {'hour': 14, 'minute': 30});
    expect(snapshot.data()?['scheduledDateTime'], isA<Timestamp>());
  });

  testWidgets('ride retrieval and status updates are persisted', (
    tester,
  ) async {
    final rider = await createRoleFixture(
      role: UserRole.rider,
      displayName: 'Status Rider',
    );
    riderUid = rider.user.uid;

    await signOutAndResetAuth();
    await AuthService.instance.signInWithEmail(
      email: rider.user.email!,
      password: kTestPassword,
      role: UserRole.rider,
    );

    final createdRide = await RideRepository.instance.createRide(
      pickupLocation: 'Pickup',
      dropoffLocation: 'Dropoff',
      zone: 'Zone 2 - South Metro',
      vehicleType: VehicleType.blackRide,
      rideType: 'Ride Now',
      fare: 35,
    );
    rideId = createdRide.id;

    final snapshot = await FirebaseFirestore.instance
        .collection('rides')
        .doc(createdRide.id)
        .get(const GetOptions(source: Source.server));

    expect(snapshot.exists, isTrue);
    expect(snapshot.data()?['riderId'], rider.user.uid);
    expect(snapshot.data()?['status'], RideStatus.pending.id);

    final updatedRide = await RideRepository.instance.cancelRide(
      createdRide.id,
    );
    expect(updatedRide.status, RideStatus.cancelled);

    final updatedSnapshot = await FirebaseFirestore.instance
        .collection('rides')
        .doc(createdRide.id)
        .get(const GetOptions(source: Source.server));

    expect(updatedSnapshot.exists, isTrue);
    expect(updatedSnapshot.data()?['riderId'], rider.user.uid);
    expect(updatedSnapshot.data()?['status'], RideStatus.cancelled.id);
  });
}
