import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
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
final authStateProvider = StateProvider<bool>((ref) => false);

// Wallet Balance Provider
final walletBalanceProvider = StateProvider<double>((ref) => 0.0);

// Theme Mode Provider (Light, Dark, System)
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);

// Selected Language Provider
final languageProvider = StateProvider<String>((ref) => 'English');

// Live Charging Session Model & Notifier
class ChargingSessionState {
  final bool isCharging;
  final String? sessionId;
  final String status;
  final String stationName;
  final String chargerId;
  final String connectorType;
  final double percentage; // 0-100
  final double kwhDelivered;
  final double currentPowerKw;
  final int durationSeconds;
  final double totalCost;
  final bool hasConnectionError;

  ChargingSessionState({
    required this.isCharging,
    this.sessionId,
    required this.status,
    required this.stationName,
    required this.chargerId,
    required this.connectorType,
    required this.percentage,
    required this.kwhDelivered,
    required this.currentPowerKw,
    required this.durationSeconds,
    required this.totalCost,
    this.hasConnectionError = false,
  });

  ChargingSessionState copyWith({
    bool? isCharging,
    String? sessionId,
    String? status,
    String? stationName,
    String? chargerId,
    String? connectorType,
    double? percentage,
    double? kwhDelivered,
    double? currentPowerKw,
    int? durationSeconds,
    double? totalCost,
    bool? hasConnectionError,
  }) {
    return ChargingSessionState(
      isCharging: isCharging ?? this.isCharging,
      sessionId: sessionId ?? this.sessionId,
      status: status ?? this.status,
      stationName: stationName ?? this.stationName,
      chargerId: chargerId ?? this.chargerId,
      connectorType: connectorType ?? this.connectorType,
      percentage: percentage ?? this.percentage,
      kwhDelivered: kwhDelivered ?? this.kwhDelivered,
      currentPowerKw: currentPowerKw ?? this.currentPowerKw,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      totalCost: totalCost ?? this.totalCost,
      hasConnectionError: hasConnectionError ?? this.hasConnectionError,
    );
  }
}

class ChargingSessionNotifier extends StateNotifier<ChargingSessionState> {
  final Ref ref;
  Timer? _timer;
  bool _isStarting = false;
  DateTime? _lastSyncTime;

  ChargingSessionNotifier(this.ref)
      : super(ChargingSessionState(
          isCharging: false,
          status: 'COMPLETED',
          stationName: 'EcoMargin Charging Hub',
          chargerId: '',
          connectorType: '',
          percentage: 0.0,
          kwhDelivered: 0.0,
          currentPowerKw: 0.0,
          durationSeconds: 0,
          totalCost: 0.0,
        )) {
    syncWithBackend();
  }

  Future<void> syncWithBackend() async {
    final now = DateTime.now();
    if (_lastSyncTime != null && now.difference(_lastSyncTime!) < const Duration(seconds: 3)) {
      return;
    }
    _lastSyncTime = now;
    try {
      await fetchWalletBalance();
    } catch (_) {}
    try {
      await checkActiveSession();
    } catch (_) {}
  }

