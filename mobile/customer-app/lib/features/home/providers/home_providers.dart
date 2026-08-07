import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/station.dart';
import '../../../core/providers/core_providers.dart';

// StateNotifier for Charging Stations list
class StationNotifier extends StateNotifier<AsyncValue<List<ChargingStation>>> {
  final Ref ref;

  StationNotifier(this.ref) : super(const AsyncValue.loading()) {
    fetchStations();
  }

  Future<void> fetchStations() async {
    try {
      state = const AsyncValue.loading();
      final apiClient = ref.read(apiClientProvider);
      
      // Attempt backend API call
      try {
        final response = await apiClient.dio.get('/stations/nearby');
        if (response.statusCode == 200 && response.data is List) {
          final List<ChargingStation> stations = (response.data as List).map((json) {
            return ChargingStation(
              id: json['id']?.toString() ?? '',
              name: json['name'] ?? 'Charging Hub',
              address: json['address'] ?? 'City Center',
              distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 1.5,
              totalChargers: json['totalChargers'] ?? 6,
              availableChargers: json['availableChargers'] ?? 4,
              chargerType: json['chargerType'] ?? 'DC Fast (150kW)',
              pricePerKwh: (json['pricePerKwh'] as num?)?.toDouble() ?? 0.28,
              imageUrl: json['imageUrl'] ?? 'https://images.unsplash.com/photo-1563720223185-11003d516935?w=500&q=80',
              isVerified: json['isVerified'] ?? true,
            );
          }).toList();
          state = AsyncValue.data(stations);
          return;
        }
      } catch (_) {
        // Fallback to sample data for seamless offline/standalone demo experience
      }

      // Premium fallback mock data
      final mockStations = [
        const ChargingStation(
          id: '1',
          name: 'EcoMargin Central Hub',
          address: '742 Evergreen Terrace, Downtown',
          distanceKm: 0.8,
          totalChargers: 8,
          availableChargers: 6,
          chargerType: 'Ultra Fast DC (250 kW)',
          pricePerKwh: 0.24,
          imageUrl: 'https://images.unsplash.com/photo-1563720223185-11003d516935?w=500&q=80',
          isVerified: true,
          rating: 4.9,
        ),
        const ChargingStation(
          id: '2',
          name: 'GreenDrive Express Station',
          address: '101 Tech Boulevard, Silicon District',
          distanceKm: 2.1,
          totalChargers: 6,
          availableChargers: 3,
          chargerType: 'Super Fast DC (150 kW)',
          pricePerKwh: 0.28,
          imageUrl: 'https://images.unsplash.com/photo-1558441719-6705166e2860?w=500&q=80',
          isVerified: true,
          rating: 4.7,
        ),
        const ChargingStation(
          id: '3',
          name: 'Metro EcoPark Charging',
          address: '55 Park Avenue, City Square',
          distanceKm: 4.5,
          totalChargers: 12,
          availableChargers: 9,
          chargerType: 'Dual AC/DC (60 kW)',
          pricePerKwh: 0.19,
          imageUrl: 'https://images.unsplash.com/photo-1617788138017-80ad40651399?w=500&q=80',
          isVerified: true,
          rating: 4.8,
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

// Wallet Balance Provider
final walletBalanceProvider = StateProvider<double>((ref) => 85.50);

// Notification Unread Count Provider
final unreadNotificationCountProvider = StateProvider<int>((ref) => 3);

// Current User Location Provider
final currentLocationProvider = StateProvider<String>((ref) => 'San Francisco, CA');
