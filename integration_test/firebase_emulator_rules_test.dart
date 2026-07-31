import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedy_trips/models/user_role.dart';
import 'package:speedy_trips/services/auth_service.dart';

import '../test/support/firebase_emulator_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  String? riderUid;

  setUpAll(() async {
    await initializeFirebaseEmulators();
    await clearFirebaseEmulators();
  });

  setUp(() async {
    riderUid = null;
    await signOutAndResetAuth();
  });

  tearDown(() async {
    if (riderUid != null) {
      await deleteDocIfExists(collection: 'users', documentId: riderUid!);
    }
    await signOutAndResetAuth();
  });

  tearDownAll(() async {
    await disposeFirebaseEmulators();
  });

  testWidgets('non-user collections remain denied', (tester) async {
    final rider = await createRoleFixture(
      role: UserRole.rider,
      displayName: 'Deny Rider',
    );
    riderUid = rider.user.uid;

    await signOutAndResetAuth();
    await AuthService.instance.signInWithEmail(
      email: rider.user.email!,
      password: kTestPassword,
      role: UserRole.rider,
    );

    await expectLater(
      FirebaseFirestore.instance.collection('misc').doc('blocked').get(),
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
