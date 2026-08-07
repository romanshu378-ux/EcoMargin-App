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
          id: '1',
          name: 'EcoMargin Charging Station',
          address: 'Tonk Road, Jaipur, Rajasthan',
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
        ),
        const ChargingStation(
          id: '2',
          name: 'EcoMargin Hub Express',
          address: 'Malviya Nagar, Jaipur, Rajasthan',
          distanceStr: '2.4 km Away',
          totalChargers: 8,
          availableChargers: 5,
          chargerType: 'DC 120kW',
          chargerCategory: 'Super Charger',
          priceStr: '₹15 / kWh',
          priceSubtext: 'Starting from',
          imageUrl: 'https://images.unsplash.com/photo-1558441719-6705166e2860?w=500&q=80',
          isVerified: true,
          isFavorite: true,
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

final walletBalanceProvider = StateProvider<double>((ref) => 256.50);
final unreadNotificationCountProvider = StateProvider<int>((ref) => 1);
final currentLocationProvider = StateProvider<String>((ref) => 'Current Location');
