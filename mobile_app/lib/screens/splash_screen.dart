import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'admin/admin_dashboard.dart';
import 'employee/employee_dashboard.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _routeAfterDelay();
  }

  Future<void> _routeAfterDelay() async {
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final auth = context.read<AuthProvider>();
    while (auth.isInitializing) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
    }

    if (!mounted) return;
    final user = auth.user;
    final next = auth.isAuthenticated && user?.isAdmin == true
        ? const AdminDashboard()
        : auth.isAuthenticated && user?.isEmployee == true
            ? const EmployeeDashboard()
            : const LoginScreen();

    unawaited(Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => next)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.background, AppTheme.secondary],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Hero(
                tag: 'dayaar-logo',
                child: Image.asset(
                  'assets/logo.png',
                  height: 300,
                  errorBuilder: (context, error, stackTrace) => const _LogoFallback(size: 116),
                ),
              ).animate().fadeIn(duration: 650.ms).scale(begin: const Offset(0.92, 0.92)),
              const SizedBox(height: 14),
              const Text('CRM', style: TextStyle(color: AppTheme.textMuted)).animate().fadeIn(delay: 500.ms),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoFallback extends StatelessWidget {
  const _LogoFallback({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'D',
        style: TextStyle(fontSize: 54, fontWeight: FontWeight.w900, color: Colors.white),
      ),
    );
  }
}
