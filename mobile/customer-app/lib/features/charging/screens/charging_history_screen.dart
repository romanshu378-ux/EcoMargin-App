import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';

class ChargingHistoryScreen extends ConsumerWidget {
  const ChargingHistoryScreen({super.key});

  void _showSessionDetails(BuildContext context, Map<String, dynamic> session) {
    final stationName = session['stationName'] ?? 'EcoMargin Charging Hub';
    final chargerId = session['chargerId'] ?? 'N/A';
    final connectorType = session['connectorType'] ?? 'N/A';
    final energy = double.tryParse(session['kwhDelivered']?.toString() ?? '0') ?? 0.0;
    final durationSec = int.tryParse(session['durationSeconds']?.toString() ?? '0') ?? 0;
    final durationMins = durationSec ~/ 60;
    final cost = double.tryParse(session['totalCost']?.toString() ?? '0') ?? 0.0;
    final status = session['status'] ?? 'Completed';
    final rate = double.tryParse(session['ratePerKwh']?.toString() ?? '0') ?? 18.0;
    final paymentMethod = session['paymentMethod'] ?? 'Wallet';
    final transactionId = session['ocppTransactionId'] ?? 'N/A';

    final startTimeStr = session['startTime']?.toString() ?? '';
    final endTimeStr = session['endTime']?.toString() ?? '';

    final startTime = startTimeStr.isNotEmpty
        ? startTimeStr.replaceAll('T', ' ').substring(0, startTimeStr.length > 19 ? 19 : startTimeStr.length)
        : 'N/A';
    final endTime = endTimeStr.isNotEmpty
        ? endTimeStr.replaceAll('T', ' ').substring(0, endTimeStr.length > 19 ? 19 : endTimeStr.length)
        : 'N/A';

    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          title: Text(stationName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Divider(),
                _buildDetailRow('Status', status, isStatus: true, isDark: isDark),
                _buildDetailRow('Start Time', startTime, isDark: isDark),
                _buildDetailRow('End Time', endTime, isDark: isDark),
                _buildDetailRow('Duration', '$durationMins mins ($durationSec secs)', isDark: isDark),
                _buildDetailRow('Energy Consumed', '${energy.toStringAsFixed(3)} kWh', isDark: isDark),
                _buildDetailRow('Rate / kWh', '₹${rate.toStringAsFixed(2)}', isDark: isDark),
                _buildDetailRow('Total Amount', '₹${cost.toStringAsFixed(2)}', isBold: true, isDark: isDark),
                _buildDetailRow('Payment Method', paymentMethod, isDark: isDark),
                _buildDetailRow('Transaction ID', transactionId, isDark: isDark),
                _buildDetailRow('Charger ID', chargerId, isDark: isDark),
                _buildDetailRow('Connector Type', connectorType, isDark: isDark),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close', style: TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false, bool isStatus = false, required bool isDark}) {
    Color valColor = isDark ? Colors.white70 : Colors.black87;
    if (isStatus) {
      valColor = value.toUpperCase() == 'COMPLETED' ? Colors.green : Colors.orange;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: valColor,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

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
                            color: const Color(0xFF16A34A).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(status, style: const TextStyle(fontSize: 10, color: Color(0xFF16A34A), fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    onTap: () => _showSessionDetails(context, session),
                  ),
                );
              },
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFF16A34A)),
          ),
          error: (err, st) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
                const SizedBox(height: 12),
                Text(
                  'Failed to load charging history: $err',
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(chargingHistoryProvider),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
