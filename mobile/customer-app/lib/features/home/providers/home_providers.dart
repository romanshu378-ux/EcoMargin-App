import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/station.dart';
import '../../../core/providers/core_providers.dart';

class StationNotifier extends StateNotifier<AsyncValue<List<ChargingStation>>> {
  final Ref ref;

  StationNotifier(this.ref) : super(const AsyncValue.loading()) {
    fetchStations();
  }

  Future<void> fetchStations() async {
    try {
      state = const AsyncValue.loading();
      final apiClient = ref.read(apiClientProvider);
      
      try {
        final response = await apiClient.dio.get('/stations/nearby');
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
                    final String status = conn['status'] ?? 'AVAILABLE';
                    if (status.toUpperCase() == 'AVAILABLE') {
                      available++;
                    }
                    connectors.add(StationConnector(
                      id: conn['id']?.toString() ?? '',
                      type: conn['type'] ?? 'CCS2',
                      status: status,
                      maxPowerKw: (conn['maxPowerKw'] as num?)?.toDouble() ?? 50.0,
                      chargerId: chargerId,
                    ));
                  }
                }
              }
            }
            
            // fallback if empty
            if (connectors.isEmpty) {
              connectors.addAll([
                const StationConnector(id: '1', type: 'CCS2', status: 'AVAILABLE', maxPowerKw: 60.0, chargerId: 'CHG-DC-04'),
                const StationConnector(id: '2', type: 'Type 2', status: 'AVAILABLE', maxPowerKw: 22.0, chargerId: 'CHG-AC-02'),
              ]);
              total = 2;
              available = 2;
            }

            final chargerType = json['chargerType'] ?? (connectors.isNotEmpty ? connectors.first.type : 'CCS2');

            return ChargingStation(
              id: json['id']?.toString() ?? '',
              name: json['name'] ?? 'EcoMargin Charging Station',
              address: json['address'] ?? 'Tonk Road, Jaipur, Rajasthan',
              distanceStr: json['distanceStr'] ?? '0.8 km Away',
              totalChargers: total,
              availableChargers: available,
              chargerType: chargerType,
              chargerCategory: json['chargerCategory'] ?? (chargerType.contains('CCS2') ? 'Fast Charger' : 'Standard Charger'),
              priceStr: json['priceStr'] ?? '₹12 / kWh',
              priceSubtext: json['priceSubtext'] ?? 'Starting from',
              imageUrl: json['imageUrl'] ?? 'https://images.unsplash.com/photo-1563720223185-11003d516935?w=500&q=80',
              isVerified: json['isVerified'] ?? true,
              latitude: (json['latitude'] as num?)?.toDouble() ?? 26.9150,
              longitude: (json['longitude'] as num?)?.toDouble() ?? 75.7920,
              connectors: connectors,
            );
          }).toList();
          state = AsyncValue.data(stations);
          return;
        }
      } catch (_) {
        // Fallback to sample data for offline demo
      }

      final mockStations = [
        const ChargingStation(
          id: 'st-01',
          name: 'EcoMargin Fast Charging Hub',
          address: 'Tonk Road, Sector 62, Jaipur, Rajasthan 302018',
          distanceStr: '0.8 km Away',
          totalChargers: 2,
          availableChargers: 2,
          chargerType: 'CCS2, Type 2',
          chargerCategory: 'Fast Charger',
          priceStr: '₹12 / kWh',
          priceSubtext: 'Starting from',
          imageUrl: 'https://images.unsplash.com/photo-1563720223185-11003d516935?w=500&q=80',
          isVerified: true,
          isFavorite: false,
          latitude: 26.9150,
          longitude: 75.7920,
          connectors: [
            StationConnector(id: '1', type: 'CCS2', status: 'AVAILABLE', maxPowerKw: 60.0, chargerId: 'TX_AUS_DWTN_01'),
            StationConnector(id: '2', type: 'Type 2', status: 'AVAILABLE', maxPowerKw: 22.0, chargerId: 'TX_AUS_DWTN_01'),
          ],
        ),
        const ChargingStation(
          id: 'st-02',
          name: 'EcoMargin Supercharge Hub',
          address: 'Apex Circle, Malviya Nagar, Jaipur 302017',
          distanceStr: '2.4 km Away',
          totalChargers: 2,
          availableChargers: 2,
          chargerType: 'CCS2, GB/T',
          chargerCategory: 'Super Charger',
          priceStr: '₹15 / kWh',
          priceSubtext: 'Starting from',
          imageUrl: 'https://images.unsplash.com/photo-1563720223185-11003d516935?w=500&q=80',
          isVerified: true,
          isFavorite: true,
          latitude: 26.8540,
          longitude: 75.8140,
          connectors: [
            StationConnector(id: '3', type: 'CCS2', status: 'AVAILABLE', maxPowerKw: 120.0, chargerId: 'TX_AUS_DWTN_02'),
            StationConnector(id: '4', type: 'GB/T', status: 'AVAILABLE', maxPowerKw: 60.0, chargerId: 'TX_AUS_DWTN_02'),
          ],
        ),
        const ChargingStation(
          id: 'st-03',
          name: 'PowerGrid Hub C-Scheme',
          address: 'MI Road, C-Scheme, Jaipur 302001',
          distanceStr: '3.1 km Away',
          totalChargers: 1,
          availableChargers: 1,
          chargerType: 'Type 2',
          chargerCategory: 'Standard Charger',
          priceStr: '₹10 / kWh',
          priceSubtext: 'Starting from',
          imageUrl: 'https://images.unsplash.com/photo-1563720223185-11003d516935?w=500&q=80',
          isVerified: true,
          isFavorite: false,
          latitude: 26.9180,
          longitude: 75.8010,
          connectors: [
            StationConnector(id: '5', type: 'Type 2', status: 'AVAILABLE', maxPowerKw: 22.0, chargerId: 'TX_AUS_NL_01'),
          ],
        ),
        const ChargingStation(
          id: 'st-04',
          name: 'ChargeZone Express Vaishali',
          address: 'Queens Road, Vaishali Nagar, Jaipur 302021',
          distanceStr: '4.5 km Away',
          totalChargers: 1,
          availableChargers: 1,
          chargerType: 'CCS2',
          chargerCategory: 'Super Charger',
          priceStr: '₹18 / kWh',
          priceSubtext: 'Starting from',
          imageUrl: 'https://images.unsplash.com/photo-1563720223185-11003d516935?w=500&q=80',
          isVerified: true,
          isFavorite: false,
          latitude: 26.9080,
          longitude: 75.7480,
          connectors: [
            StationConnector(id: '6', type: 'CCS2', status: 'AVAILABLE', maxPowerKw: 240.0, chargerId: 'TX_AUS_NL_02'),
          ],
        ),
      ];

      state = AsyncValue.data(mockStations);
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

final unreadNotificationCountProvider = StateProvider<int>((ref) => 1);
final currentLocationProvider = StateProvider<String>((ref) => 'Current Location');
