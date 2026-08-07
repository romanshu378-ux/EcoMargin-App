import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/core_providers.dart';

class LiveChargingSessionScreen extends ConsumerWidget {
  const LiveChargingSessionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(chargingSessionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final minutes = (session.durationSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (session.durationSeconds % 60).toString().padLeft(2, '0');

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Live Charging Session'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => context.go('/help'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Circular Battery Progress Gauge
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 220,
                  height: 220,
                  child: CircularProgressIndicator(
                    value: session.percentage / 100.0,
                    strokeWidth: 16,
                    backgroundColor: const Color(0xFF16A34A).withOpacity(0.15),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF16A34A)),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bolt_rounded, size: 48, color: Color(0xFF16A34A)),
                    Text(
                      '${session.percentage.toInt()}%',
                      style: const TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    ),
                    const Text(
                      'CHARGING',
                      style: TextStyle(
                        color: Color(0xFF16A34A),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Station & Charger Info
            Text(
              session.stationName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Charger ID: ${session.chargerId} (60 kW DC Fast)',
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
            const SizedBox(height: 24),

            // Live Metrics Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _MetricCard(
                  icon: Icons.electric_meter,
                  label: 'Energy Delivered',
                  value: '${session.kwhDelivered.toStringAsFixed(2)} kWh',
                ),
                _MetricCard(
                  icon: Icons.timer,
                  label: 'Duration',
                  value: '$minutes:$seconds min',
                ),
                _MetricCard(
                  icon: Icons.speed,
                  label: 'Charging Speed',
                  value: '${session.currentPowerKw.toStringAsFixed(1)} kW',
                ),
                _MetricCard(
                  icon: Icons.currency_rupee,
                  label: 'Estimated Cost',
                  value: '₹${session.totalCost.toStringAsFixed(2)}',
                  valueColor: const Color(0xFF16A34A),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Stop Charging Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  ref.read(chargingSessionProvider.notifier).stopCharging();
                  context.go('/stop-charging');
                },
                icon: const Icon(Icons.stop_circle_outlined, color: Colors.white),
                label: const Text('Stop Charging Session', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF16A34A)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: valueColor ?? (isDark ? Colors.white : const Color(0xFF0F172A)),
            ),
          ),
        ],
      ),
    );
  }
}
