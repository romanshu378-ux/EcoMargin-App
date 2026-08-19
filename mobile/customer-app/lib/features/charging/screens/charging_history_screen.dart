import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/core_providers.dart';

class ChargingHistoryScreen extends ConsumerStatefulWidget {
  const ChargingHistoryScreen({super.key});

  @override
  ConsumerState<ChargingHistoryScreen> createState() => _ChargingHistoryScreenState();
}

class _ChargingHistoryScreenState extends ConsumerState<ChargingHistoryScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(chargingSessionProvider.notifier).checkActiveSession();
        ref.invalidate(chargingHistoryProvider);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(chargingSessionProvider.notifier).checkActiveSession();
          ref.invalidate(chargingHistoryProvider);
          ref.invalidate(walletBalanceAsyncProvider);
        }
      });
    }
  }

  String _formatDateTime(String? rawIso) {
    if (rawIso == null || rawIso.isEmpty) return 'N/A';
    try {
      final dt = DateTime.parse(rawIso);
      return DateFormat('dd MMM yyyy • hh:mm a').format(dt);
    } catch (_) {
      return rawIso.replaceAll('T', ' ').split('.')[0];
    }
  }

  String _formatDurationHms(int seconds) {
    if (seconds <= 0) return '00:00:00';
    final hours = (seconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$secs';
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2).format(amount);
  }

  Map<String, dynamic> _getStatusBadge(String rawStatus) {
    final status = rawStatus.toUpperCase();
    switch (status) {
      case 'COMPLETED':
        return {
          'label': 'Completed',
          'color': const Color(0xFF16A34A),
          'bg': const Color(0xFFDCFCE7),
          'icon': Icons.check_circle_rounded,
          'prefix': '✓ '
        };
      case 'STOPPED':
        return {
          'label': 'Stopped',
          'color': const Color(0xFF64748B),
          'bg': const Color(0xFFF1F5F9),
          'icon': Icons.pause_circle_rounded,
          'prefix': ''
        };
      case 'FAILED':
      case 'FAULTED':
      case 'ERROR':
        return {
          'label': status == 'FAULTED' ? 'Faulted' : 'Failed',
          'color': const Color(0xFFDC2626),
          'bg': const Color(0xFFFEE2E2),
          'icon': Icons.error_rounded,
          'prefix': ''
        };
      case 'CHARGING':
      case 'ACTIVE':
      case 'STARTING':
      case 'PREPARING':
        return {
          'label': 'Charging Now',
          'color': const Color(0xFF2563EB),
          'bg': const Color(0xFFDBEAFE),
          'icon': Icons.bolt_rounded,
          'prefix': '⚡ '
        };
      default:
        return {
          'label': status,
          'color': const Color(0xFF64748B),
          'bg': const Color(0xFFF1F5F9),
          'icon': Icons.info_rounded,
          'prefix': ''
        };
    }
  }

  void _showReceiptDialog(BuildContext context, Map<String, dynamic> session) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stationName = session['stationName'] ?? 'EcoMargin Charging Hub';
    final stationAddress = session['stationAddress'] ?? session['address'] ?? 'Downtown EV Charging Station';
    final energy = double.tryParse(session['kwhDelivered']?.toString() ?? '0') ?? 0.0;
    final cost = double.tryParse(session['totalCost']?.toString() ?? '0') ?? 0.0;
    final rate = double.tryParse(session['ratePerKwh']?.toString() ?? '0') ?? 18.0;
    final paymentMethod = session['paymentMethod'] ?? 'EcoMargin Wallet';
    final txId = session['ocppTransactionId'] ?? session['sessionId']?.toString() ?? 'TX-10029';
    final dateStr = _formatDateTime(session['startTime']?.toString() ?? session['endTime']?.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        contentPadding: const EdgeInsets.all(24),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF16A34A), size: 36),
              ),
              const SizedBox(height: 12),
              const Text(
                'EcoMargin EV Charging',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(
                'Official Session Receipt',
                style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : const Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              _buildReceiptRow('Transaction ID', txId, isDark),
              _buildReceiptRow('Date & Time', dateStr, isDark),
              _buildReceiptRow('Station', stationName, isDark),
              _buildReceiptRow('Location', stationAddress, isDark),
              _buildReceiptRow('Payment Method', paymentMethod, isDark),
              
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              _buildReceiptRow('Energy Consumed', '${energy.toStringAsFixed(3)} kWh', isDark),
              _buildReceiptRow('Rate per kWh', _formatCurrency(rate), isDark),
              _buildReceiptRow('Subtotal', _formatCurrency(cost), isDark),
              _buildReceiptRow('Taxes & Fees', 'Included (GST 18%)', isDark),

              const SizedBox(height: 12),
              const Divider(height: 1, thickness: 1.5),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Amount Paid', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(
                    _formatCurrency(cost),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF16A34A)),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Close Receipt', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showSessionDetails(BuildContext context, Map<String, dynamic> session) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stationName = session['stationName'] ?? 'EcoMargin Charging Hub';
    final stationAddress = session['stationAddress'] ?? session['address'] ?? 'Downtown EV Station';
    final chargerId = session['chargerId'] ?? 'CHG-DC-04';
    final connectorType = session['connectorType'] ?? 'CCS2';
    final connectorId = session['connectorId']?.toString() ?? 'CONN-01';
    final energy = double.tryParse(session['kwhDelivered']?.toString() ?? '0') ?? 0.0;
    final durationSec = int.tryParse(session['durationSeconds']?.toString() ?? '0') ?? 0;
    final cost = double.tryParse(session['totalCost']?.toString() ?? '0') ?? 0.0;
    final status = session['status']?.toString() ?? 'COMPLETED';
    final rate = double.tryParse(session['ratePerKwh']?.toString() ?? '0') ?? 18.0;
    final paymentMethod = session['paymentMethod'] ?? 'EcoMargin Wallet';
    final ocppTxId = session['ocppTransactionId'] ?? session['sessionId']?.toString() ?? 'N/A';
    final startTimeStr = _formatDateTime(session['startTime']?.toString());
    final endTimeStr = _formatDateTime(session['endTime']?.toString());
    final peakPower = double.tryParse(session['peakPowerKw']?.toString() ?? session['currentPowerKw']?.toString() ?? '0') ?? 42.5;
    final co2Saved = double.tryParse(session['co2SavedKg']?.toString() ?? '0') ?? (energy * 0.85);

    final badge = _getStatusBadge(status);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stationName,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(stationAddress, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: badge['bg'] as Color,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(badge['icon'] as IconData, color: badge['color'] as Color, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${badge['prefix']}${badge['label']}',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: badge['color'] as Color),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              _buildDetailItem('Transaction ID', ocppTxId, isDark),
              _buildDetailItem('Charger & Connector', '$chargerId ($connectorType - $connectorId)', isDark),
              _buildDetailItem('Start Time', startTimeStr, isDark),
              _buildDetailItem('End Time', endTimeStr, isDark),
              _buildDetailItem('Duration', _formatDurationHms(durationSec), isDark),
              _buildDetailItem('Energy Consumed', '${energy.toStringAsFixed(2)} kWh', isDark),
              _buildDetailItem('Peak Power Rating', '${peakPower.toStringAsFixed(1)} kW', isDark),
              _buildDetailItem('CO₂ Emission Saved', '${co2Saved.toStringAsFixed(2)} kg', isDark),
              _buildDetailItem('Unit Rate', '${_formatCurrency(rate)} / kWh', isDark),
              _buildDetailItem('Payment Method', paymentMethod, isDark),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Cost Charged', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(
                    _formatCurrency(cost),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF16A34A)),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showReceiptDialog(context, session);
                      },
                      icon: const Icon(Icons.receipt_rounded, size: 18),
                      label: const Text('View Receipt', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF16A34A),
                        side: const BorderSide(color: Color(0xFF16A34A)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailItem(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonLoading(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          height: 90,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(
          4,
          (index) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            height: 110,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final historyAsync = ref.watch(chargingHistoryProvider);
    final activeSessionState = ref.watch(chargingSessionProvider);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Charging History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  ref.read(chargingSessionProvider.notifier).checkActiveSession();
                  ref.invalidate(chargingHistoryProvider);
                  ref.invalidate(walletBalanceAsyncProvider);
                }
              });
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF16A34A),
        onRefresh: () async {
          ref.invalidate(chargingHistoryProvider);
          ref.invalidate(walletBalanceAsyncProvider);
          await ref.read(chargingSessionProvider.notifier).checkActiveSession();
        },
        child: historyAsync.when(
          loading: () => _buildSkeletonLoading(isDark),
          error: (err, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off_rounded, color: Colors.red, size: 48),
                  const SizedBox(height: 12),
                  const Text(
                    'Unable to load charging history',
                    style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Please check your connection and try again.',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      ref.invalidate(chargingHistoryProvider);
                    },
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
          data: (sessions) {
            int totalSessionsCount = sessions.length;
            double totalEnergyKwh = 0.0;
            double totalAmountSpent = 0.0;

            for (var s in sessions) {
              totalEnergyKwh += double.tryParse(s['kwhDelivered']?.toString() ?? '0') ?? 0.0;
              totalAmountSpent += double.tryParse(s['totalCost']?.toString() ?? '0') ?? 0.0;
            }

            if (activeSessionState.isCharging) {
              totalSessionsCount += 1;
              totalEnergyKwh += activeSessionState.kwhDelivered;
              totalAmountSpent += activeSessionState.totalCost;
            }

            if (sessions.isEmpty && !activeSessionState.isCharging) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
                  width: double.infinity,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A).withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.history_rounded, size: 64, color: Color(0xFF16A34A)),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'No charging sessions yet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Your completed charging sessions will appear here.',
                        style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => context.go('/map'),
                        icon: const Icon(Icons.search_rounded, color: Colors.white),
                        label: const Text('Find a Charger', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 1. History Summary Header Card
                Container(
                  padding: const EdgeInsets.all(18),
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
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('Total Sessions', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text('$totalSessionsCount', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                        ],
                      ),
                      Container(height: 30, width: 1, color: Colors.grey.shade300),
                      Column(
                        children: [
                          const Text('Total Energy', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text('${totalEnergyKwh.toStringAsFixed(1)} kWh', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                        ],
                      ),
                      Container(height: 30, width: 1, color: Colors.grey.shade300),
                      Column(
                        children: [
                          const Text('Total Spent', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(_formatCurrency(totalAmountSpent), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 2. Active Session Card at Top
                if (activeSessionState.isCharging) ...[
                  InkWell(
                    onTap: () => context.push('/live-charging'),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F291E) : const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF86EFAC), width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: Color(0xFF16A34A),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF16A34A),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text('⚡ CHARGING NOW', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(activeSessionState.stationName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                const SizedBox(height: 2),
                                Text(
                                  '${activeSessionState.kwhDelivered.toStringAsFixed(2)} kWh • ${_formatDurationHms(activeSessionState.durationSeconds)}',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(_formatCurrency(activeSessionState.totalCost), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                              const SizedBox(height: 4),
                              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF16A34A)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // 3. History Sessions List
                ...sessions.map((session) {
                  final stationName = session['stationName'] ?? 'EcoMargin Charging Hub';
                  final startTimeRaw = session['startTime'] ?? session['startedAt'] ?? session['endTime'];
                  final dateStr = _formatDateTime(startTimeRaw?.toString());
                  final energy = double.tryParse(session['kwhDelivered']?.toString() ?? session['totalEnergyKwh']?.toString() ?? '0') ?? 0.0;
                  final durationSec = int.tryParse(session['durationSeconds']?.toString() ?? session['duration']?.toString() ?? '0') ?? 0;
                  final cost = double.tryParse(session['totalCost']?.toString() ?? '0') ?? 0.0;
                  final status = session['status']?.toString() ?? 'COMPLETED';
                  final connectorType = session['connectorType']?.toString() ?? 'CCS2';
                  final badge = _getStatusBadge(status);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () => _showSessionDetails(context, session),
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: (badge['color'] as Color).withOpacity(0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(badge['icon'] as IconData, color: badge['color'] as Color, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        stationName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        dateStr,
                                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: badge['bg'] as Color,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${badge['prefix']}${badge['label']}',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: badge['color'] as Color),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),
                            Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                            const SizedBox(height: 12),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Duration', style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 2),
                                    Text(
                                      _formatDurationHms(durationSec),
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Energy', style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${energy.toStringAsFixed(1)} kWh',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Cost', style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 2),
                                    Text(
                                      _formatCurrency(cost),
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    connectorType,
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : const Color(0xFF475569)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                })
              ],
            );
          },
        ),
      ),
    );
  }
}
