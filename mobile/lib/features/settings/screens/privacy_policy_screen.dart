import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: const SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Privacy Policy & Data Security', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Text(
              '1. Information We Collect\n'
              'EcoMargin collects location data to display nearby charging stations, vehicle specifications to ensure connector compatibility, and transaction logs for automated wallet billing.\n\n'
              '2. Data Usage & Security\n'
              'All communications between the mobile application, backend API endpoints, and OCPP charging hardware are encrypted via standard TLS 1.3 encryption. We do not sell your personal information to third parties.\n\n'
              '3. Location Permissions\n'
              'Location permissions are utilized exclusively while using the map screen to calculate distances and render directions to charging hubs.\n\n'
              '4. Data Retention & Deletion\n'
              'Users retain full control over their account data and can request complete account deletion at any time through the app settings.',
              style: TextStyle(height: 1.6, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }
}
