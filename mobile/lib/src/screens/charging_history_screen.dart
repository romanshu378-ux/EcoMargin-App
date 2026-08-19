import 'package:flutter/material.dart';

class ChargingHistoryScreen extends StatelessWidget {
  const ChargingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Charging History')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Card(
            color: Color(0xFF1E293B),
            child: ListTile(
              title: Text('Downtown Hub Fast Charge'),
              subtitle: Text('42.5 kWh • 45 mins'),
              trailing: Text('₹18.70', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
            ),
          ),
        ],
      ),
    );
  }
}
