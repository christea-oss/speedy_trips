import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../models/user_role.dart';
import '../../services/auth_error_messages.dart';
import '../../services/auth_service.dart';
import '../driver/driver_home.dart';
import '../rider/rider_home.dart';

class RoleAuthScreen extends StatefulWidget {
  final UserRole role;
  final bool isSignup;

  const RoleAuthScreen({
    super.key,
    required this.role,
    required this.isSignup,
  });

  @override
  State<RoleAuthScreen> createState() => _RoleAuthScreenState();
}

class _RoleAuthScreenState extends State<RoleAuthScreen>
    with SingleTickerProviderStateMixin {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  late final AnimationController fadeController;
  late final Animation<double> fadeAnimation;
  bool isLoading = false;
  bool obscurePassword = true;

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
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!(formKey.currentState?.validate() ?? false)) return;

    setState(() {
      isLoading = true;
    });

    try {
      if (widget.isSignup) {
        await AuthService.instance.signUpWithEmail(
          email: emailController.text.trim(),
          password: passwordController.text,
          role: widget.role,
          name: nameController.text,
        );
      } else {
        await AuthService.instance.signInWithEmail(
          email: emailController.text.trim(),
          password: passwordController.text,
          role: widget.role,
        );
      }

      if (!mounted) return;

      showSuccess(
        widget.isSignup
            ? '${widget.role.label} account created successfully.'
            : '${widget.role.label} login successful.',
      );
      await Future<void>.delayed(const Duration(milliseconds: 450));
      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => homeForRole(widget.role)),
        (route) => false,
      );
    } on FirebaseAuthException catch (error) {
      showError(friendlyAuthError(error.code, message: error.message));
    } on FirebaseException catch (error) {
      showError(friendlyAuthError(error.code, message: error.message));
    } catch (error) {
      showError(friendlyUnexpectedAuthError(error));
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Widget homeForRole(UserRole role) {
    switch (role) {
      case UserRole.rider:
        return const RiderHome();
      case UserRole.driver:
        return const DriverHome();
    }
  }

  void showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void showSuccess(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final action = widget.isSignup ? 'Sign Up' : 'Log In';
    final title = '${widget.role.label} $action';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(title),
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
                constraints: const BoxConstraints(maxWidth: 520),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(22, 24, 22, 26),
                  decoration: BoxDecoration(
                    color: const Color(0xFF12100B),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.amber.withOpacity(.5)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withOpacity(.16),
                        blurRadius: 28,
                        offset: const Offset(0, 14),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(.62),
                        blurRadius: 34,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Image.asset(
                            'assets/logo.png',
                            height: 86,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.amber,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          widget.role == UserRole.rider
                              ? 'Book and manage SpeedyTrips rides.'
                              : 'Accept and manage SpeedyTrips ride requests.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 30),
                        if (widget.isSignup) ...[
                          _AuthTextField(
                            controller: nameController,
                            label: 'Name',
                            icon: Icons.person,
                            enabled: !isLoading,
                            validator: (value) {
                              if ((value ?? '').trim().isEmpty) {
                                return 'Enter your name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                        ],
                        _AuthTextField(
                          controller: emailController,
                          label: 'Email',
                          icon: Icons.email,
                          enabled: !isLoading,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            final email = (value ?? '').trim();
                            if (email.isEmpty || !email.contains('@')) {
                              return 'Enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _AuthTextField(
                          controller: passwordController,
                          label: 'Password',
                          icon: Icons.lock,
                          enabled: !isLoading,
                          obscureText: obscurePassword,
                          suffixIcon: IconButton(
                            color: Colors.white70,
                            onPressed: isLoading
                                ? null
                                : () {
                                    setState(() {
                                      obscurePassword = !obscurePassword;
                                    });
                                  },
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                          ),
                          validator: (value) {
                            if ((value ?? '').length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 26),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black,
                            disabledBackgroundColor:
                                Colors.amber.withOpacity(.72),
                            disabledForegroundColor: Colors.black87,
                            elevation: 10,
                            shadowColor: Colors.amber.withOpacity(.35),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: isLoading ? null : submit,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            child: isLoading
                                ? Row(
                                    key: const ValueKey('loading'),
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.black,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        widget.isSignup
                                            ? 'Creating account...'
                                            : 'Signing in...',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  )
                                : Text(
                                    action,
                                    key: const ValueKey('action'),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool enabled;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const _AuthTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.enabled = true,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.amber),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withOpacity(.08),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(.16)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.amber),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }
}
