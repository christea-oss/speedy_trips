import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';
import '../models/ride.dart';
import '../models/user_role.dart';
import '../services/firebase_bootstrap.dart';
import 'ride_repository.dart';

class AdminRepository {
  AdminRepository._();

  static final AdminRepository instance = AdminRepository._();

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users {
    return _firestore.collection('users');
  }

  Stream<List<Ride>> watchAllRides() {
    return RideRepository.instance.watchRides();
  }

  Stream<List<AppUser>> watchDrivers() {
    if (!FirebaseBootstrap.isEnabled) {
      return Stream.value(const <AppUser>[]);
    }

    return _users
        .where('role', isEqualTo: UserRole.driver.id)
        .snapshots()
        .map((snapshot) {
      final drivers = snapshot.docs.map(_userFromSnapshot).toList()
        ..sort((a, b) {
          final nameCompare = a.displayName
              .toLowerCase()
              .compareTo(b.displayName.toLowerCase());
          if (nameCompare != 0) return nameCompare;
          return a.email.toLowerCase().compareTo(b.email.toLowerCase());
        });

      return drivers;
    });
  }

  AppUser _userFromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? <String, dynamic>{};
    final roleId = data['role'] as String? ?? UserRole.driver.id;

    return AppUser(
      uid: data['uid'] as String? ?? snapshot.id,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      role: userRoleFromId(roleId),
      createdAt: _dateTimeFromFirestore(data['createdAt']),
      updatedAt: _dateTimeFromFirestore(data['updatedAt']),
    );
  }

  DateTime? _dateTimeFromFirestore(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }
}
