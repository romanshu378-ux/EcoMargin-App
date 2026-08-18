import 'package:flutter/material.dart';

class ChargingHistoryScreen extends StatelessWidget {
  const ChargingHistoryScreen({super.key});

  final List<Map<String, String>> _sessions = const [
    {
      'station': 'GreenCharge Hub Sector 62',
      'date': '07 Aug 2026, 02:30 PM',
      'energy': '14.5 kWh',
      'duration': '19 mins',
      'cost': '₹261.00',
      'status': 'Completed',
    },
    {
      'station': 'EcoFast Station Whitefield',
      'date': '04 Aug 2026, 11:15 AM',
      'energy': '28.2 kWh',
      'duration': '35 mins',
      'cost': '₹507.60',
      'status': 'Completed',
    },
    {
      'station': 'PowerGrid Hub Indiranagar',
      'date': '29 Jul 2026, 06:45 PM',
      'energy': '18.0 kWh',
      'duration': '45 mins',
      'cost': '₹252.00',
      'status': 'Completed',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Charging History'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _sessions.length,
        itemBuilder: (context, index) {
          final item = _sessions[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF16A34A),
                child: Icon(Icons.bolt, color: Colors.white),
              ),
              title: Text(item['station']!, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['date']!),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(item['energy']!, style: const TextStyle(fontWeight: FontWeight.w600)),
                        const Text(' • '),
                        Text(item['duration']!, style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(item['cost']!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16A34A).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(item['status']!, style: const TextStyle(fontSize: 10, color: Color(0xFF16A34A), fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
