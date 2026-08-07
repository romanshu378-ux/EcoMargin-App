import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/storage_service.dart';
import '../network/api_client.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return ApiClient(storageService);
});

// Auth State Provider
final authStateProvider = StateProvider<bool>((ref) => true); // Default logged in for demo

// Theme Mode Provider (Light, Dark, System)
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);

// Selected Language Provider
final languageProvider = StateProvider<String>((ref) => 'English');

// Live Charging Session Model & Notifier
class ChargingSessionState {
  final bool isCharging;
  final String stationName;
  final String chargerId;
  final double percentage; // 0-100
  final double kwhDelivered;
  final double currentPowerKw;
  final int durationSeconds;
  final double totalCost;

  ChargingSessionState({
    required this.isCharging,
    required this.stationName,
    required this.chargerId,
    required this.percentage,
    required this.kwhDelivered,
    required this.currentPowerKw,
    required this.durationSeconds,
    required this.totalCost,
  });

  ChargingSessionState copyWith({
    bool? isCharging,
    String? stationName,
    String? chargerId,
    double? percentage,
    double? kwhDelivered,
    double? currentPowerKw,
    int? durationSeconds,
    double? totalCost,
  }) {
    return ChargingSessionState(
      isCharging: isCharging ?? this.isCharging,
      stationName: stationName ?? this.stationName,
      chargerId: chargerId ?? this.chargerId,
      percentage: percentage ?? this.percentage,
      kwhDelivered: kwhDelivered ?? this.kwhDelivered,
      currentPowerKw: currentPowerKw ?? this.currentPowerKw,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      totalCost: totalCost ?? this.totalCost,
    );
  }
}

class ChargingSessionNotifier extends StateNotifier<ChargingSessionState> {
  Timer? _timer;

  ChargingSessionNotifier()
      : super(ChargingSessionState(
          isCharging: false,
          stationName: 'GreenCharge Hub Sector 62',
          chargerId: 'CHG-DC-04',
          percentage: 42.0,
          kwhDelivered: 14.5,
          currentPowerKw: 58.4,
          durationSeconds: 1140, // 19 mins
          totalCost: 261.0,
        ));

  void startCharging({String? stationName, String? chargerId}) {
    state = state.copyWith(
      isCharging: true,
      stationName: stationName ?? state.stationName,
      chargerId: chargerId ?? state.chargerId,
    );
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (state.percentage >= 100) {
        stopCharging();
        return;
      }
      state = state.copyWith(
        percentage: (state.percentage + 0.5).clamp(0, 100),
        kwhDelivered: state.kwhDelivered + 0.15,
        durationSeconds: state.durationSeconds + 2,
        totalCost: state.totalCost + 2.7,
      );
    });
  }

  void stopCharging() {
    _timer?.cancel();
    state = state.copyWith(isCharging: false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final chargingSessionProvider =
    StateNotifierProvider<ChargingSessionNotifier, ChargingSessionState>((ref) {
  return ChargingSessionNotifier();
});

// EV Vehicle Model
class EvVehicle {
  final String id;
  final String brand;
  final String model;
  final String registrationNumber;
  final double batteryCapacityKwh;
  final String connectorType;
  final bool isDefault;

  EvVehicle({
    required this.id,
    required this.brand,
    required this.model,
    required this.registrationNumber,
    required this.batteryCapacityKwh,
    required this.connectorType,
    this.isDefault = false,
  });
}

class VehicleNotifier extends StateNotifier<List<EvVehicle>> {
  VehicleNotifier()
      : super([
          EvVehicle(
            id: '1',
            brand: 'Tata Motors',
            model: 'Nexon EV Max',
            registrationNumber: 'MH 12 AB 4589',
            batteryCapacityKwh: 40.5,
            connectorType: 'CCS2 (DC Fast)',
            isDefault: true,
          ),
          EvVehicle(
            id: '2',
            brand: 'MG Motor',
            model: 'ZS EV',
            registrationNumber: 'MH 14 EV 9912',
            batteryCapacityKwh: 50.3,
            connectorType: 'CCS2 (DC Fast)',
            isDefault: false,
          ),
        ]);

  void addVehicle(EvVehicle vehicle) {
    state = [...state, vehicle];
  }

  void removeVehicle(String id) {
    state = state.where((v) => v.id != id).toList();
  }

  void setDefault(String id) {
    state = [
      for (final v in state)
        EvVehicle(
          id: v.id,
          brand: v.brand,
          model: v.model,
          registrationNumber: v.registrationNumber,
          batteryCapacityKwh: v.batteryCapacityKwh,
          connectorType: v.connectorType,
          isDefault: v.id == id,
        )
    ];
  }
}

final vehicleProvider =
    StateNotifierProvider<VehicleNotifier, List<EvVehicle>>((ref) {
  return VehicleNotifier();
});
