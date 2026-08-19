import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/core_providers.dart';

class ThemeScreen extends ConsumerWidget {
  const ThemeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('App Theme Preference'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          RadioListTile<ThemeMode>(
            title: const Text('Light Theme'),
            subtitle: const Text('Clean slate background with high contrast text'),
            value: ThemeMode.light,
            groupValue: currentTheme,
            activeColor: const Color(0xFF16A34A),
            onChanged: (val) {
              if (val != null) {
                ref.read(themeModeProvider.notifier).state = val;
                context.pop();
              }
            },
          ),
          const Divider(),
          RadioListTile<ThemeMode>(
            title: const Text('Dark Theme'),
            subtitle: const Text('Sleek dark mode tailored for night driving'),
            value: ThemeMode.dark,
            groupValue: currentTheme,
            activeColor: const Color(0xFF16A34A),
            onChanged: (val) {
              if (val != null) {
                ref.read(themeModeProvider.notifier).state = val;
                context.pop();
              }
            },
          ),
        ],
      ),
    );
  }
}
