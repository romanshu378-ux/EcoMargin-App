import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & 24/7 Support'),
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
              title: const Text('24/7 EV Helpline Number', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Toll Free: 1800-123-4567'),
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
            onTap: () => context.push('/faq'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.report_problem_outlined, color: Color(0xFF16A34A)),
            title: const Text('Raise a Support Ticket / Complaint'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/raise-complaint'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline, color: Color(0xFF16A34A)),
            title: const Text('About EcoMargin App'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/about'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined, color: Color(0xFF16A34A)),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/privacy-policy'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.gavel_outlined, color: Color(0xFF16A34A)),
            title: const Text('Terms & Conditions'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/terms-conditions'),
          ),
        ],
      ),
    );
  }
}
