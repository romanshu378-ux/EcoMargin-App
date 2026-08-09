import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/core_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('App Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.language, color: Color(0xFF16A34A)),
            title: const Text('Language'),
            subtitle: Text(language),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/language'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.dark_mode_outlined, color: Color(0xFF16A34A)),
            title: const Text('App Theme'),
            subtitle: Text(themeMode == ThemeMode.dark ? 'Dark Mode' : 'Light Mode'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/theme'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.notifications_outlined, color: Color(0xFF16A34A)),
            title: const Text('Push Notifications'),
            subtitle: const Text('Live charging updates & discounts'),
            trailing: Switch(value: true, onChanged: (val) {}, activeColor: const Color(0xFF16A34A)),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.fingerprint, color: Color(0xFF16A34A)),
            title: const Text('Biometric Authentication'),
            subtitle: const Text('Require fingerprint to start charging'),
            trailing: Switch(value: false, onChanged: (val) {}, activeColor: const Color(0xFF16A34A)),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Delete Account', style: TextStyle(color: Colors.red)),
            trailing: const Icon(Icons.chevron_right, color: Colors.red),
            onTap: () => context.push('/delete-account'),
          ),
        ],
      ),
    );
  }
}
