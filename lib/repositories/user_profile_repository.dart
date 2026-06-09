import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/firebase_bootstrap.dart';

class UserProfileRepository {
  UserProfileRepository._();

  static final UserProfileRepository instance = UserProfileRepository._();

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users {
    return _firestore.collection('users');
  }

  Future<String> displayNameForUser(
    String? uid, {
    required String fallback,
  }) async {
    if (uid == null || uid.isEmpty) {
      return fallback;
    }

    if (!FirebaseBootstrap.isEnabled) {
      return uid;
    }

    try {
      final snapshot = await _users.doc(uid).get();
      final data = snapshot.data() ?? <String, dynamic>{};
      final displayName = data['displayName'] as String?;
      final email = data['email'] as String?;

      if (displayName != null && displayName.trim().isNotEmpty) {
        return displayName.trim();
      }

      if (email != null && email.trim().isNotEmpty) {
        return email.trim();
      }

      return uid;
    } on FirebaseException {
      return uid;
    }
  }
}
