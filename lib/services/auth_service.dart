import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/auth_session.dart';
import '../models/user_role.dart';
import 'firebase_bootstrap.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users {
    return _firestore.collection('users');
  }

  User? get currentUser => _auth.currentUser;

  Stream<User?> authStateChanges() {
    if (!FirebaseBootstrap.isEnabled) {
      return Stream.value(null);
    }

    return _auth.authStateChanges();
  }

  Future<AuthSession?> currentSession() async {
    if (!FirebaseBootstrap.isEnabled) {
      return null;
    }

    final user = currentUser;
    if (user == null || user.isAnonymous) {
      if (user?.isAnonymous ?? false) {
        await signOut();
      }
      return null;
    }

    final role = await roleForUser(user.uid);
    if (role == null) {
      await signOut();
      return null;
    }

    return AuthSession(user: user, role: role);
  }

  Future<UserRole?> roleForUser(String uid) async {
    try {
      final snapshot = await _users.doc(uid).get();
      final roleId = snapshot.data()?['role'] as String?;
      if (roleId == null) return null;

      return userRoleFromId(roleId);
    } on ArgumentError catch (error) {
      throw FirebaseAuthException(
        code: 'invalid-user-role',
        message: error.message?.toString() ?? 'Unknown SpeedyTrips role.',
      );
    } on FirebaseException catch (error) {
      throw FirebaseAuthException(
        code: _profileReadErrorCode(error),
        message: error.message,
      );
    }
  }

  Future<AuthSession> signUpWithEmail({
    required String email,
    required String password,
    required UserRole role,
    String? name,
  }) async {
    _checkFirebaseEnabled();
    await _signOutAnonymousUser();

    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'missing-user',
        message: 'Firebase did not return a signed-in user.',
      );
    }

    final cleanName = name?.trim();
    if (cleanName != null && cleanName.isNotEmpty) {
      await user.updateDisplayName(cleanName);
    }

    try {
      await _saveUserProfile(
        user: user,
        role: role,
        displayName: cleanName,
        includeCreatedAt: true,
      );
    } on FirebaseAuthException {
      await signOut();
      rethrow;
    }

    return AuthSession(user: user, role: role);
  }

  Future<AuthSession> signInWithEmail({
    required String email,
    required String password,
    required UserRole role,
    bool createProfileIfMissing = true,
  }) async {
    _checkFirebaseEnabled();
    await _signOutAnonymousUser();

    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'missing-user',
        message: 'Firebase did not return a signed-in user.',
      );
    }

    final savedRole = await roleForUser(user.uid);
    if (savedRole == null) {
      if (!createProfileIfMissing) {
        await signOut();
        throw FirebaseAuthException(
          code: 'missing-user-role',
          message: 'This account is not registered as a ${role.label}.',
        );
      }

      await _saveUserProfile(
        user: user,
        role: role,
        displayName: user.displayName,
        includeCreatedAt: true,
      );
      return AuthSession(user: user, role: role);
    }

    if (savedRole != role) {
      await signOut();
      throw FirebaseAuthException(
        code: 'role-mismatch',
        message: 'This account is registered as a ${savedRole.label}.',
      );
    }

    return AuthSession(user: user, role: savedRole);
  }

  Future<void> signOut() async {
    if (!FirebaseBootstrap.isEnabled) return;

    await _auth.signOut();
  }

  Future<void> _signOutAnonymousUser() async {
    if (_auth.currentUser?.isAnonymous ?? false) {
      await _auth.signOut();
    }
  }

  Future<void> _saveUserProfile({
    required User user,
    required UserRole role,
    required String? displayName,
    required bool includeCreatedAt,
  }) async {
    try {
      final data = <String, dynamic>{
        'uid': user.uid,
        'email': user.email,
        'displayName': displayName,
        'role': role.id,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (includeCreatedAt) {
        data['createdAt'] = FieldValue.serverTimestamp();
      }

      await _users.doc(user.uid).set(data, SetOptions(merge: true));
    } on FirebaseException catch (error) {
      throw FirebaseAuthException(
        code: _profileWriteErrorCode(error),
        message: error.message,
      );
    }
  }

  String _profileReadErrorCode(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return 'profile-read-permission-denied';
      case 'unavailable':
        return 'profile-read-unavailable';
      default:
        return 'profile-read-failed';
    }
  }

  String _profileWriteErrorCode(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return 'profile-write-permission-denied';
      case 'unavailable':
        return 'profile-write-unavailable';
      default:
        return 'profile-write-failed';
    }
  }

  void _checkFirebaseEnabled() {
    if (!FirebaseBootstrap.isEnabled) {
      throw FirebaseAuthException(
        code: 'firebase-unavailable',
        message: 'Firebase is not configured for this platform.',
      );
    }
  }
}
