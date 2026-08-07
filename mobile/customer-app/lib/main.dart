import 'package:flutter/material.dart';
import 'src/core/theme/app_theme.dart';
import 'src/screens/login_screen.dart';
import 'src/screens/map_screen.dart';
import 'src/screens/qr_scan_screen.dart';
import 'src/screens/charging_session_screen.dart';
import 'src/screens/wallet_screen.dart';
import 'src/screens/payments_screen.dart';
import 'src/screens/charging_history_screen.dart';
import 'src/screens/notifications_screen.dart';
import 'src/screens/profile_screen.dart';

void main() {
  runApp(const CustomerApp());
}

class CustomerApp extends StatelessWidget {
  const CustomerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoMargin Driver',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const MapScreen(),
        '/login': (context) => const LoginScreen(),
        '/qr': (context) => const QrScanScreen(),
        '/charging': (context) => const ChargingSessionScreen(),
        '/wallet': (context) => const WalletScreen(),
        '/payments': (context) => const PaymentsScreen(),
        '/history': (context) => const ChargingHistoryScreen(),
        '/notifications': (context) => const NotificationsScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}
