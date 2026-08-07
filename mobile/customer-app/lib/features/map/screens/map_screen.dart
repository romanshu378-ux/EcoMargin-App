import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/core_providers.dart';

class MapStation {
  final String id;
  final String name;
  final String address;
  final LatLng position;
  final int totalChargers;
  final int availableChargers;
  final String maxPowerKw;
  final List<String> connectors;
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
  LatLng _userPosition = const LatLng(12.9716, 77.5946); // Default: Bengaluru
  bool _isLoadingLocation = true;
  bool _permissionDenied = false;
  Timer? _refreshTimer;
  MapStation? _selectedStation;

  // Mock Nearby Stations Database
  final List<MapStation> _stations = [
    MapStation(
      id: 'st-01',
      name: 'GreenCharge Hub Sector 62',
      address: 'Plot 42, Electronic City Phase 1, Bengaluru',
      position: const LatLng(12.9725, 77.5960),
      totalChargers: 6,
      availableChargers: 4,
      maxPowerKw: '60 kW DC Fast',
      connectors: ['CCS2 (DC)', 'Type 2 (AC)'],
      isAvailable: true,
    ),
    MapStation(
      id: 'st-02',
      name: 'EcoFast Ultra Hub Whitefield',
      address: 'ITPL Main Road, Whitefield, Bengaluru',
      position: const LatLng(12.9790, 77.6010),
      totalChargers: 8,
      availableChargers: 2,
      maxPowerKw: '120 kW DC Ultra Fast',
      connectors: ['CCS2 (DC)', 'GB/T (DC)', 'Type 2 (AC)'],
      isAvailable: true,
    ),
    MapStation(
      id: 'st-03',
      name: 'PowerGrid Hub Indiranagar',
      address: '100 Feet Road, Indiranagar, Bengaluru',
      position: const LatLng(12.9650, 77.5890),
      totalChargers: 4,
      availableChargers: 0,
      maxPowerKw: '22 kW AC Standard',
      connectors: ['Type 2 (AC)'],
      isAvailable: false,
    ),
    MapStation(
      id: 'st-04',
      name: 'ChargeZone Express Koramangala',
      address: '80 Feet Road, 4th Block Koramangala, Bengaluru',
      position: const LatLng(12.9610, 77.6050),
      totalChargers: 10,
      availableChargers: 7,
      maxPowerKw: '240 kW Hyper Charger',
      connectors: ['CCS2 (DC)', 'Type 2 (AC)'],
      isAvailable: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _determinePosition();
    // Refresh charger availability every 20 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 20), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _determinePosition() async {
    setState(() => _isLoadingLocation = true);

    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _isLoadingLocation = false;
        _permissionDenied = true;
      });
      return;
    }

    permission = await Geolocator.checkPermission();
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

      setState(() {
        _userPosition = newPos;
        _isLoadingLocation = false;
        _permissionDenied = false;
      });

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(newPos, 14.5),
      );
    } catch (e) {
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
    final distanceKm = _calculateDistanceKm(station.position);

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(station.position, 15.0),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildStationBottomSheet(station, distanceKm),
    );
  }

  Widget _buildStationBottomSheet(MapStation station, double distanceKm) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 15),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  station.name,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: station.isAvailable
                      ? const Color(0xFF16A34A).withOpacity(0.15)
                      : Colors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  station.isAvailable ? 'AVAILABLE' : 'BUSY',
                  style: TextStyle(
                    color: station.isAvailable ? const Color(0xFF16A34A) : Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            station.address,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.near_me, size: 16, color: Color(0xFF16A34A)),
              const SizedBox(width: 4),
              Text(
                '${distanceKm.toStringAsFixed(1)} km away',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.ev_station, size: 16, color: Color(0xFF16A34A)),
              const SizedBox(width: 4),
              Text(
                '${station.availableChargers}/${station.totalChargers} Available',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Max Speed: ${station.maxPowerKw}',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: station.connectors.map((c) => Chip(label: Text(c, style: const TextStyle(fontSize: 11)))).toList(),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Opening navigation to ${station.name}...')),
                    );
                  },
                  icon: const Icon(Icons.directions, color: Color(0xFF16A34A)),
                  label: const Text('Navigate', style: TextStyle(color: Color(0xFF16A34A))),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF16A34A)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.go('/station-details');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('View Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Set<Marker> _createMarkers() {
    final markers = <Marker>{};

    // User Location Marker (Blue)
    markers.add(
      Marker(
        markerId: const MarkerId('user_location'),
        position: _userPosition,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'Your Current Location'),
      ),
    );

    // Station Markers (Green)
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

  static const String _darkMapStyle = '''
[
  {"elementType": "geometry", "stylers": [{"color": "#242f3e"}]},
  {"elementType": "labels.text.fill", "stylers": [{"color": "#746855"}]},
  {"elementType": "labels.text.stroke", "stylers": [{"color": "#242f3e"}]},
  {"featureType": "administrative.locality", "elementType": "labels.text.fill", "stylers": [{"color": "#d59563"}]},
  {"featureType": "poi", "elementType": "labels.text.fill", "stylers": [{"color": "#d59563"}]},
  {"featureType": "poi.park", "elementType": "geometry", "stylers": [{"color": "#263c3f"}]},
  {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#38414e"}]},
  {"featureType": "road", "elementType": "geometry.stroke", "stylers": [{"color": "#212a37"}]},
  {"featureType": "road.highway", "elementType": "geometry", "stylers": [{"color": "#746855"}]},
  {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#17263c"}]}
]
''';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('EV Station Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.go('/search'),
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) {
              _mapController = controller;
              if (isDark) {
                _mapController?.setMapStyle(_darkMapStyle);
              }
            },
            initialCameraPosition: CameraPosition(
              target: _userPosition,
              zoom: 14.0,
            ),
            markers: _createMarkers(),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),

          // Top Search & Status Overlay Bar
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.flash_on, color: Color(0xFF16A34A)),
                  const SizedBox(width: 8),
                  Text(
                    '${_stations.where((s) => s.isAvailable).length} Fast Stations Available',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.tune, size: 20),
                    onPressed: () => context.go('/search'),
                  ),
                ],
              ),
            ),
          ),

          // Loading Shimmer Indicator
          if (_isLoadingLocation)
            Positioned(
              top: 80,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    ),
                    SizedBox(width: 12),
                    Text('Detecting GPS location...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ),
            ),

          // Permission Denied Warning Banner
          if (_permissionDenied)
            Positioned(
              bottom: 80,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade900,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_off, color: Colors.white),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text('GPS permission disabled. Showing default area.', style: TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                    TextButton(
                      onPressed: _determinePosition,
                      child: const Text('RETRY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _determinePosition,
        backgroundColor: const Color(0xFF16A34A),
        child: const Icon(Icons.my_location, color: Colors.white),
      ),
    );
  }
}
