import 'package:flutter/material.dart';
import 'src/core/theme/app_theme.dart';
import 'src/screens/login_screen.dart';
import 'src/screens/admin_dashboard_screen.dart';
import 'src/screens/users_screen.dart';
import 'src/screens/vendors_screen.dart';
import 'src/screens/stations_screen.dart';
import 'src/screens/alerts_screen.dart';

void main() {
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoMargin Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const AdminDashboardScreen(),
        '/login': (context) => const LoginScreen(),
        '/users': (context) => const UsersScreen(),
        '/vendors': (context) => const VendorsScreen(),
        '/stations': (context) => const StationsScreen(),
        '/alerts': (context) => const AlertsScreen(),
      },
    );
  }
}
