import 'package:flutter/material.dart';

class ChargerStatusScreen extends StatelessWidget {
  const ChargerStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Charger Fleet Status')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Card(
            color: Color(0xFF1E293B),
            child: ListTile(
              leading: Icon(Icons.power, color: Color(0xFF10B981)),
              title: Text('CHG-9001 • Downtown Hub'),
              subtitle: Text('DC Fast 150kW • Status: CHARGING'),
              trailing: Text('145 kW', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF97316))),
            ),
          ),
        ],
      ),
    );
  }
}
