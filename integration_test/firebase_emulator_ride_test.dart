import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:speedy_trips/models/ride_status.dart';
import 'package:speedy_trips/models/user_role.dart';
import 'package:speedy_trips/models/vehicle_type.dart';
import 'package:speedy_trips/repositories/ride_repository.dart';
import 'package:speedy_trips/services/auth_service.dart';

import 'test_support/firebase_emulator_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  String? riderUid;
  String? driverUid;
  String? adminUid;
  String? rideId;

  setUpAll(() async {
    await initializeFirebaseEmulators();
  });

  setUp(() async {
    riderUid = null;
    driverUid = null;
    adminUid = null;
    rideId = null;
    await signOutAndResetAuth();
  });

  tearDown(() async {
    for (final uid in [riderUid, driverUid, adminUid]) {
      if (uid != null) {
        await deleteDocIfExists(collection: 'users', documentId: uid);
      }
    }

    if (rideId != null) {
      await deleteDocIfExists(collection: 'rides', documentId: rideId!);
    }

    await signOutAndResetAuth();
  });

  testWidgets('ride document creation and scheduled ride persistence work', (
    tester,
  ) async {
    final rider = await createRoleFixture(
      role: UserRole.rider,
      displayName: 'Ride Rider',
    );
    riderUid = rider.user.uid;

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

  testWidgets('ride status updates are persisted through completion', (
    tester,
  ) async {
    final rider = await createRoleFixture(
      role: UserRole.rider,
      displayName: 'Status Rider',
    );
    riderUid = rider.user.uid;

    final driver = await createRoleFixture(
      role: UserRole.driver,
      displayName: 'Status Driver',
    );
    driverUid = driver.user.uid;

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

    await signOutAndResetAuth();
    await AuthService.instance.signInWithEmail(
      email: driver.user.email!,
      password: kTestPassword,
      role: UserRole.driver,
    );

    expect(
      (await RideRepository.instance.acceptRide(createdRide.id)).status,
      RideStatus.accepted,
    );
    expect(
      (await RideRepository.instance.updateRideStatus(
        rideId: createdRide.id,
        status: RideStatus.arriving,
      )).status,
      RideStatus.arriving,
    );
    expect(
      (await RideRepository.instance.updateRideStatus(
        rideId: createdRide.id,
        status: RideStatus.inProgress,
      )).status,
      RideStatus.inProgress,
    );
    expect(
      (await RideRepository.instance.updateRideStatus(
        rideId: createdRide.id,
        status: RideStatus.completed,
      )).status,
      RideStatus.completed,
    );

    final snapshot = await FirebaseFirestore.instance
        .collection('rides')
        .doc(createdRide.id)
        .get(const GetOptions(source: Source.server));

    expect(snapshot.data()?['assignedDriver'], driver.user.uid);
    expect(snapshot.data()?['status'], RideStatus.completed.id);
  });

  testWidgets('authenticated users can access only allowed Firestore data', (
    tester,
  ) async {
    final driver = await createRoleFixture(
      role: UserRole.driver,
      displayName: 'Query Driver',
    );
    driverUid = driver.user.uid;

    final admin = await createRoleFixture(
      role: UserRole.admin,
      displayName: 'Query Admin',
    );
    adminUid = admin.user.uid;

    await signOutAndResetAuth();
    await AuthService.instance.signInWithEmail(
      email: admin.user.email!,
      password: kTestPassword,
      role: UserRole.admin,
    );

    final driverProfile = await FirebaseFirestore.instance
        .collection('users')
        .doc(driver.user.uid)
        .get(const GetOptions(source: Source.server));

    expect(driverProfile.exists, isTrue);
    expect(driverProfile.data()?['role'], UserRole.driver.id);

    final driverQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: UserRole.driver.id)
        .get(const GetOptions(source: Source.server));

    expect(driverQuery.docs, isNotEmpty);
    expect(driverQuery.docs.first.id, driver.user.uid);
  });
}
