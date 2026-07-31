import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedy_trips/models/user_role.dart';
import 'package:speedy_trips/services/auth_service.dart';

import '../test/support/firebase_emulator_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  String? riderUid;
  String? driverUid;
  String? adminUid;

  setUpAll(() async {
    await initializeFirebaseEmulators();
    await clearFirebaseEmulators();
  });

  setUp(() async {
    riderUid = null;
    driverUid = null;
    adminUid = null;
    await signOutAndResetAuth();
  });

  tearDown(() async {
    for (final uid in [riderUid, driverUid, adminUid]) {
      if (uid != null) {
        await deleteDocIfExists(collection: 'users', documentId: uid);
      }
    }
    await signOutAndResetAuth();
  });

  tearDownAll(() async {
    await disposeFirebaseEmulators();
  });

  testWidgets('auth success, failure, and role resolution work', (
    tester,
  ) async {
    final rider = await createRoleFixture(
      role: UserRole.rider,
      displayName: 'Day 15 Rider',
    );
    riderUid = rider.user.uid;

    final riderProfile = await FirebaseFirestore.instance
        .collection('users')
        .doc(rider.user.uid)
        .get(const GetOptions(source: Source.server));

    expect(riderProfile.exists, isTrue);
    expect(riderProfile.data()?['uid'], rider.user.uid);
    expect(riderProfile.data()?['role'], UserRole.rider.id);

    await signOutAndResetAuth();

    final riderSignIn = await AuthService.instance.signInWithEmail(
      email: rider.user.email!,
      password: kTestPassword,
      role: UserRole.rider,
    );
    expect(riderSignIn.role, UserRole.rider);
    expect((await AuthService.instance.currentSession())?.role, UserRole.rider);

    await expectLater(
      AuthService.instance.signInWithEmail(
        email: rider.user.email!,
        password: 'wrong-password',
        role: UserRole.rider,
      ),
      throwsA(isA<FirebaseAuthException>()),
    );

    await signOutAndResetAuth();

    final driver = await createRoleFixture(
      role: UserRole.driver,
      displayName: 'Day 15 Driver',
    );
    driverUid = driver.user.uid;

    final admin = await createRoleFixture(
      role: UserRole.admin,
      displayName: 'Day 15 Admin',
    );
    adminUid = admin.user.uid;

    expect(
      await AuthService.instance.roleForUser(driver.user.uid),
      UserRole.driver,
    );
    expect(
      await AuthService.instance.roleForUser(admin.user.uid),
      UserRole.admin,
    );
  });

  testWidgets('unauthorized profile access is denied', (tester) async {
    final rider = await createRoleFixture(
      role: UserRole.rider,
      displayName: 'Profile Rider',
    );
    riderUid = rider.user.uid;

    final driver = await createRoleFixture(
      role: UserRole.driver,
      displayName: 'Profile Driver',
    );
    driverUid = driver.user.uid;

    await signOutAndResetAuth();
    await AuthService.instance.signInWithEmail(
      email: rider.user.email!,
      password: kTestPassword,
      role: UserRole.rider,
    );

    await expectLater(
      FirebaseFirestore.instance
          .collection('users')
          .doc(driver.user.uid)
          .get(const GetOptions(source: Source.server)),
      throwsA(
        isA<FirebaseException>().having(
          (error) => error.code,
          'code',
          'permission-denied',
        ),
      ),
    );
  });
}
