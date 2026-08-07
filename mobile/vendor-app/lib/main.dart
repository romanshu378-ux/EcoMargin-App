import 'package:flutter/material.dart';
import 'src/core/theme/app_theme.dart';
import 'src/screens/login_screen.dart';
import 'src/screens/vendor_dashboard_screen.dart';
import 'src/screens/charger_status_screen.dart';
import 'src/screens/earnings_screen.dart';
import 'src/screens/transactions_screen.dart';
import 'src/screens/notifications_screen.dart';

void main() {
  runApp(const VendorApp());
}

class VendorApp extends StatelessWidget {
  const VendorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoMargin CPO Vendor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const VendorDashboardScreen(),
        '/login': (context) => const LoginScreen(),
        '/chargers': (context) => const ChargerStatusScreen(),
        '/earnings': (context) => const EarningsScreen(),
        '/transactions': (context) => const TransactionsScreen(),
        '/notifications': (context) => const NotificationsScreen(),
      },
    );
  }
}
