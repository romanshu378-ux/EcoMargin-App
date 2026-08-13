import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/config/app_config.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Profile'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(profileProvider);
        },
        child: profileAsync.when(
          data: (profile) {
            final host = AppConfig.baseUrl.replaceAll('/api/v1', '');
            final avatarUrl = profile.profileImageUrl != null && profile.profileImageUrl!.isNotEmpty
                ? '$host${profile.profileImageUrl}'
                : null;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: const Color(0x1A16A34A),
                    backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl == null
                        ? const Icon(Icons.person, size: 50, color: Color(0xFF16A34A))
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  profile.fullName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.email,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                if (profile.phoneNumber.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    profile.phoneNumber,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
                const SizedBox(height: 8),
                Center(
                  child: TextButton.icon(
                    onPressed: () => context.push('/edit-profile'),
                    icon: const Icon(Icons.edit, size: 16, color: Color(0xFF16A34A)),
                    label: const Text(
                      'Edit Profile',
                      style: TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.electric_car, color: Color(0xFF16A34A)),
                  title: const Text('My Vehicles'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => context.push('/vehicles'),
                ),
                ListTile(
                  leading: const Icon(Icons.history, color: Color(0xFF16A34A)),
                  title: const Text('Charging History'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => context.push('/charging-history'),
                ),
                ListTile(
                  leading: const Icon(Icons.credit_card_rounded, color: Color(0xFF16A34A)),
                  title: const Text('RFID Card'),
                  subtitle: const Text('Manage your EcoMargin RFID card', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => context.push('/rfid-card'),
                ),
                ListTile(
                  leading: const Icon(Icons.shield_outlined, color: Color(0xFF16A34A)),
                  title: const Text('Privacy Settings'),
                  subtitle: const Text('Control your privacy and data', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => context.push('/privacy-settings'),
                ),
                ListTile(
                  leading: const Icon(Icons.help_outline_rounded, color: Color(0xFF16A34A)),
                  title: const Text('FAQs'),
                  subtitle: const Text('Frequently asked questions', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => context.push('/faqs'),
                ),
                ListTile(
                  leading: const Icon(Icons.settings, color: Color(0xFF16A34A)),
                  title: const Text('App Settings'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => context.push('/settings'),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    await ref.read(storageServiceProvider).clearAllTokens();
                    ref.read(authStateProvider.notifier).state = false;
                    if (context.mounted) {
                      context.go('/login');
                    }
                  },
                ),
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFF16A34A)),
          ),
          error: (err, st) {
            String message = "Unable to load your profile. Please try again later.";
            if (err is DioException) {
              if (err.type == DioExceptionType.connectionTimeout ||
                  err.type == DioExceptionType.receiveTimeout ||
                  err.type == DioExceptionType.sendTimeout ||
                  err.type == DioExceptionType.connectionError) {
                message = "Unable to load your profile. Please check your connection and try again.";
              } else if (err.response?.statusCode == 401 || err.response?.statusCode == 403) {
                message = "Your session has expired. Please log in again.";
              } else if (err.response?.statusCode != null && err.response!.statusCode! >= 500) {
                message = "Server error occurred. Please try again later.";
              }
            }
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, color: Colors.red),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => ref.read(profileProvider.notifier).fetchProfile(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
