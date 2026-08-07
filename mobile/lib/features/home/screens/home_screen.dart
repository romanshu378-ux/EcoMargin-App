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
              // 1. App Header (Logo, Tagline, Hamburger Menu, Notification Bell)
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

              // 2. Hero Banner (Promotional EV banner with slider & Find Stations CTA)
              SliverToBoxAdapter(
                child: HeroBannerSlider(
                  onFindStationsPressed: () => context.go('/map'),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // 3. Search Section (Current Location & Search input + Filter button)
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

              // 4. Nearby Stations Section
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

              // 5. Quick Actions Section (Scan QR, Favorites, Charging History, Wallet)
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

              // 6. Wallet Card (Wallet Balance & Add Money Button)
              SliverToBoxAdapter(
                child: WalletCardWidget(
                  onAddMoneyPressed: () => context.go('/wallet'),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // 7. Promotional Banner ("Drive Green, Save More")
              const SliverToBoxAdapter(
                child: PromoBannerWidget(),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),

      // 8. Bottom Navigation Bar (Home, Map, Bookings, Profile)
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          elevation: 0,
          backgroundColor: Colors.transparent,
          indicatorColor: const Color(0xFF16A34A).withOpacity(0.12),
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
