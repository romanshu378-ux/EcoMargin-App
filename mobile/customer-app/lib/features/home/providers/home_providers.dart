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

      final Map<String, dynamic> queryParams = {};
      if (userLat != null && userLng != null) {
        queryParams['latitude'] = userLat;
        queryParams['longitude'] = userLng;
        queryParams['radiusKm'] = radiusKm ?? 50.0;
      }

      final response = await apiClient.dio.get('/stations/nearby', queryParameters: queryParams);

      if (response.statusCode == 200 && response.data is List) {
        final List<ChargingStation> stations = (response.data as List).map((json) {
          final chargersList = json['chargers'] as List?;
          final List<StationConnector> connectors = [];
          int total = 0;
          int available = 0;

          if (chargersList != null) {
            for (final chg in chargersList) {
              final String chargerId = chg['ocppId'] ?? chg['id']?.toString() ?? '';
              final connList = chg['connectors'] as List?;
              if (connList != null) {
                for (final conn in connList) {
                  total++;
                  final String status = (conn['status'] ?? 'AVAILABLE').toString();
                  if (status.toUpperCase() == 'AVAILABLE') {
                    available++;
                  }
                  final double rate = (conn['unitRate'] as num?)?.toDouble() ?? 0.0;
                  connectors.add(StationConnector(
                    id: conn['id']?.toString() ?? '',
                    type: (conn['type'] ?? 'CCS2').toString(),
                    status: status,
                    maxPowerKw: (conn['maxPowerKw'] as num?)?.toDouble() ?? 60.0,
                    unitRate: rate,
                    chargerId: chargerId,
                  ));
                }
              }
            }
          }

          final double stationLat = (json['latitude'] as num?)?.toDouble() ?? 0.0;
          final double stationLng = (json['longitude'] as num?)?.toDouble() ?? 0.0;

          double distKm = 0.0;
          String distStr = '';

          if (userLat != null && userLng != null && stationLat != 0.0 && stationLng != 0.0) {
            distKm = Geolocator.distanceBetween(userLat, userLng, stationLat, stationLng) / 1000.0;
            distStr = '${distKm.toStringAsFixed(1)} km Away';
          } else if (json['distanceKm'] != null) {
            distKm = (json['distanceKm'] as num).toDouble();
            distStr = json['distanceStr'] ?? '${distKm.toStringAsFixed(1)} km Away';
          } else {
            distStr = json['distanceStr'] ?? '';
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

          return ChargingStation(
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
          );
        }).toList();

        // Strictly sort by distance ascending (nearest station at index 0)
        stations.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

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
