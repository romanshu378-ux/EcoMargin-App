import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.push('/edit-profile'),
          ),
        ],
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
                    backgroundColor: const Color(0xFF16A34A).withOpacity(0.1),
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
                    await ref.read(storageServiceProvider).deleteToken();
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
          error: (err, st) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Failed to load profile: $err', style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.read(profileProvider.notifier).fetchProfile(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
