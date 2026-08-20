import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/home_providers.dart';
import '../models/station.dart';
import '../../../core/providers/app_config_provider.dart';
import '../../../core/providers/core_providers.dart';
import '../widgets/app_header.dart';
import '../widgets/search_section_widget.dart';
import '../widgets/quick_actions_widget.dart';
import '../widgets/wallet_card_widget.dart';
import '../widgets/nearby_station_card.dart';
import '../widgets/promo_banner_widget.dart';
import '../../charging/screens/start_charging_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _searchQuery = '';
  Timer? _activeSessionTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Safely check active session & refresh wallet post-frame layout
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(chargingSessionProvider.notifier).checkActiveSession();
        ref.invalidate(walletBalanceAsyncProvider);
        ref.invalidate(unreadNotificationCountAsyncProvider);
      }
    });

    // Refresh active session periodically while Home Screen is visible
    _activeSessionTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) {
        ref.read(chargingSessionProvider.notifier).checkActiveSession();
      }
    });
  }

  @override
  void dispose() {
    _activeSessionTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(chargingSessionProvider.notifier).checkActiveSession();
          ref.invalidate(walletBalanceAsyncProvider);
          ref.invalidate(unreadNotificationCountAsyncProvider);
          ref.read(stationsProvider.notifier).fetchStations();
        }
      });
    }
  }

  Future<void> _handleStationClick(BuildContext context, ChargingStation station) async {
    await ref.read(chargingSessionProvider.notifier).checkActiveSession();
    final activeState = ref.read(chargingSessionProvider);

    if (!mounted) return;

    if (activeState.isCharging) {
      context.push('/live-charging');
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StartChargingScreen(
            stationId: station.id,
            connectorId: station.connectors.isNotEmpty ? station.connectors.first.id : null,
            chargerId: station.connectors.isNotEmpty ? station.connectors.first.chargerId : null,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stationsAsync = ref.watch(stationsProvider);
    final appConfig = ref.watch(appConfigProvider);

    return Scaffold(
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
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  'AR',
                  style: TextStyle(
                    color: Color(0xFF16A34A),
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.electric_car_rounded, color: Color(0xFF16A34A)),
              title: const Text('My Vehicles'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.bookmark_border_rounded, color: Color(0xFF16A34A)),
              title: const Text('Saved Stations'),
              onTap: () {
                Navigator.pop(context);
                context.go('/map');
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long_rounded, color: Color(0xFF16A34A)),
              title: const Text('Charging History'),
              onTap: () {
                Navigator.pop(context);
                context.go('/charging-history');
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF16A34A)),
              title: const Text('EcoMargin Wallet'),
              onTap: () async {
                Navigator.pop(context);
                await context.push('/wallet');
                ref.invalidate(walletBalanceAsyncProvider);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings_outlined, color: Color(0xFF16A34A)),
              title: const Text('Settings'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.help_outline_rounded, color: Color(0xFF16A34A)),
              title: const Text('Help & Support'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF16A34A),
          onRefresh: () async {
            ref.invalidate(walletBalanceAsyncProvider);
            await ref.read(chargingSessionProvider.notifier).checkActiveSession();
            await ref.read(stationsProvider.notifier).fetchStations();
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // 1. App Header Section
              SliverToBoxAdapter(
                child: AppHeader(
                  onMenuPressed: () {
                    _scaffoldKey.currentState?.openDrawer();
                  },
                  onNotificationPressed: () async {
                    await context.push('/notifications');
                    ref.invalidate(unreadNotificationCountAsyncProvider);
                    ref.invalidate(notificationsProvider);
                  },
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // 2. Wallet Card Section (Top Priority EV App Layout)
              if (appConfig.walletCardEnabled) ...[
                SliverToBoxAdapter(
                  child: WalletCardWidget(
                    onAddMoneyPressed: () async {
                      await context.push('/add-money');
                      ref.invalidate(walletBalanceAsyncProvider);
                    },
                    onTransactionHistoryPressed: () async {
                      await context.push('/wallet');
                      ref.invalidate(walletBalanceAsyncProvider);
                    },
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
              ],

              // 3. Active Charging Session Card ("Charging Now")
              ...[
                Consumer(
                  builder: (context, ref, child) {
                    final sessionState = ref.watch(chargingSessionProvider);
                    if (!sessionState.isCharging) return const SliverToBoxAdapter(child: SizedBox.shrink());

                    return SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Material(
                          color: isDark ? const Color(0xFF0F291E) : const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(16),
                          clipBehavior: Clip.antiAlias,
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark ? const Color(0xFF166534) : const Color(0xFF86EFAC),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF16A34A).withOpacity(0.06),
                                  blurRadius: 12,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title Header Row: ⚡ Charging Now + Active Indicator
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Text(
                                          '⚡',
                                          style: TextStyle(fontSize: 16),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Charging Now',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D),
                                          ),
                                        ),
                                      ],
                                    ),
                                    // Subtle Active Indicator Badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF16A34A).withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFF16A34A),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Text(
                                            'ACTIVE',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF16A34A),
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),

                                // Station Name
                                Text(
                                  sessionState.stationName,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),

                                const SizedBox(height: 10),

                                // Data Metrics Row: SOC | Energy | Cost
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF1E293B).withOpacity(0.6) : Colors.white.withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      // SOC: XX%
                                      Row(
                                        children: [
                                          const Icon(Icons.battery_charging_full_rounded, size: 14, color: Color(0xFF16A34A)),
                                          const SizedBox(width: 4),
                                          Text(
                                            'SOC: ${sessionState.percentage.toInt()}%',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Container(height: 12, width: 1, color: isDark ? Colors.white24 : Colors.black12),
                                      // Energy: XX.XX kWh
                                      Row(
                                        children: [
                                          const Icon(Icons.bolt_rounded, size: 14, color: Color(0xFF16A34A)),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Energy: ${sessionState.kwhDelivered.toStringAsFixed(2)} kWh',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Container(height: 12, width: 1, color: isDark ? Colors.white24 : Colors.black12),
                                      // Cost: ₹XXX.XX
                                      Row(
                                        children: [
                                          const Icon(Icons.currency_rupee_rounded, size: 13, color: Color(0xFF16A34A)),
                                          Text(
                                            'Cost: ₹${sessionState.totalCost.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 10),

                                // View Charging Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 38,
                                  child: ElevatedButton(
                                    onPressed: () => context.push('/live-charging'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF16A34A),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: EdgeInsets.zero,
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.bolt_rounded, size: 16, color: Colors.white),
                                        SizedBox(width: 6),
                                        Text(
                                          'View Charging',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                        Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.white),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],

              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              // 4. Search Section (Admin Configurable)
              if (appConfig.searchSectionEnabled) ...[
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
              ],

              // 5. Nearby Stations Section
              if (appConfig.nearbyStationsEnabled) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Nearby Chargers',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.go('/map'),
                          child: const Row(
                            children: [
                              Text(
                                'View on Map',
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

                // Nearby Stations List
                stationsAsync.when(
                  data: (stations) {
                    final filtered = stations.where((s) {
                      return s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                          s.address.toLowerCase().contains(_searchQuery.toLowerCase());
                    }).toList();

                    if (filtered.isEmpty) {
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Center(
                            child: Column(
                              children: [
                                const Icon(Icons.ev_station_outlined, size: 44, color: Colors.grey),
                                const SizedBox(height: 12),
                                Text(
                                  _searchQuery.isEmpty ? 'No charging stations found nearby.' : 'No stations found matching "$_searchQuery"',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
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
                                _handleStationClick(context, station);
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
                        height: 140,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(color: Color(0xFF16A34A)),
                              SizedBox(height: 12),
                              Text(
                                'Loading nearby chargers...',
                                style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  error: (err, stack) {
                    final errStr = err.toString().toLowerCase();
                    final isLocationErr = errStr.contains('location') || errStr.contains('permission') || errStr.contains('gps');
                    final titleText = isLocationErr
                        ? 'Unable to determine your location'
                        : 'Unable to load nearby chargers';
                    final bodyText = isLocationErr
                        ? 'Please enable location permission to discover charging stations near you.'
                        : 'Please check your network connection and try again.';

                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: [
                              Icon(isLocationErr ? Icons.location_off_rounded : Icons.error_outline_rounded, size: 36, color: Colors.red),
                              const SizedBox(height: 8),
                              Text(
                                titleText,
                                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                bodyText,
                                style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: () {
                                  ref.read(stationsProvider.notifier).fetchStations();
                                },
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 12)),
              ],

              // 6. Quick Actions Section (Admin Configurable)
              if (appConfig.quickActionsEnabled) ...[
                SliverToBoxAdapter(
                  child: QuickActionsWidget(
                    onScanQr: () => context.go('/map'),
                    onFavorites: () => context.go('/map'),
                    onHistory: () => context.go('/charging-history'),
                    onWallet: () async {
                      await context.push('/wallet');
                      ref.invalidate(walletBalanceAsyncProvider);
                    },
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
              ],

              // 7. Promotional Banner (Admin Configurable)
              if (appConfig.promoBannerEnabled) ...[
                const SliverToBoxAdapter(
                  child: PromoBannerWidget(),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ],
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
                    selectedColor: const Color(0xFF16A34A).withOpacity(0.2),
                  ),
                  FilterChip(
                    label: const Text('Available Now'),
                    selected: true,
                    onSelected: (val) {},
                    selectedColor: const Color(0xFF16A34A).withOpacity(0.2),
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
