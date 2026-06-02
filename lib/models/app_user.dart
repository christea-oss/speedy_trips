import 'user_role.dart';

class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final UserRole role;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    this.createdAt,
    this.updatedAt,
  });
}
