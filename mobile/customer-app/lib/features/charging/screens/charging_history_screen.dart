import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';

class ChargingHistoryScreen extends ConsumerWidget {
  const ChargingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(chargingHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Charging History'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(chargingHistoryProvider);
        },
        child: historyAsync.when(
          data: (sessions) {
            if (sessions.isEmpty) {
              return const Center(
                child: Text('No charging history found', style: TextStyle(color: Colors.grey)),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                final session = sessions[index];
                
                final stationName = session['stationName'] ?? 'EcoMargin Charging Hub';
                final energy = double.tryParse(session['kwhDelivered']?.toString() ?? '0') ?? 0.0;
                final durationSec = int.tryParse(session['durationSeconds']?.toString() ?? '0') ?? 0;
                final durationMins = durationSec ~/ 60;
                final cost = double.tryParse(session['totalCost']?.toString() ?? '0') ?? 0.0;
                final status = session['status'] ?? 'Completed';
                
                final dateStr = session['startTime'] != null 
                    ? session['startTime'].toString().split('T')[0]
                    : 'Unknown Date';

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFF16A34A),
                      child: Icon(Icons.bolt, color: Colors.white),
                    ),
                    title: Text(stationName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text('$dateStr\n${energy.toStringAsFixed(1)} kWh • $durationMins mins'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('₹${cost.toStringAsFixed(2)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16A34A).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(status, style: const TextStyle(fontSize: 10, color: Color(0xFF16A34A), fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFF16A34A)),
          ),
          error: (err, st) => Center(
            child: Text('Failed to load history: $err', style: const TextStyle(color: Colors.red)),
          ),
        ),
      ),
    );
  }
}
