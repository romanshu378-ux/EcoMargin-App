import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../models/station.dart';
import '../../../core/providers/core_providers.dart';

class StationNotifier extends StateNotifier<AsyncValue<List<ChargingStation>>> {
  final Ref ref;

  StationNotifier(this.ref) : super(const AsyncValue.loading()) {
    fetchStations();
  }

  Future<void> fetchStations({double? latitude, double? longitude, double? radiusKm}) async {
    try {
      state = const AsyncValue.loading();
      final apiClient = ref.read(apiClientProvider);

      double? userLat = latitude;
      double? userLng = longitude;

      if (userLat == null || userLng == null) {
        try {
          bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
          if (serviceEnabled) {
            LocationPermission permission = await Geolocator.checkPermission();
            if (permission == LocationPermission.denied) {
              permission = await Geolocator.requestPermission();
            }
            if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
              Position position = await Geolocator.getCurrentPosition(
                desiredAccuracy: LocationAccuracy.medium,
                timeLimit: const Duration(seconds: 6),
              );
              userLat = position.latitude;
              userLng = position.longitude;
            }
          }
        } catch (_) {
          // Continue if location fetch times out or fails
        }
      }

      // Check last known position if current position acquisition failed/timed out
      if (userLat == null || userLng == null) {
        try {
          Position? lastKnown = await Geolocator.getLastKnownPosition();
          if (lastKnown != null) {
            userLat = lastKnown.latitude;
            userLng = lastKnown.longitude;
          }
        } catch (_) {}
      }

      // Fallback default coordinates if GPS unavailable (e.g. emulator/testing)
      const double defaultLat = 26.9124;
      const double defaultLng = 75.7873;
      final double effectiveLat = userLat ?? defaultLat;
      final double effectiveLng = userLng ?? defaultLng;

      final Map<String, dynamic> queryParams = {
        'latitude': effectiveLat,
        'longitude': effectiveLng,
        'radiusKm': radiusKm ?? 500.0,
      };

      final response = await apiClient.dio.get('/stations/nearby', queryParameters: queryParams);

      if (response.statusCode == 200 && response.data is List) {
        final List<ChargingStation> stations = [];
        final rawList = response.data as List;

        for (final json in rawList) {
          final String stationStatus = (json['status'] ?? 'ACTIVE').toString().toUpperCase();
          if (json['deletedAt'] != null || stationStatus == 'DELETED' || stationStatus == 'INACTIVE') {
            continue;
          }

          final chargersList = json['chargers'] as List?;
          final List<StationConnector> connectors = [];
          int total = 0;
          int available = 0;

          if (chargersList != null) {
            for (final chg in chargersList) {
              final String chgStatus = (chg['status'] ?? 'AVAILABLE').toString().toUpperCase();
              if (chg['deletedAt'] != null || chgStatus == 'DELETED' || chgStatus == 'DISABLED' || chgStatus == 'INACTIVE') {
                continue;
              }

              final String chargerId = chg['ocppId'] ?? chg['id']?.toString() ?? '';
              final bool isChargerAvailable = chgStatus == 'AVAILABLE';
              final connList = chg['connectors'] as List?;

              if (connList != null) {
                for (final conn in connList) {
                  final String connStatus = (conn['status'] ?? 'AVAILABLE').toString().toUpperCase();
                  if (conn['deletedAt'] != null || connStatus == 'DELETED' || connStatus == 'DISABLED' || connStatus == 'INACTIVE') {
                    continue;
                  }

                  total++;
                  final bool isConnAvailable = connStatus == 'AVAILABLE';
                  final String effectiveStatus = (isChargerAvailable && isConnAvailable) ? 'AVAILABLE' : 'UNAVAILABLE';

                  if (effectiveStatus == 'AVAILABLE') {
                    available++;
                  }
                  final double rate = (conn['unitRate'] as num?)?.toDouble() ?? 0.0;
                  connectors.add(StationConnector(
                    id: conn['id']?.toString() ?? '',
                    type: (conn['type'] ?? 'CCS2').toString(),
                    status: effectiveStatus,
                    maxPowerKw: (conn['maxPowerKw'] as num?)?.toDouble() ?? 60.0,
                    unitRate: rate,
                    chargerId: chargerId,
                  ));
                }
              }
            }
          }

          // Skip station only if it has 0 valid non-deleted chargers/connectors
          if (total == 0) continue;

          final double stationLat = (json['latitude'] as num?)?.toDouble() ?? 0.0;
          final double stationLng = (json['longitude'] as num?)?.toDouble() ?? 0.0;

          double distKm = 0.0;
          String distStr = '';

          if (stationLat != 0.0 && stationLng != 0.0) {
            distKm = Geolocator.distanceBetween(effectiveLat, effectiveLng, stationLat, stationLng) / 1000.0;
            distStr = '${distKm.toStringAsFixed(1)} km Away';
          } else if (json['distanceKm'] != null) {
            distKm = (json['distanceKm'] as num).toDouble();
            distStr = json['distanceStr'] ?? '${distKm.toStringAsFixed(1)} km Away';
          }

          final String chargerType = json['chargerType'] ??
              (connectors.isNotEmpty ? connectors.map((c) => c.type).toSet().join(', ') : 'CCS2');

          String computedPriceStr = json['priceStr'] ?? '';
          String computedPriceSubtext = json['priceSubtext'] ?? 'Per kWh';

          if (computedPriceStr.isEmpty || computedPriceStr == 'N/A') {
            if (connectors.isNotEmpty) {
              final List<double> validRates = connectors
                  .map((c) => c.unitRate)
                  .where((r) => r > 0.0)
                  .toList();
              if (validRates.isNotEmpty) {
                final double minRate = validRates.reduce((double a, double b) => a < b ? a : b);
                final double maxRate = validRates.reduce((double a, double b) => a > b ? a : b);
                computedPriceStr = '₹${minRate % 1 == 0 ? minRate.toInt() : minRate.toStringAsFixed(2)} / kWh';
                computedPriceSubtext = minRate < maxRate ? 'Starting from' : 'Per kWh';
              }
            }
          }

          final String rawAddress = json['address'] ?? '';
          final String city = json['city'] ?? '';
          final String stateStr = json['state'] ?? '';
          String fullAddress = rawAddress;
          if (city.isNotEmpty && !fullAddress.contains(city)) {
            fullAddress = fullAddress.isNotEmpty ? '$fullAddress, $city' : city;
          }
          if (stateStr.isNotEmpty && !fullAddress.contains(stateStr)) {
            fullAddress = fullAddress.isNotEmpty ? '$fullAddress, $stateStr' : stateStr;
          }

          stations.add(ChargingStation(
            id: json['id']?.toString() ?? '',
            name: json['name'] ?? 'EcoMargin Station',
            address: fullAddress.isNotEmpty ? fullAddress : 'Location N/A',
            distanceKm: distKm,
            distanceStr: distStr.isNotEmpty ? distStr : 'N/A',
            totalChargers: total,
            availableChargers: available,
            chargerType: chargerType,
            chargerCategory: json['chargerCategory'] ??
                (chargerType.contains('CCS2') || chargerType.contains('CHADEMO') || chargerType.contains('GB')
                    ? 'Fast Charger'
                    : 'Standard Charger'),
            priceStr: computedPriceStr.isNotEmpty ? computedPriceStr : 'N/A',
            priceSubtext: computedPriceSubtext,
            imageUrl: json['imageUrl'] ?? 'https://images.unsplash.com/photo-1563720223185-11003d516935?w=500&q=80',
            isVerified: json['isVerified'] ?? true,
            latitude: stationLat,
            longitude: stationLng,
            connectors: connectors,
          ));
        }

        // Strictly sort by distance ascending (nearest station at index 0)
        stations.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

        // Requirement 14 Debug Logging
        debugPrint('[NEARBY-STATIONS] total API stations: ${stations.length}');
        for (final s in stations) {
          final int chgCount = s.connectors.map((c) => c.chargerId).toSet().length;
          debugPrint(
            '[NEARBY-STATIONS] station ID: ${s.id} | station name: "${s.name}" | distance: ${s.distanceStr} (${s.distanceKm.toStringAsFixed(2)} km) | charger count: $chgCount | connector count: ${s.connectors.length} | available connector count: ${s.availableChargers}',
          );
        }

        state = AsyncValue.data(stations);
        return;
      }
      state = AsyncValue.error('Invalid response format', StackTrace.current);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void toggleFavorite(String stationId) {
    state.whenData((stations) {
      state = AsyncValue.data(
        stations.map((station) {
          if (station.id == stationId) {
            return station.copyWith(isFavorite: !station.isFavorite);
          }
          return station;
        }).toList(),
      );
    });
  }
}

final stationsProvider = StateNotifierProvider<StationNotifier, AsyncValue<List<ChargingStation>>>((ref) {
  return StationNotifier(ref);
});

final currentLocationProvider = StateProvider<String>((ref) => 'Current Location');
