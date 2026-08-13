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

  Future<void> startCharging({String? stationName, String? chargerId, String? connectorType, String? connectorId}) async {
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
          if (connectorId != null) 'connectorId': connectorId,
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

// User Profile Model
class UserProfile {
  final int? id;
  final String email;
  final String firstName;
  final String lastName;
  final String fullName;
  final String phoneNumber;
  final String? dateOfBirth; // yyyy-MM-dd
  final String? gender;
  final String? address;
  final String? city;
  final String? state;
  final String? pinCode;
  final String? emergencyContactName;
  final String? emergencyContactNumber;
  final String? profileImageUrl;

  UserProfile({
    this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.phoneNumber,
    this.dateOfBirth,
    this.gender,
    this.address,
    this.city,
    this.state,
    this.pinCode,
    this.emergencyContactName,
    this.emergencyContactNumber,
    this.profileImageUrl,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      email: json['email'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      fullName: json['fullName'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      dateOfBirth: json['dateOfBirth'],
      gender: json['gender'],
      address: json['address'],
      city: json['city'],
      state: json['state'],
      pinCode: json['pinCode'],
      emergencyContactName: json['emergencyContactName'],
      emergencyContactNumber: json['emergencyContactNumber'],
      profileImageUrl: json['profileImageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'address': address,
      'city': city,
      'state': state,
      'pinCode': pinCode,
      'emergencyContactName': emergencyContactName,
      'emergencyContactNumber': emergencyContactNumber,
      'profileImageUrl': profileImageUrl,
    };
  }
}

class ProfileNotifier extends StateNotifier<AsyncValue<UserProfile>> {
  final Ref ref;

  ProfileNotifier(this.ref) : super(const AsyncValue.loading()) {
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.dio.get('/profile');
      if (response.statusCode == 200) {
        state = AsyncValue.data(UserProfile.fromJson(response.data));
      } else {
        state = AsyncValue.error('Failed to load profile', StackTrace.current);
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> updateProfile(UserProfile updatedProfile) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.dio.put('/profile', data: updatedProfile.toJson());
      if (response.statusCode == 200) {
        state = AsyncValue.data(UserProfile.fromJson(response.data));
        await fetchProfile(); // Refresh profile state directly from backend
      } else {
        throw Exception('Failed to update profile');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> uploadPhoto(List<int> bytes, String filename) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: filename),
      });
      final response = await apiClient.dio.post('/profile/photo', data: formData);
      if (response.statusCode == 200) {
        await fetchProfile(); // Reload profile
      } else {
        throw Exception('Failed to upload photo');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> removePhoto() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.dio.delete('/profile/photo');
      if (response.statusCode == 200) {
        await fetchProfile(); // Reload profile
      } else {
        throw Exception('Failed to remove photo');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, AsyncValue<UserProfile>>((ref) {
  return ProfileNotifier(ref);
});

// EV Vehicle Model
class EvVehicle {
  final String id;
  final String brand;
  final String model;
  final String? variant;
  final String? type;
  final String registrationNumber;
  final double batteryCapacityKwh;
  final String connectorType;
  final String? nickname;
  final bool isDefault;

  EvVehicle({
    required this.id,
    required this.brand,
    required this.model,
    this.variant,
    this.type,
    required this.registrationNumber,
    required this.batteryCapacityKwh,
    required this.connectorType,
    this.nickname,
    this.isDefault = false,
  });
}

class VehicleNotifier extends StateNotifier<List<EvVehicle>> {
  final Ref ref;

  VehicleNotifier(this.ref) : super([]) {
    fetchVehicles();
  }

  Future<void> fetchVehicles() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.dio.get('/vehicles');
      if (response.statusCode == 200 && response.data is List) {
        final List list = response.data;
        state = list.map((item) => EvVehicle(
          id: item['id'].toString(),
          brand: item['brand'] ?? '',
          model: item['model'] ?? '',
          variant: item['variant'],
          type: item['type'],
          registrationNumber: item['registrationNumber'] ?? '',
          batteryCapacityKwh: double.tryParse(item['batteryCapacityKwh']?.toString() ?? '0') ?? 0.0,
          connectorType: item['connectorType'] ?? '',
          nickname: item['nickname'],
          isDefault: item['isDefault'] ?? false,
        )).toList();
      }
    } catch (e) {
      debugPrint('Failed to fetch vehicles: $e');
    }
  }

  Future<void> addVehicle(EvVehicle vehicle) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.dio.post('/vehicles', data: {
        'registrationNumber': vehicle.registrationNumber,
        'brand': vehicle.brand,
        'model': vehicle.model,
        'variant': vehicle.variant,
        'type': vehicle.type,
        'batteryCapacityKwh': vehicle.batteryCapacityKwh,
        'connectorType': vehicle.connectorType,
        'nickname': vehicle.nickname,
        'isDefault': vehicle.isDefault,
      });
      if (response.statusCode == 201 || response.statusCode == 200) {
        await fetchVehicles();
      } else {
        throw Exception('Failed to add vehicle');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> updateVehicle(EvVehicle vehicle) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.dio.put('/vehicles/${vehicle.id}', data: {
        'registrationNumber': vehicle.registrationNumber,
        'brand': vehicle.brand,
        'model': vehicle.model,
        'variant': vehicle.variant,
        'type': vehicle.type,
        'batteryCapacityKwh': vehicle.batteryCapacityKwh,
        'connectorType': vehicle.connectorType,
        'nickname': vehicle.nickname,
        'isDefault': vehicle.isDefault,
      });
      if (response.statusCode == 200) {
        await fetchVehicles();
      } else {
        throw Exception('Failed to update vehicle');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> removeVehicle(String id) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.dio.delete('/vehicles/$id');
      if (response.statusCode == 200) {
        await fetchVehicles();
      } else {
        throw Exception('Failed to delete vehicle');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> setDefault(String id) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.dio.post('/vehicles/$id/default');
      if (response.statusCode == 200) {
        await fetchVehicles();
      } else {
        throw Exception('Failed to set default vehicle');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}

final vehicleProvider =
    StateNotifierProvider<VehicleNotifier, List<EvVehicle>>((ref) {
  return VehicleNotifier(ref);
});
