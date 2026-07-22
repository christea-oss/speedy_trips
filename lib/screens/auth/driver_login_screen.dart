import 'package:flutter/material.dart';

import '../../models/user_role.dart';
import 'role_auth_screen.dart';

class DriverLoginScreen extends StatelessWidget {
  const DriverLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoleAuthScreen(role: UserRole.driver, isSignup: false);
  }
}
