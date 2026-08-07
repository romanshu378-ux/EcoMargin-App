import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/home_providers.dart';
import '../widgets/app_header.dart';
import '../widgets/hero_banner_slider.dart';
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

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stationsAsync = ref.watch(stationsProvider);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      drawer: Drawer(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
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
              onTap: () => Navigator.pop(context),
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
                      const SnackBar(content: Text('Notifications: 3 unread updates')),
                    );
                  },
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 8)),

              // 2. Hero Banner Slider
              SliverToBoxAdapter(
                child: HeroBannerSlider(
                  onFindStationsPressed: () => context.go('/map'),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

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

              // 4. Quick Actions Grid
              SliverToBoxAdapter(
                child: QuickActionsWidget(
                  onScanQr: () => context.go('/scan'),
                  onFavorites: () => context.go('/map'),
                  onHistory: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Opening Charging History')),
                    );
                  },
                  onWallet: () => context.go('/wallet'),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // 5. Wallet Card
              SliverToBoxAdapter(
                child: WalletCardWidget(
                  onAddMoneyPressed: () => context.go('/wallet'),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // 6. Promotional Banner
              const SliverToBoxAdapter(
                child: PromoBannerWidget(),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // Section Header: Nearby Charging Stations
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Nearby Charging Stations',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/map'),
                        child: const Text(
                          'View All',
                          style: TextStyle(
                            color: Color(0xFF16A34A),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              // 7. Nearby Stations List (SliverList with async state & skeleton fallback)
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
                              Icon(
                                Icons.ev_station_rounded,
                                size: 48,
                                color: isDark ? Colors.slate600 : Colors.slate300,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No charging stations found matching "$_searchQuery"',
                                style: TextStyle(
                                  color: isDark ? Colors.slate400 : Colors.slate500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
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
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: List.generate(
                        2,
                        (index) => Container(
                          height: 220,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(color: Color(0xFF16A34A)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                error: (err, stack) => SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Failed to load stations: $err',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),

      // 8. Bottom Navigation Bar
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          elevation: 0,
          backgroundColor: Colors.transparent,
          indicatorColor: const Color(0xFF16A34A).withOpacity(0.15),
          onDestinationSelected: (index) {
            setState(() => _currentIndex = index);
            if (index == 1) context.go('/map');
            if (index == 2) context.go('/scan');
            if (index == 3) context.go('/profile');
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded, color: Color(0xFF16A34A)),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.map_outlined),
              selectedIcon: Icon(Icons.map_rounded, color: Color(0xFF16A34A)),
              label: 'Map',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_today_outlined),
              selectedIcon: Icon(Icons.calendar_today_rounded, color: Color(0xFF16A34A)),
              label: 'Bookings',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded, color: Color(0xFF16A34A)),
              label: 'Profile',
            ),
          ],
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
                    label: const Text('DC Fast (>100 kW)'),
                    selected: true,
                    onSelected: (val) {},
                    selectedColor: const Color(0xFF16A34A).withOpacity(0.2),
                  ),
                  FilterChip(
                    label: const Text('AC Standard (22 kW)'),
                    selected: false,
                    onSelected: (val) {},
                  ),
                  FilterChip(
                    label: const Text('Available Now'),
                    selected: true,
                    onSelected: (val) {},
                    selectedColor: const Color(0xFF16A34A).withOpacity(0.2),
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
                      borderRadius: BorderRadius.circular(14),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(station.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(station.address),
            const SizedBox(height: 12),
            Text('Charger Type: ${station.chargerType}', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Available: ${station.availableChargers} of ${station.totalChargers} connectors'),
            Text('Price: \$${station.pricePerKwh}/kWh', style: const TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold)),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Start Charging', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
