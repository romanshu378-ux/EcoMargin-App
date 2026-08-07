import 'package:flutter/material.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
      ),
      body: const SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Terms of Service Agreement', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Text(
              '1. Acceptance of Terms\n'
              'By creating an account or initiating a charging session on the EcoMargin platform, you agree to comply with all charging safety protocols, local electrical guidelines, and tariff schedules.\n\n'
              '2. Charging Station Usage\n'
              'Users must unhook connectors safely upon session completion. Vehicles parked at charging bays without active charging sessions may incur idle parking fees.\n\n'
              '3. Payments & Tariff Changes\n'
              'Energy prices per kWh are displayed prior to starting a session. Wallet debits are final once energy has been delivered.',
              style: TextStyle(height: 1.6, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }
}
