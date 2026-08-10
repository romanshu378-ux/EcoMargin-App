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
            return ChargingStation(
              id: json['id']?.toString() ?? '',
              name: json['name'] ?? 'EcoMargin Charging Station',
              address: json['address'] ?? 'Tonk Road, Jaipur, Rajasthan',
              distanceStr: json['distanceStr'] ?? '0.8 km Away',
              totalChargers: json['totalChargers'] ?? 6,
              availableChargers: json['availableChargers'] ?? 4,
              chargerType: json['chargerType'] ?? 'DC 60kW',
              chargerCategory: json['chargerCategory'] ?? 'Fast Charger',
              priceStr: json['priceStr'] ?? '₹12 / kWh',
              priceSubtext: json['priceSubtext'] ?? 'Starting from',
              imageUrl: json['imageUrl'] ?? 'https://images.unsplash.com/photo-1563720223185-11003d516935?w=500&q=80',
              isVerified: json['isVerified'] ?? true,
              latitude: (json['latitude'] as num?)?.toDouble() ?? 26.9150,
              longitude: (json['longitude'] as num?)?.toDouble() ?? 75.7920,
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
          totalChargers: 6,
          availableChargers: 4,
          chargerType: 'DC 60kW',
          chargerCategory: 'Fast Charger',
          priceStr: '₹12 / kWh',
          priceSubtext: 'Starting from',
          imageUrl: 'https://images.unsplash.com/photo-1563720223185-11003d516935?w=500&q=80',
          isVerified: true,
          isFavorite: false,
          latitude: 26.9150,
          longitude: 75.7920,
        ),
        const ChargingStation(
          id: 'st-02',
          name: 'EcoMargin Supercharge Hub',
          address: 'Apex Circle, Malviya Nagar, Jaipur 302017',
          distanceStr: '2.4 km Away',
          totalChargers: 8,
          availableChargers: 5,
          chargerType: 'DC 120kW',
          chargerCategory: 'Super Charger',
          priceStr: '₹15 / kWh',
          priceSubtext: 'Starting from',
          imageUrl: 'https://images.unsplash.com/photo-1563720223185-11003d516935?w=500&q=80',
          isVerified: true,
          isFavorite: true,
          latitude: 26.8540,
          longitude: 75.8140,
        ),
        const ChargingStation(
          id: 'st-03',
          name: 'PowerGrid Hub C-Scheme',
          address: 'MI Road, C-Scheme, Jaipur 302001',
          distanceStr: '3.1 km Away',
          totalChargers: 4,
          availableChargers: 2,
          chargerType: 'AC 22kW',
          chargerCategory: 'Standard Charger',
          priceStr: '₹10 / kWh',
          priceSubtext: 'Starting from',
          imageUrl: 'https://images.unsplash.com/photo-1563720223185-11003d516935?w=500&q=80',
          isVerified: true,
          isFavorite: false,
          latitude: 26.9180,
          longitude: 75.8010,
        ),
        const ChargingStation(
          id: 'st-04',
          name: 'ChargeZone Express Vaishali',
          address: 'Queens Road, Vaishali Nagar, Jaipur 302021',
          distanceStr: '4.5 km Away',
          totalChargers: 10,
          availableChargers: 7,
          chargerType: 'DC 240kW',
          chargerCategory: 'Super Charger',
          priceStr: '₹18 / kWh',
          priceSubtext: 'Starting from',
          imageUrl: 'https://images.unsplash.com/photo-1563720223185-11003d516935?w=500&q=80',
          isVerified: true,
          isFavorite: false,
          latitude: 26.9080,
          longitude: 75.7480,
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
