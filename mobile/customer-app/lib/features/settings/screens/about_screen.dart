import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About EcoMargin'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 44,
              backgroundColor: Color(0xFF16A34A),
              child: Icon(Icons.electric_car, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 16),
            const Text(
              'EcoMargin EV Customer Platform',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text('Version 1.0.0 (Production Edition)', style: TextStyle(color: Color(0xFF64748B))),
            const SizedBox(height: 24),
            const Text(
              'EcoMargin is a next-generation electric vehicle charging ecosystem providing ultra-fast DC and AC charging solutions with real-time OCPP protocol monitoring, smart automated payments, and 100% green energy sourcing across India.',
              textAlign: TextAlign.center,
              style: TextStyle(height: 1.5, color: Color(0xFF64748B)),
            ),
            const Spacer(),
            const Text('© 2026 EcoMargin Technologies Pvt Ltd.', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const Text('All rights reserved.', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
