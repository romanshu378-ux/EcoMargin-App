import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/core_providers.dart';

import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';

import '../../features/home/screens/home_screen.dart';

import '../../features/map/screens/map_screen.dart';
import '../../features/map/screens/search_station_screen.dart';
import '../../features/map/screens/station_details_screen.dart';
import '../../features/map/screens/charger_details_screen.dart';
import '../../features/map/screens/favorites_screen.dart';

import '../../features/charging/screens/start_charging_screen.dart';
import '../../features/charging/screens/live_charging_session_screen.dart';
import '../../features/charging/screens/stop_charging_screen.dart';
import '../../features/charging/screens/charging_history_screen.dart';

import '../../features/wallet/screens/wallet_screen.dart';
import '../../features/wallet/screens/add_money_screen.dart';
import '../../features/wallet/screens/payments_screen.dart';
import '../../features/wallet/screens/transactions_screen.dart';
import '../../features/wallet/screens/offers_coupons_screen.dart';

import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/profile/screens/vehicle_management_screen.dart';
import '../../features/profile/screens/add_edit_vehicle_screen.dart';

import '../../features/settings/screens/settings_screen.dart';
import '../../features/settings/screens/language_screen.dart';
import '../../features/settings/screens/theme_screen.dart';
import '../../features/settings/screens/notifications_screen.dart';
import '../../features/settings/screens/help_support_screen.dart';
import '../../features/settings/screens/raise_complaint_screen.dart';
import '../../features/settings/screens/faq_screen.dart';
import '../../features/settings/screens/about_screen.dart';
import '../../features/settings/screens/privacy_policy_screen.dart';
import '../../features/settings/screens/terms_conditions_screen.dart';
import '../../features/settings/screens/delete_account_screen.dart';

import '../../features/error/screens/no_internet_screen.dart';
import '../../features/error/screens/maintenance_screen.dart';
import '../../features/error/screens/not_found_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    errorBuilder: (context, state) => const NotFoundScreen(),
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(path: '/forgot-password', builder: (context, state) => const ForgotPasswordScreen()),

      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),

      GoRoute(path: '/map', builder: (context, state) => const MapScreen()),
      GoRoute(path: '/search', builder: (context, state) => const SearchStationScreen()),
      GoRoute(
        path: '/station-details',
        builder: (context, state) => const StationDetailsScreen(stationId: 'st-01'),
      ),
      GoRoute(path: '/charger-details', builder: (context, state) => const ChargerDetailsScreen()),
      GoRoute(path: '/favorites', builder: (context, state) => const FavoritesScreen()),

      GoRoute(path: '/start-charging', builder: (context, state) => const StartChargingScreen()),
      GoRoute(path: '/live-charging', builder: (context, state) => const LiveChargingSessionScreen()),
      GoRoute(path: '/stop-charging', builder: (context, state) => const StopChargingScreen()),
      GoRoute(path: '/charging-history', builder: (context, state) => const ChargingHistoryScreen()),

      GoRoute(path: '/wallet', builder: (context, state) => const WalletScreen()),
      GoRoute(path: '/add-money', builder: (context, state) => const AddMoneyScreen()),
      GoRoute(path: '/payments', builder: (context, state) => const PaymentsScreen()),
      GoRoute(path: '/transactions', builder: (context, state) => const TransactionsScreen()),
      GoRoute(path: '/offers', builder: (context, state) => const OffersCouponsScreen()),

      GoRoute(path: '/notifications', builder: (context, state) => const NotificationsScreen()),

      GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
      GoRoute(path: '/edit-profile', builder: (context, state) => const EditProfileScreen()),
      GoRoute(path: '/vehicles', builder: (context, state) => const VehicleManagementScreen()),
      GoRoute(path: '/add-edit-vehicle', builder: (context, state) => const AddEditVehicleScreen()),

      GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
      GoRoute(path: '/language', builder: (context, state) => const LanguageScreen()),
      GoRoute(path: '/theme', builder: (context, state) => const ThemeScreen()),

      GoRoute(path: '/help', builder: (context, state) => const HelpSupportScreen()),
      GoRoute(path: '/raise-complaint', builder: (context, state) => const RaiseComplaintScreen()),
      GoRoute(path: '/faq', builder: (context, state) => const FaqScreen()),
      GoRoute(path: '/about', builder: (context, state) => const AboutScreen()),
      GoRoute(path: '/privacy-policy', builder: (context, state) => const PrivacyPolicyScreen()),
      GoRoute(path: '/terms-conditions', builder: (context, state) => const TermsConditionsScreen()),
      GoRoute(path: '/delete-account', builder: (context, state) => const DeleteAccountScreen()),

      GoRoute(path: '/no-internet', builder: (context, state) => const NoInternetScreen()),
      GoRoute(path: '/maintenance', builder: (context, state) => const MaintenanceScreen()),
    ],
  );
});
