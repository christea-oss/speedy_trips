import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../models/auth_session.dart';
import '../../models/user_role.dart';
import '../../services/auth_error_messages.dart';
import '../../services/auth_service.dart';
import '../../services/firebase_bootstrap.dart';
import '../admin/admin_dashboard.dart';
import '../driver/driver_home.dart';
import '../rider/rider_home.dart';
import 'role_selection_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    if (!FirebaseBootstrap.isEnabled) {
      return const RoleSelectionScreen(
        message: 'Firebase authentication is not configured on this platform.',
      );
    }

    return StreamBuilder(
      stream: AuthService.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _AuthLoadingScreen();
        }

        return FutureBuilder<AuthSession?>(
          future: AuthService.instance.currentSession(),
          builder: (context, sessionSnapshot) {
            if (sessionSnapshot.connectionState == ConnectionState.waiting) {
              return const _AuthLoadingScreen();
            }

            if (sessionSnapshot.hasError) {
              return RoleSelectionScreen(
                message: authRestoreErrorMessage(sessionSnapshot.error!),
              );
            }

            final session = sessionSnapshot.data;
            if (session == null) {
              return const RoleSelectionScreen();
            }

            switch (session.role) {
              case UserRole.rider:
                return const RiderHome();
              case UserRole.driver:
                return const DriverHome();
              case UserRole.admin:
                return const AdminDashboard();
            }
          },
        );
      },
    );
  }

  String authRestoreErrorMessage(Object error) {
    if (error is FirebaseAuthException) {
      return friendlyAuthError(error.code, message: error.message);
    }

    if (error is FirebaseException) {
      return friendlyAuthError(error.code, message: error.message);
    }

    return friendlyUnexpectedAuthError(error);
  }
}

class _AuthLoadingScreen extends StatelessWidget {
  const _AuthLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: CircularProgressIndicator(color: Colors.amber),
      ),
    );
  }
}
