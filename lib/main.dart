import 'package:flutter/material.dart';

import 'screens/auth/auth_gate.dart';
import 'services/firebase_bootstrap.dart';

Future<void> main() async {
  await FirebaseBootstrap.initialize();
  runApp(const SpeedyTripsApp());
}

class SpeedyTripsApp extends StatelessWidget {
  const SpeedyTripsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthGate(),
    );
  }
}
