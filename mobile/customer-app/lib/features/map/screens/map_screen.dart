import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../home/providers/home_providers.dart';
import '../../home/models/station.dart';
import '../../charging/screens/start_charging_screen.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  GoogleMapController? _mapController;
  LatLng _userPosition = const LatLng(26.9124, 75.7873); // Default: Jaipur
  bool _permissionDenied = false;
  StreamSubscription<Position>? _locationSubscription;
  late PageController _pageController;
  ChargingStation? _selectedStation;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _determinePosition();
    _startLocationUpdates();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _pageController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _startLocationUpdates() {
    _locationSubscription?.cancel();
    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: 20, // Battery optimized: fire only on 20 meters move
      ),
    ).listen((Position position) {
      if (mounted) {
        setState(() {
          _userPosition = LatLng(position.latitude, position.longitude);
        });
      }
    }, onError: (error) {
      debugPrint('[GPS] Location stream error: $error');
    });
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _permissionDenied = true;
      });
      _showSnackbar('Location services are disabled. Please enable GPS.');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _permissionDenied = true;
        });
        _showSnackbar('Location permission is required to find nearby chargers.');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _permissionDenied = true;
      });
      _showSnackbar('Location permissions are permanently denied. Map remains active with default location.');
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 8),
      );
      final newPos = LatLng(position.latitude, position.longitude);

      if (!mounted) return;

      setState(() {
        _userPosition = newPos;
        _permissionDenied = false;
      });

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(newPos, 14.5),
      );
    } catch (e) {
      // Graceful fallback
    }
  }

  void _showSnackbar(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 4)),
      );
    }
  }

  Future<void> _moveCameraTo(LatLng target) async {
    if (_mapController != null) {
      final zoom = await _mapController!.getZoomLevel();
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(target, zoom),
      );
    }
  }

  Future<void> _openMapNavigation(double lat, double lng) async {
    final Uri googleMapsUrl = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    final Uri geoUrl = Uri.parse('geo:$lat,$lng?q=$lat,$lng');
    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(geoUrl)) {
        await launchUrl(geoUrl, mode: LaunchMode.externalApplication);
      } else if (mounted) {
        _showSnackbar('Could not open map application.');
      }
    } catch (e) {
      if (mounted) {
        _showSnackbar('Failed to launch navigation: $e');
      }
    }
  }

  void _showStationBottomSheet(BuildContext context, ChargingStation station) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final dist = Geolocator.distanceBetween(
          _userPosition.latitude,
          _userPosition.longitude,
          station.latitude,
          station.longitude,
        ) / 1000.0;
        final distStr = '${dist.toStringAsFixed(1)} km Away';

        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      station.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16A34A).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${station.availableChargers}/${station.totalChargers} Available',
                      style: const TextStyle(
                        color: Color(0xFF16A34A),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF64748B)),
                  const SizedBox(width: 4),
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
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Distance: $distStr', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  Text('Power: ${station.chargerType}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  Text('Price: ${station.priceStr}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _openMapNavigation(station.latitude, station.longitude);
                      },
                      icon: const Icon(Icons.near_me, size: 16, color: Colors.white),
                      label: const Text('Navigate', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StartChargingScreen(
                              station: station,
                              stationId: station.id,
                              connectorId: station.connectors.isNotEmpty ? station.connectors.first.id : null,
                              chargerId: station.connectors.isNotEmpty ? station.connectors.first.chargerId : null,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.flash_on, size: 16, color: Colors.white),
                      label: const Text('View Charger', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
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

  Set<Marker> _createMarkers(List<ChargingStation> stations) {
    final markers = <Marker>{};

    // User Blue Marker
    markers.add(
      Marker(
        markerId: const MarkerId('user_location'),
        position: _userPosition,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'Your Location'),
      ),
    );

    // Station Markers
    for (int i = 0; i < stations.length; i++) {
      final station = stations[i];
      final isSelected = _selectedStation != null && station.id == _selectedStation!.id;
      final isAvailable = station.availableChargers > 0;

      markers.add(
        Marker(
          markerId: MarkerId(station.id),
          position: LatLng(station.latitude, station.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            isSelected
                ? BitmapDescriptor.hueRed // Highlighted marker
                : (isAvailable ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueOrange),
          ),
          onTap: () {
            setState(() {
              _selectedStation = station;
            });
            if (_pageController.hasClients) {
              _pageController.animateToPage(
                i,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
            _moveCameraTo(LatLng(station.latitude, station.longitude));
            _showStationBottomSheet(context, station);
          },
        ),
      );
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stationsAsync = ref.watch(stationsProvider);

    return Scaffold(
      body: stationsAsync.when(
        data: (stations) {
          // 1. Calculate distances dynamically
          final mappedStations = stations.map((s) {
            final dist = Geolocator.distanceBetween(
              _userPosition.latitude,
              _userPosition.longitude,
              s.latitude,
              s.longitude,
            ) / 1000.0;
            return s.copyWith(
              distanceKm: dist,
              distanceStr: '${dist.toStringAsFixed(1)} km Away',
            );
          }).toList();

          // 2. Sort Nearest -> Farthest
          mappedStations.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

          // 3. Live search filter
          final searchQuery = _searchController.text.toLowerCase();
          final filteredStations = mappedStations.where((s) {
            return s.name.toLowerCase().contains(searchQuery) ||
                s.address.toLowerCase().contains(searchQuery);
          }).toList();

          // Initialize selected station if needed
          if (filteredStations.isNotEmpty) {
            if (_selectedStation == null || !filteredStations.any((s) => s.id == _selectedStation!.id)) {
              _selectedStation = filteredStations.first;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_pageController.hasClients) {
                  _pageController.jumpToPage(0);
                }
              });
            }
          } else {
            _selectedStation = null;
          }

          return Stack(
            children: [
              // Google Map View
              GoogleMap(
                onMapCreated: (controller) => _mapController = controller,
                initialCameraPosition: CameraPosition(
                  target: _userPosition,
                  zoom: 13.5,
                ),
                markers: _createMarkers(filteredStations),
                myLocationEnabled: !_permissionDenied,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
              ),

              // Top Floating Search Bar
              Positioned(
                top: 50,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      if (context.canPop())
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Color(0xFF64748B)),
                          onPressed: () => context.pop(),
                        )
                      else
                        const Icon(Icons.search, color: Color(0xFF64748B)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          decoration: const InputDecoration(
                            hintText: 'Search station, city or landmark...',
                            border: InputBorder.none,
                            hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.clear, color: Color(0xFF94A3B8)),
                        onPressed: () {
                          _searchController.clear();
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Permission Denied Overlay Banner
              if (_permissionDenied)
                Positioned(
                  top: 110,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_off_rounded, color: Colors.orange, size: 24),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Location permission is required to find nearby chargers.',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _determinePosition,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF16A34A),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Enable Location', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),

              // Right Floating Controls
              Positioned(
                top: _permissionDenied ? 180 : 120,
                right: 16,
                child: Column(
                  children: [
                    FloatingActionButton.small(
                      heroTag: 'refresh_btn',
                      onPressed: () {
                        ref.read(stationsProvider.notifier).fetchStations();
                        _determinePosition();
                      },
                      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      foregroundColor: const Color(0xFF16A34A),
                      elevation: 4,
                      child: const Icon(Icons.refresh),
                    ),
                    const SizedBox(height: 10),
                    FloatingActionButton.small(
                      heroTag: 'gps_btn',
                      onPressed: _determinePosition,
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      elevation: 4,
                      child: const Icon(Icons.my_location),
                    ),
                  ],
                ),
              ),

              // Bottom Station Card details
              if (_selectedStation != null)
                Positioned(
                  bottom: 24,
                  left: 0,
                  right: 0,
                  height: 245,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: filteredStations.length,
                    onPageChanged: (index) {
                      final station = filteredStations[index];
                      setState(() {
                        _selectedStation = station;
                      });
                      _moveCameraTo(LatLng(station.latitude, station.longitude));
                    },
                    itemBuilder: (context, index) {
                      final station = filteredStations[index];
                      final rating = 4.5 + (station.id.hashCode % 5) * 0.1;

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.18),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.network(
                                    station.imageUrl,
                                    width: 90,
                                    height: 90,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 90,
                                        height: 90,
                                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                        child: const Icon(
                                          Icons.ev_station_rounded,
                                          size: 40,
                                          color: Color(0xFF16A34A),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF16A34A).withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              station.isVerified ? '24x7 Open' : 'Open Now',
                                              style: const TextStyle(
                                                color: Color(0xFF16A34A),
                                                fontWeight: FontWeight.w800,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              const Icon(Icons.star, color: Colors.amber, size: 16),
                                              const SizedBox(width: 2),
                                              Text(
                                                rating.toStringAsFixed(1),
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        station.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        station.address,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            station.distanceStr,
                                            style: const TextStyle(
                                              color: Color(0xFF16A34A),
                                              fontWeight: FontWeight.w800,
                                              fontSize: 12,
                                            ),
                                          ),
                                          Text(
                                            station.priceStr,
                                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: (station.connectors.isNotEmpty
                                            ? station.connectors.map((c) => c.type).toSet().toList()
                                            : ['CCS2', 'Type 2'])
                                        .map(
                                          (c) => Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: isDark ? const Color(0xFF334155) : Colors.grey.shade100,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              c,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: isDark ? Colors.white70 : Colors.black87,
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF16A34A).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${station.availableChargers}/${station.totalChargers} Available',
                                    style: const TextStyle(
                                      color: Color(0xFF16A34A),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _openMapNavigation(station.latitude, station.longitude),
                                    icon: const Icon(Icons.near_me, size: 16, color: Colors.white),
                                    label: const Text('Navigate', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue.shade600,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => StartChargingScreen(
                                            station: station,
                                            stationId: station.id,
                                            connectorId: station.connectors.isNotEmpty ? station.connectors.first.id : null,
                                            chargerId: station.connectors.isNotEmpty ? station.connectors.first.chargerId : null,
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.flash_on, size: 16, color: Colors.white),
                                    label: const Text('View Charger', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF16A34A),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

              // Empty State Handling
              if (filteredStations.isEmpty)
                Positioned(
                  bottom: 24,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.ev_station_rounded,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No chargers found nearby.',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _determinePosition();
                              ref.read(stationsProvider.notifier).fetchStations();
                            },
                            icon: const Icon(Icons.refresh, color: Colors.white, size: 16),
                            label: const Text('Search Again', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF16A34A),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF16A34A)),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Failed to load stations: $err',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    ref.read(stationsProvider.notifier).fetchStations();
                    _determinePosition();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16A34A)),
                  child: const Text('Retry', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
