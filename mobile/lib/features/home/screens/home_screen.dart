import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/home_providers.dart';
import '../../../core/providers/app_config_provider.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/utils/connector_status.dart';
import '../widgets/app_header.dart';
import '../widgets/search_section_widget.dart';
import '../widgets/quick_actions_widget.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(walletBalanceAsyncProvider);
      ref.read(stationsProvider.notifier).fetchStations();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stationsAsync = ref.watch(stationsProvider);
    final appConfig = ref.watch(appConfigProvider);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: Drawer(
        backgroundColor: Colors.white,
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
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.help_outline_rounded, color: Color(0xFF16A34A)),
              title: const Text('Customer Support'),
              onTap: () {
                Navigator.pop(context);
                context.go('/help');
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
            ref.invalidate(walletBalanceAsyncProvider);
            await ref.read(stationsProvider.notifier).fetchStations();
            await ref.read(appConfigProvider.notifier).fetchAppConfig();
          },
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. Maintenance Alert Banner if Maintenance Mode Enabled by Admin
              if (appConfig.maintenanceEnabled)
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    color: Colors.amber.shade800,
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.white),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            appConfig.maintenanceMessage,
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // 2. App Header (Logo, Tagline, Hamburger Menu, Notification Bell)
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

              const SliverToBoxAdapter(child: SizedBox(height: 14)),

              // 3. Featured Wallet Balance Card (Replaces Hero Banner)
              SliverToBoxAdapter(
                child: WalletCardWidget(
                  onAddMoneyPressed: () async {
                    await context.push('/add-money');
                    ref.invalidate(walletBalanceAsyncProvider);
                  },
                  onTransactionHistoryPressed: () async {
                    await context.push('/transactions');
                    ref.invalidate(walletBalanceAsyncProvider);
                  },
                ),
              ),

              // Persistent Active Charging Status Card
              if (ref.watch(chargingSessionProvider).isCharging) ...[
                const SliverToBoxAdapter(child: SizedBox(height: 14)),
                Builder(
                  builder: (context) {
                    final session = ref.watch(chargingSessionProvider);
                    final walletBal = ref.watch(walletBalanceProvider);
                    final isDark = Theme.of(context).brightness == Brightness.dark;
                    final durationMins = session.durationSeconds ~/ 60;
                    final isLowBalance = walletBal < 50.0;
                    final timeAgo = session.lastUpdated != null
                        ? '${DateTime.now().difference(session.lastUpdated!).inSeconds}s ago'
                        : 'Just now';

                    return SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? [const Color(0xFF0F291E), const Color(0xFF064E3B)]
                                : [const Color(0xFFF0FDF4), const Color(0xFFDCFCE7)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF16A34A), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF16A34A).withOpacity(0.15),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.bolt_rounded, color: Color(0xFF16A34A), size: 22),
                                    const SizedBox(width: 6),
                                    Text(
                                      '⚡ Charging Now',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : const Color(0xFF15803D),
                                      ),
                                    ),
                                  ],
                                ),
                                 Builder(
                                  builder: (context) {
                                    final statusInfo = ConnectorStatusInfo.fromRaw(session.status);
                                    final isFaulted = statusInfo.status == ConnectorStatus.faulted;
                                    final badgeText = session.hasConnectionError
                                        ? 'Connection lost. Reconnecting...'
                                        : statusInfo.label;
                                    final badgeColor = isFaulted ? Colors.red : statusInfo.color;

                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: badgeColor.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        badgeText,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: badgeColor,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    session.stationName.isNotEmpty ? session.stationName : 'EcoMargin Charging Hub',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  'Last updated $timeAgo',
                                  style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${session.percentage.toInt()}% SOC',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                                ),
                                Text(
                                  '${session.kwhDelivered.toStringAsFixed(2)} kWh',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '$durationMins min',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '₹${session.totalCost.toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Wallet: ₹${walletBal.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isLowBalance ? Colors.orange.shade800 : const Color(0xFF64748B),
                                  ),
                                ),
                                if (isLowBalance)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      '⚠️ Low wallet balance',
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              height: 44,
                              child: ElevatedButton.icon(
                                onPressed: () => context.push('/live-charging'),
                                icon: const Icon(Icons.flash_on_rounded, size: 18, color: Colors.white),
                                label: const Text('View Charging', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF16A34A),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

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

              // 5. Nearby Stations Section (Admin Configurable)
              if (appConfig.nearbyStationsEnabled) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Nearby Stations',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.go('/map'),
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
                                _showStationDetailsDialog(context, station);
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
                      child: Text(
                        'Failed to load stations: $err',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 12)),
              ],

              // 6. Quick Actions Section (Admin Configurable)
              if (appConfig.quickActionsEnabled) ...[
                SliverToBoxAdapter(
                  child: QuickActionsWidget(
                    onScanQr: () => context.go('/scan'),
                    onFavorites: () => context.go('/map'),
                    onHistory: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Opening Charging History')),
                      );
                    },
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

  void _showStationDetailsDialog(BuildContext context, station) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(station.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(station.address, style: const TextStyle(color: Color(0xFF64748B))),
            const SizedBox(height: 12),
            Text('Charger: ${station.chargerType} (${station.chargerCategory})', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Available Connectors: ${station.availableChargers} / ${station.totalChargers}'),
            const SizedBox(height: 4),
            Text('Rate: ${station.priceStr}', style: const TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/scan');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Start Charging', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
