import 'package:firebase_auth/firebase_auth.dart';

import 'user_role.dart';

class AuthSession {
  final User user;
  final UserRole role;

  const AuthSession({
    required this.user,
    required this.role,
  });
}
