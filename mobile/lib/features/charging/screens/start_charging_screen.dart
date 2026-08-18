import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/providers/app_config_provider.dart';
import '../../../core/utils/connector_status.dart';
import '../../home/providers/home_providers.dart';
import '../../home/models/station.dart';

class StartChargingScreen extends ConsumerStatefulWidget {
  final String? connectorId;
  final String? chargerId;
  final String? stationId;

  const StartChargingScreen({
    super.key,
    this.connectorId,
    this.chargerId,
    this.stationId,
  });

  @override
  ConsumerState<StartChargingScreen> createState() => _StartChargingScreenState();
}

class _StartChargingScreenState extends ConsumerState<StartChargingScreen> {
  ChargingStation? _selectedStation;
  StationConnector? _selectedConnector;
  Position? _currentPosition;
  bool _isLocating = false;
  bool _isStartingSession = false;

  @override
  void initState() {
    super.initState();
    _detectLocationAndStations();
  }

  Future<void> _detectLocationAndStations() async {
    if (mounted) setState(() => _isLocating = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 8),
        );
        if (mounted) setState(() => _currentPosition = pos);
      }
    } catch (_) {}

    await ref.read(stationsProvider.notifier).fetchStations();

    if (mounted) {
      setState(() {
        _isLocating = false;
      });
    }
  }

  String _formatAmount(double amount) {
    return NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appConfig = ref.watch(appConfigProvider);
    final walletAsync = ref.watch(walletBalanceAsyncProvider);
    final currentWalletBalance = ref.watch(walletBalanceProvider);
    final stationsAsync = ref.watch(stationsProvider);

    final double walletBalance = walletAsync.maybeWhen(
      data: (bal) => bal,
      orElse: () => currentWalletBalance,
    );

    const double minRequiredBalance = 50.0;
    final bool hasMinBalance = walletBalance >= minRequiredBalance;
    final statusInfo = ConnectorStatusInfo.fromRaw(_selectedConnector?.status);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Start EV Charger'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.invalidate(walletBalanceAsyncProvider);
              _detectLocationAndStations();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF16A34A),
          onRefresh: () async {
            ref.invalidate(walletBalanceAsyncProvider);
            await _detectLocationAndStations();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // STEP 1: Wallet Balance Eligibility Check
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: hasMinBalance
                        ? (isDark ? const Color(0xFF0F291E) : const Color(0xFFF0FDF4))
                        : (isDark ? const Color(0xFF311414) : const Color(0xFFFEF2F2)),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: hasMinBalance ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: hasMinBalance ? const Color(0xFF16A34A).withOpacity(0.15) : Colors.red.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          hasMinBalance ? Icons.account_balance_wallet_rounded : Icons.warning_amber_rounded,
                          color: hasMinBalance ? const Color(0xFF16A34A) : Colors.red,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hasMinBalance ? 'Wallet Balance Eligible' : 'Minimum ₹50 Balance Required',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: hasMinBalance ? const Color(0xFF15803D) : Colors.red.shade800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Current: ${_formatAmount(walletBalance)} (Min: ₹50.00)',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white70 : const Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (!hasMinBalance) ...[
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            await context.push('/add-money');
                            ref.invalidate(walletBalanceAsyncProvider);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Add Money', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // STEP 2: Nearby Charger Selection
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Select Nearby Charger', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    if (_isLocating)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF16A34A)),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                stationsAsync.when(
                  data: (stations) {
                    if (stations.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Text('No chargers found nearby. Try refreshing.'),
                        ),
                      );
                    }

                    final sortedStations = List<ChargingStation>.from(stations);
                    if (_currentPosition != null) {
                      sortedStations.sort((a, b) {
                        final dA = Geolocator.distanceBetween(_currentPosition!.latitude, _currentPosition!.longitude, a.latitude, a.longitude);
                        final dB = Geolocator.distanceBetween(_currentPosition!.latitude, _currentPosition!.longitude, b.latitude, b.longitude);
                        return dA.compareTo(dB);
                      });
                    }

                    _selectedStation ??= sortedStations.firstWhere(
                      (s) => s.id == widget.stationId,
                      orElse: () => sortedStations.first,
                    );

                    if (_selectedStation != null && _selectedStation!.connectors.isNotEmpty) {
                      _selectedConnector ??= _selectedStation!.connectors.firstWhere(
                        (c) => c.id == widget.connectorId,
                        orElse: () => _selectedStation!.connectors.first,
                      );
                    }

                    return Column(
                      children: sortedStations.map((station) {
                        final isSelected = _selectedStation?.id == station.id;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Material(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            clipBehavior: Clip.antiAlias,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF16A34A) : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                onTap: () {
                                  setState(() {
                                    _selectedStation = station;
                                    _selectedConnector = station.connectors.isNotEmpty ? station.connectors.first : null;
                                  });
                                },
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFF16A34A) : Colors.grey.shade200,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.ev_station_rounded,
                                    color: isSelected ? Colors.white : Colors.grey.shade700,
                                    size: 24,
                                  ),
                                ),
                                title: Text(
                                  station.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      station.address,
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF16A34A).withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            station.chargerCategory,
                                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          station.distanceStr,
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF16A34A)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: Radio<String>(
                                  value: station.id,
                                  groupValue: _selectedStation?.id,
                                  activeColor: const Color(0xFF16A34A),
                                  onChanged: (val) {
                                    setState(() {
                                      _selectedStation = station;
                                      _selectedConnector = station.connectors.isNotEmpty ? station.connectors.first : null;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                  loading: () => Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(child: CircularProgressIndicator(color: Color(0xFF16A34A))),
                  ),
                  error: (err, st) => Container(
                    padding: const EdgeInsets.all(20),
                    child: Text('Failed to load nearby chargers: $err', style: const TextStyle(color: Colors.red)),
                  ),
                ),

                const SizedBox(height: 24),

                // STEP 3: Selected Charger & Gun/Connector Status Verification
                if (_selectedStation != null) ...[
                  const Text('Connector & Gun Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
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
                                    _selectedStation!.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _selectedStation!.address,
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF16A34A).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '₹${appConfig.defaultChargingRate.toStringAsFixed(2)}/kWh',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF16A34A)),
                              ),
                            ),
                          ],
                        ),

                        const Divider(height: 24),

                        if (_selectedStation!.connectors.length > 1) ...[
                          const Text('Available Connectors:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: _selectedStation!.connectors.map((conn) {
                              final isSelected = _selectedConnector?.id == conn.id;
                              final cInfo = ConnectorStatusInfo.fromRaw(conn.status);
                              return ChoiceChip(
                                label: Text('${conn.type} • ${cInfo.label}'),
                                selected: isSelected,
                                selectedColor: cInfo.color.withOpacity(0.2),
                                onSelected: (sel) {
                                  if (sel) setState(() => _selectedConnector = conn);
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // CONNECTOR STATUS DISPLAY
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: statusInfo.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: statusInfo.color),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(statusInfo.icon, color: statusInfo.color, size: 28),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          statusInfo.label,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: statusInfo.color,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          statusInfo.description,
                                          style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : const Color(0xFF64748B)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.refresh_rounded, color: Color(0xFF16A34A)),
                                    tooltip: 'Refresh Status',
                                    onPressed: () {
                                      ref.read(stationsProvider.notifier).fetchStations();
                                    },
                                  ),
                                ],
                              ),
                              if (statusInfo.status == ConnectorStatus.faulted) ...[
                                const SizedBox(height: 14),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      ref.read(stationsProvider.notifier).fetchStations();
                                    },
                                    icon: const Icon(Icons.search_rounded, size: 18),
                                    label: const Text('Choose Another Charger', style: TextStyle(fontWeight: FontWeight.bold)),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      side: const BorderSide(color: Colors.red),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // STEP 4: Start Charging Action Button with Full Safety Validations
                Builder(
                  builder: (context) {
                    final bool canStart = hasMinBalance &&
                                          _selectedStation != null &&
                                          statusInfo.isStartable &&
                                          !_isStartingSession;

                    String buttonText = 'Start Charging Now';
                    if (_isStartingSession) {
                      buttonText = 'Initializing Session...';
                    } else if (!hasMinBalance) {
                      buttonText = 'Minimum ₹50 Balance Required';
                    } else if (statusInfo.status == ConnectorStatus.faulted) {
                      buttonText = 'Charger Faulted (Disabled)';
                    } else if (statusInfo.status == ConnectorStatus.unavailable) {
                      buttonText = 'Charger Unavailable (Disabled)';
                    } else if (statusInfo.status == ConnectorStatus.charging) {
                      buttonText = 'Connector In Use (Disabled)';
                    } else if (!statusInfo.isStartable) {
                      buttonText = '${statusInfo.label} (Disabled)';
                    }

                    return SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: canStart
                            ? () async {
                                setState(() => _isStartingSession = true);
                                try {
                                  // Pre-start backend status confirmation
                                  await ref.read(stationsProvider.notifier).fetchStations();
                                  final latestStation = ref.read(stationsProvider).value?.firstWhere(
                                        (s) => s.id == _selectedStation?.id,
                                        orElse: () => _selectedStation!,
                                      );
                                  final latestConn = latestStation?.connectors.firstWhere(
                                        (c) => c.id == _selectedConnector?.id,
                                        orElse: () => _selectedConnector!,
                                      );
                                  final latestStatus = ConnectorStatusInfo.fromRaw(latestConn?.status);

                                  if (!latestStatus.isStartable) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Cannot start: Connector is currently ${latestStatus.label}.'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                    return;
                                  }

                                  await ref.read(chargingSessionProvider.notifier).startCharging(
                                        stationName: _selectedStation?.name,
                                        chargerId: _selectedConnector?.chargerId,
                                        connectorType: _selectedConnector?.type,
                                        connectorId: _selectedConnector?.id,
                                      );
                                  if (context.mounted) {
                                    context.go('/live-charging');
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Failed to start session: $e'), backgroundColor: Colors.red),
                                    );
                                  }
                                } finally {
                                  if (mounted) setState(() => _isStartingSession = false);
                                }
                              }
                            : null,
                        icon: _isStartingSession
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.power_settings_new_rounded, color: Colors.white, size: 22),
                        label: Text(
                          buttonText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: canStart ? const Color(0xFF16A34A) : Colors.grey,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
