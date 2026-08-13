import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/app_config_provider.dart';

class HelpSupportScreen extends ConsumerWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appConfig = ref.watch(appConfigProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF16A34A),
                child: Icon(Icons.phone_in_talk, color: Colors.white),
              ),
              title: Text('${appConfig.supportHours} Number', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Toll Free: ${appConfig.supportPhone}'),
              trailing: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16A34A)),
                child: const Text('CALL NOW', style: TextStyle(color: Colors.white)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.question_answer_outlined, color: Color(0xFF16A34A)),
            title: const Text('Frequently Asked Questions (FAQ)'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/faq'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.report_problem_outlined, color: Color(0xFF16A34A)),
            title: const Text('Raise a Support Ticket / Complaint'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/raise-complaint'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline, color: Color(0xFF16A34A)),
            title: const Text('About EcoMargin App'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/about'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined, color: Color(0xFF16A34A)),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/privacy-policy'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.gavel_outlined, color: Color(0xFF16A34A)),
            title: const Text('Terms & Conditions'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/terms-conditions'),
          ),
        ],
      ),
    );
  }
}
