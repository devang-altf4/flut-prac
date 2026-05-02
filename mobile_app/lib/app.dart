import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/admin_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/employee_provider.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

class DayaarCrmApp extends StatelessWidget {
  const DayaarCrmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..initialize()),
        ChangeNotifierProxyProvider<AuthProvider, AdminProvider>(
          create: (_) => AdminProvider(),
          update: (_, auth, admin) => admin!..updateToken(auth.token),
        ),
        ChangeNotifierProxyProvider<AuthProvider, EmployeeProvider>(
          create: (_) => EmployeeProvider(),
          update: (_, auth, employee) => employee!..updateToken(auth.token),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Dayaar CRM',
        theme: AppTheme.darkTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
