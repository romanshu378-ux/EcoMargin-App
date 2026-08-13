import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_config_provider.dart';

class FaqScreen extends ConsumerWidget {
  const FaqScreen({super.key});

  final List<Map<String, String>> _defaultFaqs = const [
    {
      'q': 'How do I start an EV charging session?',
      'a': 'Simply find a nearby charger on the map, select the connector details, set your target battery limit, and tap Start Charging.',
    },
    {
      'q': 'How does EcoMargin Wallet billing work?',
      'a': 'Your wallet balance is automatically debited based on the exact kWh energy consumed at the end of every charging session.',
    },
    {
      'q': 'What connector types are supported?',
      'a': 'EcoMargin supports DC Fast Chargers (CCS2, GB/T, CHAdeMO) and AC Chargers (Type 2).',
    },
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appConfig = ref.watch(appConfigProvider);
    final faqs = appConfig.faqs.isNotEmpty ? appConfig.faqs : _defaultFaqs;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Frequently Asked Questions'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: faqs.length,
        itemBuilder: (context, index) {
          final item = faqs[index];
          return ExpansionTile(
            title: Text(item['q'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(item['a'] ?? '', style: const TextStyle(color: Color(0xFF64748B))),
              ),
            ],
          );
        },
      ),
    );
  }
}
