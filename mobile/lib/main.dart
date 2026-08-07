import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/core/theme/app_theme.dart';
import 'src/core/providers/theme_provider.dart';
import 'src/features/auth/login_screen.dart';
import 'src/features/map/map_screen.dart';
import 'src/features/payment/wallet_screen.dart';
import 'src/features/profile/history_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: EcoMarginApp(),
    ),
  );
}

class EcoMarginApp extends ConsumerWidget {
  const EcoMarginApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'EcoMargin',
      debugShowCheckedModeBanner: false,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/map': (context) => const MapScreen(),
        '/wallet': (context) => const WalletScreen(),
        '/history': (context) => const HistoryScreen(),
      },
    );
  }
}
