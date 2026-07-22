import 'package:flutter/material.dart';

import 'admin_login_screen.dart';
import 'driver_login_screen.dart';
import 'driver_signup_screen.dart';
import 'rider_login_screen.dart';
import 'rider_signup_screen.dart';

class RoleSelectionScreen extends StatefulWidget {
  final String? message;

  const RoleSelectionScreen({super.key, this.message});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController fadeController;
  late final Animation<double> fadeAnimation;

  @override
  void initState() {
    super.initState();
    fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    fadeAnimation = CurvedAnimation(
      parent: fadeController,
      curve: Curves.easeOutCubic,
    );
    fadeController.forward();
  }

  @override
  void dispose() {
    fadeController.dispose();
    super.dispose();
  }

  void open(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('SpeedyTrips'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.amber,
        elevation: 0,
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 44),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final useWideCards = constraints.maxWidth >= 760;

                    final cards = [
                      _RoleCard(
                        title: 'Rider',
                        subtitle:
                            'Book now, schedule rides, and view ride history.',
                        icon: Icons.person_pin_circle,
                        primaryLabel: 'Rider Login',
                        secondaryLabel: 'Create Rider Account',
                        onPrimary: () =>
                            open(context, const RiderLoginScreen()),
                        onSecondary: () =>
                            open(context, const RiderSignupScreen()),
                      ),
                      _RoleCard(
                        title: 'Driver',
                        subtitle:
                            'Go online, accept rides, and complete trips.',
                        icon: Icons.local_taxi,
                        primaryLabel: 'Driver Login',
                        secondaryLabel: 'Create Driver Account',
                        onPrimary: () =>
                            open(context, const DriverLoginScreen()),
                        onSecondary: () =>
                            open(context, const DriverSignupScreen()),
                      ),
                      _RoleCard(
                        title: 'Admin',
                        subtitle:
                            'Review rides, drivers, statuses, and operations.',
                        icon: Icons.admin_panel_settings,
                        primaryLabel: 'Admin Login',
                        onPrimary: () =>
                            open(context, const AdminLoginScreen()),
                      ),
                    ];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),
                        Center(
                          child: Image.asset(
                            'assets/logo.png',
                            height: 96,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 22),
                        const Text(
                          'Welcome to SpeedyTrips',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.amber,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Choose your account type to continue.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        if (widget.message != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            widget.message!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.orangeAccent),
                          ),
                        ],
                        const SizedBox(height: 36),
                        if (useWideCards)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: cards[0]),
                              const SizedBox(width: 20),
                              Expanded(child: cards[1]),
                              const SizedBox(width: 20),
                              Expanded(child: cards[2]),
                            ],
                          )
                        else
                          Column(
                            children: [
                              cards[0],
                              const SizedBox(height: 18),
                              cards[1],
                              const SizedBox(height: 18),
                              cards[2],
                            ],
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String primaryLabel;
  final String? secondaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback? onSecondary;

  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.primaryLabel,
    this.secondaryLabel,
    required this.onPrimary,
    this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF12100B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withAlpha((.55 * 255).round())),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withAlpha((.18 * 255).round()),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: Colors.black.withAlpha((.55 * 255).round()),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                height: 54,
                width: 54,
                decoration: BoxDecoration(
                  color: Colors.amber.withAlpha((.14 * 255).round()),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.amber.withAlpha((.4 * 255).round()),
                  ),
                ),
                child: Icon(icon, color: Colors.amber, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              elevation: 10,
              shadowColor: Colors.amber.withAlpha((.35 * 255).round()),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: onPrimary,
            child: Text(
              primaryLabel,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          if (secondaryLabel != null && onSecondary != null) ...[
            const SizedBox(height: 10),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(
                  color: Colors.amber.withAlpha((.7 * 255).round()),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: onSecondary,
              child: Text(secondaryLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