  Future<void> fetchWalletBalance() async {
    final apiClient = ref.read(apiClientProvider);
    final response = await apiClient.dio.get('/wallet/balance');
    if (response.statusCode == 200 && response.data != null) {
      final bal = double.tryParse(response.data['balance']?.toString() ?? '0') ?? 0.0;
      ref.read(walletBalanceProvider.notifier).state = bal;
    } else {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
      );
    }
  }

  Future<void> checkActiveSession() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.dio.get('/charging-sessions/active');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        final status = data['status'] ?? 'CHARGING';
        final isActive = status == 'ACTIVE' || status == 'STARTING' || status == 'PREPARING' || status == 'CHARGING' || status == 'FINISHING';
        
        if (!isActive) {
          _timer?.cancel();
        }

        state = ChargingSessionState(
          isCharging: isActive,
          sessionId: data['sessionId']?.toString(),
          status: status,
          stationName: data['stationName'] ?? 'EcoMargin Charging Hub',
          chargerId: data['chargerId'] ?? '',
          connectorType: data['connectorType'] ?? '',
          percentage: double.tryParse(data['percentage']?.toString() ?? '0') ?? 0.0,
          kwhDelivered: double.tryParse(data['kwhDelivered']?.toString() ?? '0') ?? 0.0,
          currentPowerKw: double.tryParse(data['currentPowerKw']?.toString() ?? '0') ?? 0.0,
          durationSeconds: int.tryParse(data['durationSeconds']?.toString() ?? '0') ?? 0,
          totalCost: double.tryParse(data['totalCost']?.toString() ?? '0') ?? 0.0,
          hasConnectionError: false,
        );
        if (state.isCharging) {
          _startPolling();
        }
      } else {
        _timer?.cancel();
        state = state.copyWith(isCharging: false, hasConnectionError: false);
      }
    } catch (_) {
      if (state.isCharging) {
        state = state.copyWith(hasConnectionError: true);
      } else {
        _timer?.cancel();
        state = state.copyWith(isCharging: false, hasConnectionError: false);
      }
    }
  }

  void _startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      await checkActiveSession();
    });
  }

  Future<void> startCharging({String? stationName, String? chargerId, String? connectorType}) async {
    if (_isStarting) return; // Prevent duplicate concurrent starts
    _isStarting = true;
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.dio.post(
        '/charging-sessions/start',
        data: {
          if (stationName != null) 'stationName': stationName,
          if (chargerId != null) 'chargerId': chargerId,
          if (connectorType != null) 'connectorType': connectorType,
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        final status = data['status'] ?? 'CHARGING';
        state = ChargingSessionState(
          isCharging: true,
          sessionId: data['sessionId']?.toString(),
          status: status,
          stationName: data['stationName'] ?? stationName ?? 'EcoMargin Charging Hub',
          chargerId: data['chargerId'] ?? chargerId ?? '',
          connectorType: data['connectorType'] ?? connectorType ?? '',
          percentage: double.tryParse(data['percentage']?.toString() ?? '0') ?? 0.0,
          kwhDelivered: double.tryParse(data['kwhDelivered']?.toString() ?? '0') ?? 0.0,
          currentPowerKw: double.tryParse(data['currentPowerKw']?.toString() ?? '0') ?? 0.0,
          durationSeconds: int.tryParse(data['durationSeconds']?.toString() ?? '0') ?? 0,
          totalCost: double.tryParse(data['totalCost']?.toString() ?? '0') ?? 0.0,
          hasConnectionError: false,
        );
        await fetchWalletBalance();
        _startPolling();
      } else {
        // Non-200 response: mark connection error so caller can check
        state = state.copyWith(hasConnectionError: true);
      }
    } catch (e) {
      // Do NOT rethrow bare DioException – surface as hasConnectionError
      state = state.copyWith(isCharging: false, hasConnectionError: true);
      // Re-throw so StartChargingScreen can display a message
      rethrow;
    } finally {
      _isStarting = false;
    }
  }

  Future<void> stopCharging() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final activeSessionId = state.sessionId;
      final url = activeSessionId != null ? '/charging-sessions/$activeSessionId/stop' : '/charging-sessions/stop';
      final response = await apiClient.dio.post(url);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        _timer?.cancel();
        state = ChargingSessionState(
          isCharging: false,
          sessionId: data['sessionId']?.toString() ?? activeSessionId,
          status: 'COMPLETED',
          stationName: data['stationName'] ?? state.stationName,
          chargerId: data['chargerId'] ?? state.chargerId,
          connectorType: data['connectorType'] ?? state.connectorType,
          percentage: double.tryParse(data['percentage']?.toString() ?? '100.0') ?? 100.0,
          kwhDelivered: double.tryParse(data['kwhDelivered']?.toString() ?? '0') ?? 0.0,
          currentPowerKw: 0.0,
          durationSeconds: int.tryParse(data['durationSeconds']?.toString() ?? '0') ?? 0,
          totalCost: double.tryParse(data['totalCost']?.toString() ?? '0') ?? 0.0,
          hasConnectionError: false,
        );
        
        // Dynamic balance sync
        final walletBal = double.tryParse(data['walletBalance']?.toString() ?? '0') ?? 0.0;
        ref.read(walletBalanceProvider.notifier).state = walletBal;

        ref.invalidate(walletTransactionsProvider);
        ref.invalidate(chargingHistoryProvider);
      }
    } catch (_) {
      _timer?.cancel();
      state = state.copyWith(isCharging: false, hasConnectionError: false);
      ref.invalidate(walletTransactionsProvider);
      ref.invalidate(chargingHistoryProvider);
    }
  }

  void clearCompletedSession() {
    if (state.status == 'COMPLETED') {
      state = ChargingSessionState(
        isCharging: false,
        status: 'IDLE',
        stationName: 'EcoMargin Charging Hub',
        chargerId: '',
        connectorType: '',
        percentage: 0.0,
        kwhDelivered: 0.0,
        currentPowerKw: 0.0,
        durationSeconds: 0,
        totalCost: 0.0,
        hasConnectionError: false,
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final chargingSessionProvider =
    StateNotifierProvider<ChargingSessionNotifier, ChargingSessionState>((ref) {
  return ChargingSessionNotifier(ref);
});

final walletTransactionsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  try {
    final apiClient = ref.watch(apiClientProvider);
    final response = await apiClient.dio.get('/wallet/transactions');
    if (response.statusCode == 200 && response.data is List) {
      return List<Map<String, dynamic>>.from(response.data);
    }
  } catch (_) {}
  return [];
});

final chargingHistoryProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  try {
    final apiClient = ref.watch(apiClientProvider);
    final response = await apiClient.dio.get('/charging-sessions/history');
    if (response.statusCode == 200 && response.data is List) {
      return List<Map<String, dynamic>>.from(response.data);
    }
  } catch (_) {}
  return [];
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
