import 'package:flutter/material.dart';

import '../../models/user_role.dart';
import 'role_auth_screen.dart';

class RiderLoginScreen extends StatelessWidget {
  const RiderLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoleAuthScreen(
      role: UserRole.rider,
      isSignup: false,
    );
  }
}
