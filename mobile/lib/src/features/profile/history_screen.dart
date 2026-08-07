import 'package:flutter/material.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mockHistory = [
      { 'station': 'Austin Downtown Hub', 'energy': '48.9 kWh', 'cost': '\$17.11', 'date': '2026-08-06' },
      { 'station': 'North Loop Charger Point', 'energy': '18.5 kWh', 'close': '\$6.47', 'date': '2026-08-04' },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Charging History')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Past Charging Sessions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 16),
              
              Expanded(
                child: ListView.builder(
                  itemCount: mockHistory.length,
                  itemBuilder: (context, idx) {
                    final item = mockHistory[idx];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.between,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['station']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(height: 4),
                                Text('${item['date']} • ${item['energy']}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(item['cost'] ?? '\$6.47', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.emerald)),
                                const SizedBox(height: 4),
                                GestureDetector(
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Downloading invoice pdf...')),
                                    );
                                  },
                                  child: const Text('Invoice PDF', style: TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
