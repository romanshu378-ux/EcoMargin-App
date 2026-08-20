import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/utils/connector_status.dart';
import '../../home/providers/home_providers.dart';
import '../../home/models/station.dart';

class StartChargingScreen extends ConsumerStatefulWidget {
  final ChargingStation? station;
  final String? connectorId;
  final String? chargerId;
  final String? stationId;

  const StartChargingScreen({
    super.key,
    this.station,
    this.connectorId,
    this.chargerId,
    this.stationId,
  });

  @override
  ConsumerState<StartChargingScreen> createState() => _StartChargingScreenState();
}

class _StartChargingScreenState extends ConsumerState<StartChargingScreen> with WidgetsBindingObserver {
  ChargingStation? _selectedStation;
  StationConnector? _selectedConnector;
  bool _isStartingSession = false;
  bool _hasInitialLoaded = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selectedStation = widget.station;
    if (widget.station != null && widget.station!.connectors.isNotEmpty) {
      _selectedConnector = widget.station!.connectors.firstWhere(
        (c) => c.id == widget.connectorId,
        orElse: () => widget.station!.connectors.first,
      );
    }

    // Safely defer provider state modifications after post-frame build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_hasInitialLoaded) {
        _hasInitialLoaded = true;
        _fetchAndResolveStation();
        _startPeriodicRefresh();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.invalidate(walletBalanceAsyncProvider);
          _fetchAndResolveStation();
        }
      });
    }
  }

  void _startPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted && !_isStartingSession) {
        ref.read(stationsProvider.notifier).fetchStations();
      }
    });
  }

  Future<void> _fetchAndResolveStation() async {
    if (!mounted) return;
    try {
      await ref.read(stationsProvider.notifier).fetchStations();
      if (!mounted) return;

      final stations = ref.read(stationsProvider).value;
      if (stations != null && stations.isNotEmpty) {
        final targetId = widget.stationId ?? widget.station?.id;
        final matched = stations.firstWhere(
          (s) => s.id == targetId,
          orElse: () => _selectedStation ?? stations.first,
        );

        if (mounted) {
          setState(() {
            _selectedStation = matched;
            if (matched.connectors.isNotEmpty) {
              _selectedConnector = matched.connectors.firstWhere(
                (c) => c.id == widget.connectorId && ConnectorStatusInfo.fromRaw(c.status).isStartable,
                orElse: () => matched.connectors.firstWhere(
                  (c) => ConnectorStatusInfo.fromRaw(c.status).isStartable,
                  orElse: () => matched.connectors.first,
                ),
              );
              if (!ConnectorStatusInfo.fromRaw(_selectedConnector?.status).isStartable) {
                _selectedConnector = null;
              }
            } else {
              _selectedConnector = null;
            }
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _openMapNavigation(double lat, double lng) async {
    final Uri googleMapsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open map application')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open map: $e')),
        );
      }
    }
  }

  String _formatAmount(double amount) {
    return NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2).format(amount);
  }

  Future<void> _handleStartCharging(double walletBalance) async {
    if (_isStartingSession || !mounted) return;
    setState(() => _isStartingSession = true);

    try {
      // Step 1: Re-check wallet balance from backend
      ref.invalidate(walletBalanceAsyncProvider);
      final freshBalance = await ref.read(walletBalanceAsyncProvider.future);
      if (freshBalance < 50.0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Minimum ₹50 wallet balance required to start charging.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Step 2: Verify active session on backend
      await ref.read(chargingSessionProvider.notifier).checkActiveSession();
      final activeState = ref.read(chargingSessionProvider);
      if (activeState.isCharging) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Active Session Exists'),
              content: const Text('Your account already has an active charging session.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.go('/live-charging');
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16A34A)),
                  child: const Text('View Charging', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        }
        return;
      }

      // Step 3: Refresh connector status from backend
      await ref.read(stationsProvider.notifier).fetchStations();
      if (!mounted) return;
      final latestStations = ref.read(stationsProvider).value;
      ChargingStation? latestStation;
      StationConnector? latestConn;

      if (latestStations != null && _selectedStation != null) {
        latestStation = latestStations.firstWhere((s) => s.id == _selectedStation!.id, orElse: () => _selectedStation!);
        if (_selectedConnector != null) {
          try {
            latestConn = latestStation.connectors.firstWhere((c) => c.id == _selectedConnector!.id);
          } catch (_) {
            latestConn = null;
          }
        }
      }

      final latestStatusInfo = ConnectorStatusInfo.fromRaw(latestConn?.status);
      if (!latestStatusInfo.isStartable) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Connector is no longer available (${latestStatusInfo.label}). Please select an available connector.'),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'Refresh',
                textColor: Colors.white,
                onPressed: () {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _fetchAndResolveStation();
                  });
                },
              ),
            ),
          );
        }
        return;
      }

      // Step 4: Dispatch start charging command to backend
      await ref.read(chargingSessionProvider.notifier).startCharging(
            stationName: _selectedStation?.name,
            chargerId: _selectedConnector?.chargerId,
            connectorType: _selectedConnector?.type,
            connectorId: _selectedConnector?.id,
          );

      if (mounted) {
        context.go('/live-charging');
      }
    } catch (e) {
      if (mounted) {
        // Auto-refresh station availability and session status immediately on error/conflict
        ref.read(stationsProvider.notifier).fetchStations();
        ref.read(chargingSessionProvider.notifier).checkActiveSession();

        String errorMsg = "Unable to start charging session. Please refresh and try again.";
        String? errorCode;

        if (e is DioException) {
          debugPrint("START CHARGING HTTP STATUS: ${e.response?.statusCode}");
          debugPrint("START CHARGING RESPONSE DATA: ${e.response?.data}");
          debugPrint("START CHARGING URL: ${e.requestOptions.uri}");

          if (e.response?.data is Map) {
            final Map errMap = e.response!.data as Map;
            errorCode = errMap['code']?.toString();
            if (errMap['message'] != null) {
              errorMsg = errMap['message'].toString();
            }
          }
        } else {
          errorMsg = e.toString();
        }

        if (errorCode == 'ACTIVE_SESSION_EXISTS') {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Active Session Running'),
              content: const Text('You already have an active charging session in progress.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    context.go('/live-charging');
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16A34A), foregroundColor: Colors.white),
                  child: const Text('View Charging'),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isStartingSession = false);
    }
  }

  Widget _buildSkeletonLoading(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Station Card Skeleton
        Container(
          height: 140,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 16,
                          width: 180,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 12,
                          width: 120,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    height: 14,
                    width: 100,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  Container(
                    height: 14,
                    width: 60,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Wallet Skeleton
        Container(
          height: 70,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 14,
                    width: 140,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 10,
                    width: 100,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Header Skeleton
        Container(
          height: 16,
          width: 140,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
        ),

        const SizedBox(height: 16),

        // Skeleton Connector Cards
        ...List.generate(
          2,
          (index) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            height: 90,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 14,
                        width: 120,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 10,
                        width: 80,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
                const CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF16A34A)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final walletAsync = ref.watch(walletBalanceAsyncProvider);
    final currentWalletBalance = ref.watch(walletBalanceProvider);
    final stationsAsync = ref.watch(stationsProvider);

    final double walletBalance = walletAsync.maybeWhen(
      data: (bal) => bal,
      orElse: () => currentWalletBalance,
    );

    const double minRequiredBalance = 50.0;
    final bool hasMinBalance = walletBalance >= minRequiredBalance;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Start Charging'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  ref.invalidate(walletBalanceAsyncProvider);
                  _fetchAndResolveStation();
                }
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF16A34A),
          onRefresh: () async {
            ref.invalidate(walletBalanceAsyncProvider);
            await _fetchAndResolveStation();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20.0),
            child: (stationsAsync.isLoading && _selectedStation == null)
                ? _buildSkeletonLoading(isDark)
                : (stationsAsync.hasError && _selectedStation == null)
                    ? Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
                            const SizedBox(height: 12),
                            const Text(
                              'Unable to load connector status',
                              style: TextStyle(color: Colors.red, fontSize: 14, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Please check your network connection and try again.',
                              style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: () {
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  if (mounted) {
                                    _fetchAndResolveStation();
                                  }
                                });
                              },
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : Builder(
                        builder: (context) {
                          final stations = stationsAsync.value ?? [];
                          if (_selectedStation == null && stations.isNotEmpty) {
                            final targetId = widget.stationId ?? widget.station?.id;
                            _selectedStation = stations.firstWhere(
                              (s) => s.id == targetId,
                              orElse: () => stations.first,
                            );
                          }

                          if (_selectedStation != null && _selectedConnector == null && _selectedStation!.connectors.isNotEmpty) {
                            _selectedConnector = _selectedStation!.connectors.firstWhere(
                              (c) => c.id == widget.connectorId,
                              orElse: () => _selectedStation!.connectors.first,
                            );
                          }

                if (_selectedStation == null) {
                  return Container(
                    padding: const EdgeInsets.all(30),
                    child: Column(
                      children: [
                        const Icon(Icons.ev_station_rounded, size: 48, color: Colors.grey),
                        const SizedBox(height: 12),
                        const Text('No charging station details found.', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) _fetchAndResolveStation();
                            });
                          },
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final station = _selectedStation!;
                final selectedStatusInfo = ConnectorStatusInfo.fromRaw(_selectedConnector?.status);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // SECTION 1: Selected Station Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF16A34A).withOpacity(0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.ev_station_rounded, color: Color(0xFF16A34A), size: 28),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      station.name,
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF64748B)),
                                        const SizedBox(width: 2),
                                        Expanded(
                                          child: Text(
                                            station.address,
                                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),
                          const Divider(height: 1),
                          const SizedBox(height: 16),

                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 12,
                            runSpacing: 10,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.flash_on_rounded, color: Color(0xFF16A34A), size: 18),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${station.chargerType} (${station.chargerCategory})',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF16A34A).withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      station.priceStr.isNotEmpty ? station.priceStr : 'Pricing unavailable',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton.icon(
                                    onPressed: () => _openMapNavigation(station.latitude, station.longitude),
                                    icon: const Icon(Icons.navigation_rounded, size: 16),
                                    label: const Text('Navigate', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF16A34A),
                                      side: const BorderSide(color: Color(0xFF16A34A)),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // SECTION 2: Wallet Balance Eligibility Check
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: hasMinBalance
                            ? (isDark ? const Color(0xFF0F291E) : const Color(0xFFF0FDF4))
                            : (isDark ? const Color(0xFF311414) : const Color(0xFFFEF2F2)),
                        borderRadius: BorderRadius.circular(18),
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
                                  hasMinBalance ? 'Wallet Balance Eligible' : 'Minimum ₹50 Wallet Balance Required',
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
                                  'Current Balance: ${_formatAmount(walletBalance)} (Min: ₹50.00)',
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

                    if (walletBalance >= 50.0 && walletBalance < 100.0) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2D2305) : const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.5)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 16),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Your wallet balance is low. Consider topping up before starting long sessions.',
                                style: TextStyle(fontSize: 11, color: Color(0xFFD97706), fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // SECTION 3: Connectors Section Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Select Connector',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          '${station.connectors.where((c) => ConnectorStatusInfo.fromRaw(c.status).isStartable).length}/${station.connectors.length} Available',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // SECTION 4: Connectors Responsive List
                    if (station.connectors.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          'No connectors available at this station.',
                          style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      Column(
                        children: station.connectors.asMap().entries.map((entry) {
                          final int index = entry.key + 1;
                          final conn = entry.value;
                          final isSelected = _selectedConnector?.id == conn.id;
                          final cInfo = ConnectorStatusInfo.fromRaw(conn.status);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              onTap: () {
                                if (cInfo.isStartable) {
                                  setState(() => _selectedConnector = conn);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Connector #$index is currently ${cInfo.label}. Please select an AVAILABLE connector.'),
                                      backgroundColor: Colors.orange.shade800,
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );
                                }
                              },
                              borderRadius: BorderRadius.circular(18),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isSelected ? cInfo.color.withOpacity(0.08) : (isDark ? const Color(0xFF1E293B) : Colors.white),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: isSelected ? cInfo.color : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: cInfo.color.withOpacity(0.15),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(Icons.power_rounded, color: cInfo.color, size: 24),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Connector $index (${conn.type})',
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'Rating: ${conn.maxPowerKw.toInt()} kW • ₹${conn.unitRate % 1 == 0 ? conn.unitRate.toInt() : conn.unitRate.toStringAsFixed(2)}/kWh',
                                                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Radio<String>(
                                          value: conn.id,
                                          groupValue: _selectedConnector?.id,
                                          activeColor: const Color(0xFF16A34A),
                                          onChanged: (val) {
                                            setState(() => _selectedConnector = conn);
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: cInfo.color.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(cInfo.icon, color: cInfo.color, size: 14),
                                              const SizedBox(width: 4),
                                              Text(
                                                cInfo.label,
                                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: cInfo.color),
                                              ),
                                            ],
                                          ),
                                        ),
                                        ElevatedButton(
                                          onPressed: cInfo.isStartable
                                              ? () {
                                                  setState(() => _selectedConnector = conn);
                                                }
                                              : null,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: isSelected ? const Color(0xFF16A34A) : Colors.grey.shade200,
                                            foregroundColor: isSelected ? Colors.white : Colors.black87,
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                          child: Text(
                                            cInfo.isStartable ? (isSelected ? 'Selected' : 'Select') : 'Not Available',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: cInfo.isStartable ? (isSelected ? Colors.white : const Color(0xFF0F172A)) : Colors.grey,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                    const SizedBox(height: 32),

                    // SECTION 5: Start Charging Action Button
                    Builder(
                      builder: (context) {
                        final bool canStart = hasMinBalance &&
                                              _selectedConnector != null &&
                                              selectedStatusInfo.isStartable &&
                                              !_isStartingSession;

                        String buttonText = 'Start Charging Now';
                        if (_isStartingSession) {
                          buttonText = 'Verifying & Initializing...';
                        } else if (_selectedConnector == null) {
                          buttonText = 'Select a Connector';
                        } else if (!hasMinBalance) {
                          buttonText = 'Minimum ₹50 Balance Required';
                        } else if (selectedStatusInfo.status == ConnectorStatus.faulted) {
                          buttonText = 'Charger Faulted (Disabled)';
                        } else if (selectedStatusInfo.status == ConnectorStatus.unavailable) {
                          buttonText = 'Charger Unavailable (Disabled)';
                        } else if (selectedStatusInfo.status == ConnectorStatus.charging) {
                          buttonText = 'Connector In Use (Disabled)';
                        } else if (!selectedStatusInfo.isStartable) {
                          buttonText = '${selectedStatusInfo.label} (Disabled)';
                        }

                        return SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: canStart ? () => _handleStartCharging(walletBalance) : null,
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
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
