import 'package:flutter/material.dart';

import '../../models/user_role.dart';
import 'role_auth_screen.dart';

class AdminLoginScreen extends StatelessWidget {
  const AdminLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoleAuthScreen(
      role: UserRole.admin,
      isSignup: false,
    );
  }
}
