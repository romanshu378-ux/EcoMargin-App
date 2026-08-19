import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/core_providers.dart';

class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  final List<String> _languages = const [
    'English',
    'Hindi (हिंदी)',
    'Marathi (मराठी)',
    'Gujarati (ગુજરાતી)',
    'Tamil (தமிழ்)',
    'Telugu (తెలుగు)',
    'Kannada (ಕನ್ನಡ)',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedLang = ref.watch(languageProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Language'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _languages.length,
        itemBuilder: (context, index) {
          final lang = _languages[index];
          final isSelected = selectedLang == lang || (selectedLang == 'English' && index == 0);
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              title: Text(lang, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
              trailing: isSelected ? const Icon(Icons.check_circle, color: Color(0xFF16A34A)) : null,
              onTap: () {
                ref.read(languageProvider.notifier).state = lang;
                context.pop();
              },
            ),
          );
        },
      ),
    );
  }
}
