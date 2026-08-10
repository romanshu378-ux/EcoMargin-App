import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

class MapStation {
  final String id;
  final String name;
  final String address;
  final LatLng position;
  final int totalChargers;
  final int availableChargers;
  final String maxPowerKw;
  final List<String> connectors;
  final double pricePerKwh;
  final double rating;
  final String imageUrl;
  final bool isOpen247;
  final bool isAvailable;

  MapStation({
    required this.id,
    required this.name,
    required this.address,
    required this.position,
    required this.totalChargers,
    required this.availableChargers,
    required this.maxPowerKw,
    required this.connectors,
    required this.pricePerKwh,
    required this.rating,
    required this.imageUrl,
    required this.isOpen247,
    required this.isAvailable,
  });
}

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  GoogleMapController? _mapController;
  LatLng _userPosition = const LatLng(26.9124, 75.7873); // Default: Jaipur
  // ignore: unused_field
  bool _isLoadingLocation = true;
  // ignore: unused_field
  bool _permissionDenied = false;
  Timer? _refreshTimer;
  MapStation? _selectedStation;
  final TextEditingController _searchController = TextEditingController();

  final List<MapStation> _stations = [
    MapStation(
      id: 'st-01',
      name: 'EcoMargin Fast Charging Hub',
      address: 'Tonk Road, Sector 62, Jaipur, Rajasthan 302018',
      position: const LatLng(26.9150, 75.7920),
      totalChargers: 6,
      availableChargers: 4,
      maxPowerKw: '60 kW DC',
      connectors: ['CCS2', 'Type 2'],
      pricePerKwh: 12.0,
      rating: 4.8,
      imageUrl: 'https://images.unsplash.com/photo-1563720223185-11003d516935?w=500&q=80',
      isOpen247: true,
      isAvailable: true,
    ),
    MapStation(
      id: 'st-02',
      name: 'EcoMargin Supercharge Hub',
      address: 'Apex Circle, Malviya Nagar, Jaipur 302017',
      position: const LatLng(26.8540, 75.8140),
      totalChargers: 8,
      availableChargers: 5,
      maxPowerKw: '120 kW DC',
      connectors: ['CCS2', 'GB/T'],
      pricePerKwh: 15.0,
      rating: 4.9,
      imageUrl: 'https://images.unsplash.com/photo-1563720223185-11003d516935?w=500&q=80',
      isOpen247: true,
      isAvailable: true,
    ),
    MapStation(
      id: 'st-03',
      name: 'PowerGrid Hub C-Scheme',
      address: 'MI Road, C-Scheme, Jaipur 302001',
      position: const LatLng(26.9180, 75.8010),
      totalChargers: 4,
      availableChargers: 2,
      maxPowerKw: '22 kW AC',
      connectors: ['Type 2'],
      pricePerKwh: 10.0,
      rating: 4.6,
      imageUrl: 'https://images.unsplash.com/photo-1563720223185-11003d516935?w=500&q=80',
      isOpen247: false,
      isAvailable: true,
    ),
    MapStation(
      id: 'st-04',
      name: 'ChargeZone Express Vaishali',
      address: 'Queens Road, Vaishali Nagar, Jaipur 302021',
      position: const LatLng(26.9080, 75.7480),
      totalChargers: 10,
      availableChargers: 7,
      maxPowerKw: '240 kW DC',
      connectors: ['CCS2'],
      pricePerKwh: 18.0,
      rating: 4.95,
      imageUrl: 'https://images.unsplash.com/photo-1563720223185-11003d516935?w=500&q=80',
      isOpen247: true,
      isAvailable: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedStation = _stations.first;
    _determinePosition();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _determinePosition() async {
    setState(() => _isLoadingLocation = true);

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _isLoadingLocation = false;
        _permissionDenied = true;
      });
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _isLoadingLocation = false;
          _permissionDenied = true;
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _isLoadingLocation = false;
        _permissionDenied = true;
      });
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final newPos = LatLng(position.latitude, position.longitude);

      if (!mounted) return;

      setState(() {
        _userPosition = newPos;
        _isLoadingLocation = false;
        _permissionDenied = false;
      });

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(newPos, 14.5),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingLocation = false);
    }
  }

  double _calculateDistanceKm(LatLng target) {
    double distanceInMeters = Geolocator.distanceBetween(
      _userPosition.latitude,
      _userPosition.longitude,
      target.latitude,
      target.longitude,
    );
    return distanceInMeters / 1000.0;
  }

  void _onMarkerTapped(MapStation station) {
    setState(() => _selectedStation = station);
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(station.position, 15.5),
    );
  }

  Set<Marker> _createMarkers() {
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

    // Station Green Markers
    for (final station in _stations) {
      markers.add(
        Marker(
          markerId: MarkerId(station.id),
          position: station.position,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            station.isAvailable ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueOrange,
          ),
          onTap: () => _onMarkerTapped(station),
        ),
      );
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Google Map View
          GoogleMap(
            onMapCreated: (controller) => _mapController = controller,
            initialCameraPosition: CameraPosition(
              target: _userPosition,
              zoom: 13.5,
            ),
            markers: _createMarkers(),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),

          // 2. Top Floating Search Bar
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
                  const Icon(Icons.mic, color: Color(0xFF16A34A)),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.tune, color: Color(0xFF64748B)),
                    onPressed: () => context.push('/search'),
                  ),
                ],
              ),
            ),
          ),

          // 3. Right Floating Controls
          Positioned(
            top: 120,
            right: 16,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'refresh_btn',
                  onPressed: () => setState(() {}),
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

          // 4. Bottom Floating Station Card
          if (_selectedStation != null)
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
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
                            _selectedStation!.imageUrl,
                            width: 90,
                            height: 90,
                            fit: BoxFit.cover,
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
                                      _selectedStation!.isOpen247 ? '24x7 Open' : 'Open Now',
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
                                        '${_selectedStation!.rating}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _selectedStation!.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _selectedStation!.address,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${_calculateDistanceKm(_selectedStation!.position).toStringAsFixed(1)} km away',
                                    style: const TextStyle(
                                      color: Color(0xFF16A34A),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    '₹${_selectedStation!.pricePerKwh.toStringAsFixed(1)} / kWh',
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
                            children: _selectedStation!.connectors
                                .map(
                                  (c) => Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      c,
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
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
                            '${_selectedStation!.availableChargers}/${_selectedStation!.totalChargers} Available',
                            style: const TextStyle(
                              color: Color(0xFF16A34A),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Opening Google Directions for ${_selectedStation!.name}...')),
                              );
                            },
                            icon: const Icon(Icons.near_me, size: 16, color: Colors.white),
                            label: const Text('Get Directions', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
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
                            onPressed: () => context.push('/station-details'),
                            icon: const Icon(Icons.flash_on, size: 16, color: Colors.white),
                            label: const Text('Start Charging', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
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
              ),
            ),
        ],
      ),
    );
  }
}
