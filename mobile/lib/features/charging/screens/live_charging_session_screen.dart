import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/utils/connector_status.dart';
import '../widgets/charging_power_chart.dart';

class LiveChargingSessionScreen extends ConsumerWidget {
  final String? stationId;
  final String? sessionId;
  final String? connectorId;
  final String? chargerId;

  const LiveChargingSessionScreen({
    super.key,
    this.stationId,
    this.sessionId,
    this.connectorId,
    this.chargerId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(chargingSessionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusInfo = ConnectorStatusInfo.fromRaw(session.status);

    // Listen to session changes to redirect to stop charging receipt
    ref.listen<ChargingSessionState>(chargingSessionProvider, (previous, next) {
      if (!next.isCharging && next.status == 'COMPLETED') {
        context.go('/stop-charging');
      } else if (!next.isCharging && (previous?.isCharging ?? false)) {
        context.go('/');
      }
    });

    // Prevent manual entry to live screen when not charging
    if (!session.isCharging) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          final currentPath = GoRouterState.of(context).uri.path;
          if (currentPath == '/live-charging') {
            context.go('/');
          }
        }
      });
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF16A34A)),
        ),
      );
    }

    final hrs = (session.durationSeconds ~/ 3600).toString().padLeft(2, '0');
    final mins = ((session.durationSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final secs = (session.durationSeconds % 60).toString().padLeft(2, '0');
    final durationFormatted = '$hrs:$mins:$secs';

    final displayStationName = stationId != null ? 'EcoMargin Charging Hub' : session.stationName;
    final displayChargerId = chargerId ?? (session.chargerId.isNotEmpty ? session.chargerId : 'CHG-DC-04');
    final displayConnector = connectorId ?? (session.connectorType.isNotEmpty ? session.connectorType : 'CCS2');
    final activeSessionId = session.sessionId ?? sessionId ?? 'OCPP-TX-8492';
    final co2Saved = (session.kwhDelivered * 0.85).toStringAsFixed(2);

    final int secondsSinceUpdate = session.lastUpdated != null
        ? DateTime.now().difference(session.lastUpdated!).inSeconds
        : 0;
    final bool isStale = secondsSinceUpdate > 10;

    String connectionLabel = '● Live';
    Color connectionColor = const Color(0xFF16A34A);
    if (session.hasConnectionError) {
      connectionLabel = '🔴 Offline';
      connectionColor = Colors.red;
    } else if (isStale) {
      connectionLabel = '🟡 Connection delayed';
      connectionColor = Colors.amber.shade800;
    } else if (session.lastUpdated != null) {
      connectionLabel = '● Live • ${secondsSinceUpdate}s ago';
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/'),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Charging Session', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Row(
              children: [
                Text(
                  'Session ID: $activeSessionId',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.normal),
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: activeSessionId));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Session ID copied to clipboard'), duration: Duration(seconds: 2)),
                    );
                  },
                  child: const Icon(Icons.copy_rounded, size: 12, color: Color(0xFF16A34A)),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(chargingSessionProvider.notifier).checkActiveSession(),
          ),
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            onPressed: () => context.push('/help'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            children: [
              // FAULTED / INTERRUPTED BANNER
              if (statusInfo.status == ConnectorStatus.faulted) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade900.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_rounded, color: Colors.red, size: 28),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '🔴 Charging Interrupted',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.red),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Your charging session was interrupted because of a charger fault.',
                              style: TextStyle(fontSize: 12, color: Colors.redAccent),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Top Charger Summary Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: statusInfo.color.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(statusInfo.icon, color: statusInfo.color, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayStationName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Charger $displayChargerId • $displayConnector',
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusInfo.color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.circle, color: statusInfo.color, size: 8),
                          const SizedBox(width: 6),
                          Text(
                            statusInfo.label,
                            style: TextStyle(
                              color: statusInfo.color,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Large Circular Progress Gauge (State of Charge %)
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 210,
                    height: 210,
                    child: CircularProgressIndicator(
                      value: session.percentage > 0 ? (session.percentage / 100.0).clamp(0.0, 1.0) : 0.0,
                      strokeWidth: 16,
                      backgroundColor: const Color(0xFF16A34A).withOpacity(0.15),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF16A34A)),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        session.percentage > 0 ? '${session.percentage.toInt()}%' : '--',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'State of Charge',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Live Metrics Grid (6 cards: Power, Energy, Voltage, Current, Cost, Duration)
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: [
                  _MetricCard(
                    icon: Icons.speed_rounded,
                    label: 'Power',
                    value: session.currentPowerKw > 0 ? '${session.currentPowerKw.toStringAsFixed(1)} kW' : '-- kW',
                  ),
                  _MetricCard(
                    icon: Icons.electric_meter_rounded,
                    label: 'Energy Delivered',
                    value: '${session.kwhDelivered.toStringAsFixed(2)} kWh',
                  ),
                  _MetricCard(
                    icon: Icons.bolt_rounded,
                    label: 'Voltage',
                    value: session.voltage != null ? '${session.voltage!.toStringAsFixed(0)} V' : '-- V',
                  ),
                  _MetricCard(
                    icon: Icons.electrical_services_rounded,
                    label: 'Current',
                    value: session.current != null ? '${session.current!.toStringAsFixed(0)} A' : '-- A',
                  ),
                  _MetricCard(
                    icon: Icons.currency_rupee_rounded,
                    label: 'Session Cost',
                    value: '₹${session.totalCost.toStringAsFixed(2)}',
                    valueColor: const Color(0xFF16A34A),
                  ),
                  _MetricCard(
                    icon: Icons.timer_outlined,
                    label: 'Duration',
                    value: durationFormatted,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Charging Power Graph Widget
              ChargingPowerChart(
                samples: session.powerSamples,
                currentPowerKw: session.currentPowerKw,
                hasConnectionError: session.hasConnectionError,
                onRetry: () => ref.read(chargingSessionProvider.notifier).checkActiveSession(),
              ),

              const SizedBox(height: 20),

              // Technical Details Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _DetailColumn(label: 'Connector ID', value: displayChargerId),
                        Container(height: 24, width: 1, color: Colors.grey.shade300),
                        _DetailColumn(label: 'Connector Type', value: displayConnector),
                        Container(height: 24, width: 1, color: Colors.grey.shade300),
                        _DetailColumn(label: 'Voltage', value: session.voltage != null ? '${session.voltage!.toStringAsFixed(0)} V' : '-- V'),
                        Container(height: 24, width: 1, color: Colors.grey.shade300),
                        _DetailColumn(label: 'Current', value: session.current != null ? '${session.current!.toStringAsFixed(0)} A' : '-- A'),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Wallet Balance: ₹${ref.watch(walletBalanceProvider).toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: ref.watch(walletBalanceProvider) < 50.0 ? Colors.orange.shade800 : (isDark ? Colors.white70 : const Color(0xFF64748B)),
                          ),
                        ),
                        Text(
                          connectionLabel,
                          style: TextStyle(fontSize: 11, color: connectionColor, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              if (ref.watch(walletBalanceProvider) < 50.0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 22),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Low wallet balance (Below ₹50.00). Top up wallet to avoid session interruption.',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange),
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.push('/add-money'),
                        child: const Text('Add Money', style: TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Environmental Impact Card (CO2 Saved)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF0F291E), const Color(0xFF064E3B)]
                        : [const Color(0xFFF0FDF4), const Color(0xFFDCFCE7)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.eco_rounded, color: Color(0xFF16A34A), size: 26),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You\'ve saved $co2Saved kg CO₂ in this charging session!',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF15803D),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Stop Charging Action Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Stop Charging?'),
                        content: const Text('Are you sure you want to stop the active charging session? Your final bill will be deducted from your wallet.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              Navigator.pop(ctx);
                              try {
                                await ref.read(chargingSessionProvider.notifier).stopCharging();
                                ref.invalidate(walletBalanceAsyncProvider);
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed to stop session: $e')),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            child: const Text('Stop Session', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.stop_circle_outlined, color: Colors.white, size: 22),
                  label: const Text('Stop Charging', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
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
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w600),
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

class _DetailColumn extends StatelessWidget {
  final String label;
  final String value;

  const _DetailColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}
