import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../providers/home_providers.dart';
import '../../../core/providers/core_providers.dart';
import '../widgets/app_header.dart';
import '../widgets/search_section_widget.dart';
import '../widgets/wallet_card_widget.dart';
import '../widgets/nearby_station_card.dart';
import '../widgets/promo_banner_widget.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _searchQuery = '';
  Position? _currentPosition;
  bool _isLoadingLocation = true;
  bool _locationError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _determinePosition();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _determinePosition();
      ref.read(chargingSessionProvider.notifier).syncWithBackend();
    }
  }

  Future<void> _determinePosition() async {
    if (!mounted) return;
    setState(() {
      _isLoadingLocation = true;
      _locationError = false;
    });
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _isLoadingLocation = false;
            _locationError = true;
          });
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() {
              _isLoadingLocation = false;
              _locationError = true;
            });
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _isLoadingLocation = false;
            _locationError = true;
          });
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) {
        setState(() {
          _currentPosition = position;
          _isLoadingLocation = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
          _locationError = true;
        });
      }
    }
  }

  double _calculateDistanceKm(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000.0;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stationsAsync = ref.watch(stationsProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {},
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        drawer: Drawer(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              UserAccountsDrawerHeader(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF16A34A), Color(0xFF15803D)],
                  ),
                ),
                accountName: const Text(
                  'Alex Rivers',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                accountEmail: const Text('driver@ecomargin.com'),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Text(
                    'AR',
                    style: TextStyle(
                      color: const Color(0xFF16A34A),
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.electric_car_rounded, color: Color(0xFF16A34A)),
                title: Text('My Vehicles', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/vehicles');
                },
              ),
              ListTile(
                leading: const Icon(Icons.bookmark_border_rounded, color: Color(0xFF16A34A)),
                title: Text('Saved Stations', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/map');
                },
              ),
              ListTile(
                leading: const Icon(Icons.receipt_long_rounded, color: Color(0xFF16A34A)),
                title: Text('Charging History', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/charging-history');
                },
              ),
              ListTile(
                leading: const Icon(Icons.help_outline_rounded, color: Color(0xFF16A34A)),
                title: Text('Customer Support', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/help');
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout_rounded, color: Colors.red),
                title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/login');
                },
              ),
            ],
          ),
        ),
        body: SafeArea(
          child: RefreshIndicator(
            color: const Color(0xFF16A34A),
            onRefresh: () async {
              await ref.read(stationsProvider.notifier).fetchStations();
              await _determinePosition();
            },
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // 1. App Header
                SliverToBoxAdapter(
                  child: AppHeader(
                    onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
                    onNotificationPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Notifications: 1 new alert')),
                      );
                    },
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 12)),

                // 2. EcoMargin Wallet Hero Card (Replaces HeroBannerSlider completely)
                SliverToBoxAdapter(
                  child: WalletCardWidget(
                    onAddMoneyPressed: () => context.push('/add-money'),
                    onViewWalletPressed: () => context.push('/wallet'),
                  ),
                ),

                const SliverToBoxAdapter(
                  child: ActiveChargingCard(),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // 3. Search Section
                SliverToBoxAdapter(
                  child: SearchSectionWidget(
                    onSearchChanged: (val) {
                      setState(() => _searchQuery = val);
                    },
                    onFilterPressed: () {
                      _showFilterBottomSheet(context);
                    },
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 20)),

                // 4. Nearby Stations Header & View All
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Nearby Charging Stations',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.push('/map'),
                          child: const Row(
                            children: [
                              Text(
                                'View all',
                                style: TextStyle(
                                  color: Color(0xFF16A34A),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              SizedBox(width: 2),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: Color(0xFF16A34A),
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 12)),

                // 5. Nearby Stations List
                _isLoadingLocation
                    ? SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CircularProgressIndicator(color: Color(0xFF16A34A)),
                                const SizedBox(height: 12),
                                Text(
                                  'Finding nearest stations...',
                                  style: TextStyle(
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : _locationError
                        ? SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.location_off_rounded,
                                      size: 48,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Location Permission Required',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Please enable location access to see the nearest charging stations.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      onPressed: _determinePosition,
                                      icon: const Icon(Icons.my_location_rounded, size: 16, color: Colors.white),
                                      label: const Text('Allow Location Access', style: TextStyle(color: Colors.white)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF16A34A),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        : stationsAsync.when(
                            data: (stations) {
                              // Calculate dynamic distance for each station
                              final sortedStations = stations.map((station) {
                                if (_currentPosition != null) {
                                  final dist = _calculateDistanceKm(
                                    _currentPosition!.latitude,
                                    _currentPosition!.longitude,
                                    station.latitude,
                                    station.longitude,
                                  );
                                  return station.copyWith(distanceStr: '${dist.toStringAsFixed(1)} km');
                                }
                                return station;
                              }).toList();

                              // Sort by distance in ascending order (nearest first)
                              if (_currentPosition != null) {
                                sortedStations.sort((a, b) {
                                  final distA = double.tryParse(a.distanceStr.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
                                  final distB = double.tryParse(b.distanceStr.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
                                  return distA.compareTo(distB);
                                });
                              }

                              final filtered = sortedStations.where((s) {
                                return s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                                    s.address.toLowerCase().contains(_searchQuery.toLowerCase());
                              }).toList();

                              if (filtered.isEmpty) {
                                return SliverToBoxAdapter(
                                  child: Padding(
                                    padding: const EdgeInsets.all(32),
                                    child: Center(
                                      child: Text(
                                        'No stations found matching "$_searchQuery"',
                                        style: TextStyle(
                                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }

                              return SliverPadding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                sliver: SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) {
                                      final station = filtered[index];
                                      return NearbyStationCard(
                                        station: station,
                                        onFavoriteToggle: () {
                                          ref.read(stationsProvider.notifier).toggleFavorite(station.id);
                                        },
                                        onViewDetails: () {
                                          context.push('/station-details', extra: station.id);
                                        },
                                      );
                                    },
                                    childCount: filtered.length,
                                  ),
                                ),
                              );
                            },
                            loading: () => SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Container(
                                  height: 180,
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(color: Color(0xFF16A34A)),
                                  ),
                                ),
                              ),
                            ),
                            error: (err, stack) => SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Center(
                                  child: Text(
                                    'Failed to load stations: $err',
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ),
                              ),
                            ),
                          ),

                const SliverToBoxAdapter(child: SizedBox(height: 12)),

                // 6. Promotional Banner
                const SliverToBoxAdapter(
                  child: PromoBannerWidget(),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter Chargers',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: const Text('DC Fast (>60 kW)'),
                    selected: true,
                    onSelected: (val) {},
                    selectedColor: const Color(0xFF16A34A).withValues(alpha: 0.2),
                  ),
                  FilterChip(
                    label: const Text('Available Now'),
                    selected: true,
                    onSelected: (val) {},
                    selectedColor: const Color(0xFF16A34A).withValues(alpha: 0.2),
                  ),
                  FilterChip(
                    label: const Text('AC Type 2'),
                    selected: false,
                    onSelected: (val) {},
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Apply Filters', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class AnimatedPulseDot extends StatefulWidget {
  const AnimatedPulseDot({super.key});

  @override
  State<AnimatedPulseDot> createState() => _AnimatedPulseDotState();
}

class _AnimatedPulseDotState extends State<AnimatedPulseDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Color(0xFF16A34A),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class ActiveChargingCard extends ConsumerWidget {
  const ActiveChargingCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(chargingSessionProvider);
    if (!session.isCharging) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final minutes = session.durationSeconds ~/ 60;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Title & Pulse
            Row(
              children: [
                const AnimatedPulseDot(),
                const SizedBox(width: 8),
                Text(
                  '⚡ Active Charging',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A),
                  ),
                ),
                const Spacer(),
                Text(
                  '${session.percentage.toInt()}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Station Name & Address
            Text(
              session.stationName,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.flash_on_rounded,
                  size: 14,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
                const SizedBox(width: 4),
                Text(
                  '${session.connectorType} • ${session.currentPowerKw.toStringAsFixed(1)} kW',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            if (session.hasConnectionError) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Unable to sync charging status. Please check your connection.',
                        style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const Divider(height: 24),

            // Metrics Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMiniMetric(
                  context,
                  'Delivered',
                  '${session.kwhDelivered.toStringAsFixed(1)} kWh',
                ),
                _buildMiniMetric(
                  context,
                  'Duration',
                  '$minutes min',
                ),
                _buildMiniMetric(
                  context,
                  'Current Cost',
                  '₹${session.totalCost.toStringAsFixed(2)}',
                  valueColor: const Color(0xFF16A34A),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Action Button: View Details
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () {
                  context.push(
                    '/live-charging',
                    extra: {
                      'stationId': 'st-01',
                      'sessionId': 'sess-${session.chargerId}',
                      'connectorId': session.connectorType,
                      'chargerId': session.chargerId,
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Flexible(
                      child: Text(
                        'View Charging',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniMetric(BuildContext context, String label, String value, {Color? valueColor}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: valueColor ?? (isDark ? Colors.white : const Color(0xFF0F172A)),
          ),
        ),
      ],
    );
  }
}
