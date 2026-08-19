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
class PowerSample {
  final DateTime timestamp;
  final double powerKw;

  const PowerSample({
    required this.timestamp,
    required this.powerKw,
  });
}

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
  final double? voltage;
  final double? current;
  final int durationSeconds;
  final double totalCost;
  final bool hasConnectionError;
  final DateTime? startTime;
  final DateTime? lastUpdated;
  final List<PowerSample> powerSamples;

  ChargingSessionState({
    this.isCharging = false,
    this.sessionId,
    this.status = 'COMPLETED',
    this.stationName = 'EcoMargin Charging Hub',
    this.chargerId = '',
    this.connectorType = '',
    this.percentage = 0.0,
    this.kwhDelivered = 0.0,
    this.currentPowerKw = 0.0,
    this.voltage,
    this.current,
    this.durationSeconds = 0,
    this.totalCost = 0.0,
    this.hasConnectionError = false,
    this.startTime,
    this.lastUpdated,
    this.powerSamples = const [],
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
    double? voltage,
    double? current,
    int? durationSeconds,
    double? totalCost,
    bool? hasConnectionError,
    DateTime? startTime,
    DateTime? lastUpdated,
    List<PowerSample>? powerSamples,
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
      voltage: voltage ?? this.voltage,
      current: current ?? this.current,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      totalCost: totalCost ?? this.totalCost,
      hasConnectionError: hasConnectionError ?? this.hasConnectionError,
      startTime: startTime ?? this.startTime,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      powerSamples: powerSamples ?? this.powerSamples,
    );
  }
}

class ChargingSessionNotifier extends StateNotifier<ChargingSessionState> with WidgetsBindingObserver {
  final Ref ref;
  Timer? _timer;
  bool _isStarting = false;
  bool _isAppPaused = false;

  ChargingSessionNotifier(this.ref) : super(ChargingSessionState()) {
    WidgetsBinding.instance.addObserver(this);
    checkActiveSession();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _isAppPaused = true;
      _timer?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      _isAppPaused = false;
      checkActiveSession();
    }
  }

  Future<void> fetchWalletBalance() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.dio.get('/wallet/balance');
      if (response.statusCode == 200 && response.data != null) {
        final bal = double.tryParse(response.data['balance']?.toString() ?? '0') ?? 0.0;
        ref.read(walletBalanceProvider.notifier).state = bal;
      }
    } catch (_) {}
  }

  Future<void> checkActiveSession() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.dio.get('/charging-sessions/active');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        final status = (data['status'] ?? 'CHARGING').toString().toUpperCase();
        
        final isActive = status == 'ACTIVE' ||
                         status == 'STARTING' ||
                         status == 'PREPARING' ||
                         status == 'CHARGING' ||
                         status == 'STOPPING';

        final sessId = data['sessionId']?.toString();
        if (sessId != null) {
          final storage = ref.read(storageServiceProvider);
          await storage.saveData('active_session_id', sessId);
        }

        double? volt;
        if (data['voltage'] != null) {
          volt = double.tryParse(data['voltage'].toString());
        } else if (data['voltageV'] != null) {
          volt = double.tryParse(data['voltageV'].toString());
        }

        double? curr;
        if (data['current'] != null) {
          curr = double.tryParse(data['current'].toString());
        } else if (data['currentA'] != null) {
          curr = double.tryParse(data['currentA'].toString());
        }

        DateTime? parsedStart;
        if (data['startTime'] != null) {
          parsedStart = DateTime.tryParse(data['startTime'].toString());
        }

        int durationSecs = 0;
        if (data['durationSeconds'] != null) {
          durationSecs = int.tryParse(data['durationSeconds'].toString()) ?? 0;
        } else if (parsedStart != null) {
          durationSecs = DateTime.now().difference(parsedStart).inSeconds;
        }

        // Live wallet balance sync from backend
        if (data['walletBalance'] != null) {
          final wBal = double.tryParse(data['walletBalance'].toString());
          if (wBal != null) {
            ref.read(walletBalanceProvider.notifier).state = wBal;
          }
        } else {
          fetchWalletBalance();
        }

        final pKw = double.tryParse(data['currentPowerKw']?.toString() ?? '0') ?? 0.0;
        final updatedSamples = List<PowerSample>.from(state.powerSamples);
        if (pKw > 0 || updatedSamples.isNotEmpty) {
          updatedSamples.add(PowerSample(timestamp: DateTime.now(), powerKw: pKw));
          if (updatedSamples.length > 100) {
            updatedSamples.removeAt(0);
          }
        }

        state = ChargingSessionState(
          isCharging: isActive,
          sessionId: sessId,
          status: status,
          stationName: data['stationName'] ?? 'EcoMargin Charging Hub',
          chargerId: data['chargerId'] ?? '',
          connectorType: data['connectorType'] ?? '',
          percentage: double.tryParse(data['percentage']?.toString() ?? '0') ?? 0.0,
          kwhDelivered: double.tryParse(data['kwhDelivered']?.toString() ?? '0') ?? 0.0,
          currentPowerKw: pKw,
          voltage: volt,
          current: curr,
          durationSeconds: durationSecs,
          totalCost: double.tryParse(data['totalCost']?.toString() ?? '0') ?? 0.0,
          hasConnectionError: false,
          startTime: parsedStart,
          lastUpdated: DateTime.now(),
          powerSamples: updatedSamples,
        );

        if (isActive && !_isAppPaused) {
          _startPolling();
        } else {
          _timer?.cancel();
        }
      } else {
        _timer?.cancel();
        final storage = ref.read(storageServiceProvider);
        await storage.saveData('active_session_id', null);
        state = state.copyWith(isCharging: false, hasConnectionError: false);
      }
    } catch (_) {
      if (state.isCharging) {
        state = state.copyWith(hasConnectionError: true);
        if (!_isAppPaused) {
          _startPolling();
        }
      } else {
        _timer?.cancel();
        state = state.copyWith(isCharging: false, hasConnectionError: false);
      }
    }
  }

  void _startPolling() {
    _timer?.cancel();
    if (_isAppPaused) return;
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (_isAppPaused) {
        _timer?.cancel();
        return;
      }
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
        final status = (data['status'] ?? 'CHARGING').toString().toUpperCase();
        final sessId = data['sessionId']?.toString();
        if (sessId != null) {
          final storage = ref.read(storageServiceProvider);
          await storage.saveData('active_session_id', sessId);
        }

        state = ChargingSessionState(
          isCharging: true,
          sessionId: sessId,
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
        state = state.copyWith(hasConnectionError: true);
      }
    } catch (e) {
      state = state.copyWith(isCharging: false, hasConnectionError: true);
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
        final storage = ref.read(storageServiceProvider);
        await storage.saveData('active_session_id', null);

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
        
        final walletBal = double.tryParse(data['walletBalance']?.toString() ?? '0') ?? 0.0;
        Future.microtask(() {
          ref.read(walletBalanceProvider.notifier).state = walletBal;
          ref.invalidate(walletBalanceAsyncProvider);
          ref.invalidate(walletTransactionsProvider);
          ref.invalidate(chargingHistoryProvider);
        });
      }
    } catch (_) {
      _timer?.cancel();
      final storage = ref.read(storageServiceProvider);
      await storage.saveData('active_session_id', null);
      state = state.copyWith(isCharging: false, hasConnectionError: false);
      Future.microtask(() {
        ref.invalidate(walletBalanceAsyncProvider);
        ref.invalidate(walletTransactionsProvider);
        ref.invalidate(chargingHistoryProvider);
      });
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
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }
}

final chargingSessionProvider =
    StateNotifierProvider<ChargingSessionNotifier, ChargingSessionState>((ref) {
  return ChargingSessionNotifier(ref);
});

final walletBalanceAsyncProvider = FutureProvider.autoDispose<double>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.dio.get('/wallet/balance');
  if (response.statusCode == 200 && response.data != null) {
    final bal = double.tryParse(response.data['balance']?.toString() ?? '0') ?? 0.0;
    ref.read(walletBalanceProvider.notifier).state = bal;
    return bal;
  }
  throw Exception('Failed to load wallet balance');
});

final walletTransactionsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.dio.get('/wallet/transactions');
  if (response.statusCode == 200 && response.data is List) {
    return List<Map<String, dynamic>>.from(response.data);
  }
  return [];
});

final chargingHistoryProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.dio.get('/charging-sessions/history');
  if (response.statusCode == 200 && response.data is List) {
    return List<Map<String, dynamic>>.from(response.data);
  }
  return [];
});

final notificationsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.dio.get('/notifications');
  if (response.statusCode == 200 && response.data is List) {
    return List<Map<String, dynamic>>.from(response.data);
  }
  return [];
});

final unreadNotificationCountProvider = StateProvider<int>((ref) => 0);

final unreadNotificationCountAsyncProvider = FutureProvider.autoDispose<int>((ref) async {
  try {
    final apiClient = ref.watch(apiClientProvider);
    final response = await apiClient.dio.get('/notifications/unread-count');
    if (response.statusCode == 200 && response.data != null) {
      final count = int.tryParse(response.data['unreadCount']?.toString() ?? '0') ?? 0;
      ref.read(unreadNotificationCountProvider.notifier).state = count;
      return count;
    }
  } catch (_) {}
  return 0;
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

class RfidCard {
  final int? id;
  final String cardNumber;
  final String cardUid;
  final String status;
  final String linkedVehicle;
  final String issuedDate;
  final String lastUsed;

  RfidCard({
    this.id,
    required this.cardNumber,
    required this.cardUid,
    required this.status,
    required this.linkedVehicle,
    required this.issuedDate,
    required this.lastUsed,
  });

  factory RfidCard.fromJson(Map<String, dynamic> json) {
    return RfidCard(
      id: json['id'],
      cardNumber: json['cardNumber'] ?? '',
      cardUid: json['cardUid'] ?? '',
      status: json['status'] ?? 'ACTIVE',
      linkedVehicle: json['linkedVehicle'] ?? '',
      issuedDate: json['issuedDate'] ?? '',
      lastUsed: json['lastUsed'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cardNumber': cardNumber,
      'cardUid': cardUid,
      'status': status,
      'linkedVehicle': linkedVehicle,
      'issuedDate': issuedDate,
      'lastUsed': lastUsed,
    };
  }
}

class PrivacySettings {
  final bool locationPermission;
  final bool locationSharing;
  final bool nearbyChargerPersonalization;
  final bool pushNotifications;
  final bool chargingActivityVisibility;
  final bool usageAnalytics;
  final bool personalizedRecommendations;

  PrivacySettings({
    required this.locationPermission,
    required this.locationSharing,
    required this.nearbyChargerPersonalization,
    required this.pushNotifications,
    required this.chargingActivityVisibility,
    required this.usageAnalytics,
    required this.personalizedRecommendations,
  });

  factory PrivacySettings.fromJson(Map<String, dynamic> json) {
    return PrivacySettings(
      locationPermission: json['locationPermission'] ?? true,
      locationSharing: json['locationSharing'] ?? true,
      nearbyChargerPersonalization: json['nearbyChargerPersonalization'] ?? true,
      pushNotifications: json['pushNotifications'] ?? true,
      chargingActivityVisibility: json['chargingActivityVisibility'] ?? true,
      usageAnalytics: json['usageAnalytics'] ?? true,
      personalizedRecommendations: json['personalizedRecommendations'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'locationPermission': locationPermission,
      'locationSharing': locationSharing,
      'nearbyChargerPersonalization': nearbyChargerPersonalization,
      'pushNotifications': pushNotifications,
      'chargingActivityVisibility': chargingActivityVisibility,
      'usageAnalytics': usageAnalytics,
      'personalizedRecommendations': personalizedRecommendations,
    };
  }

  PrivacySettings copyWith({
    bool? locationPermission,
    bool? locationSharing,
    bool? nearbyChargerPersonalization,
    bool? pushNotifications,
    bool? chargingActivityVisibility,
    bool? usageAnalytics,
    bool? personalizedRecommendations,
  }) {
    return PrivacySettings(
      locationPermission: locationPermission ?? this.locationPermission,
      locationSharing: locationSharing ?? this.locationSharing,
      nearbyChargerPersonalization: nearbyChargerPersonalization ?? this.nearbyChargerPersonalization,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      chargingActivityVisibility: chargingActivityVisibility ?? this.chargingActivityVisibility,
      usageAnalytics: usageAnalytics ?? this.usageAnalytics,
      personalizedRecommendations: personalizedRecommendations ?? this.personalizedRecommendations,
    );
  }
}

class RfidNotifier extends StateNotifier<AsyncValue<RfidCard?>> {
  final Ref ref;

  RfidNotifier(this.ref) : super(const AsyncValue.loading()) {
    fetchRfidCard();
  }

  Future<void> fetchRfidCard() async {
    try {
      state = const AsyncValue.loading();
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.dio.get('/rfid');
      if (response.statusCode == 200) {
        state = AsyncValue.data(RfidCard.fromJson(response.data));
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 404) {
        state = const AsyncValue.data(null);
      } else {
        state = AsyncValue.error(e, StackTrace.current);
      }
    }
  }

  Future<void> linkRfidCard(String cardNumber, String cardUid, {String? linkedVehicle}) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.dio.post('/rfid/link', data: {
        'cardNumber': cardNumber,
        'cardUid': cardUid,
        if (linkedVehicle != null) 'linkedVehicle': linkedVehicle,
      });
      if (response.statusCode == 200 || response.statusCode == 201) {
        state = AsyncValue.data(RfidCard.fromJson(response.data));
      } else {
        throw Exception('Failed to link RFID card');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> unlinkRfidCard() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.dio.post('/rfid/unlink');
      if (response.statusCode == 200) {
        state = const AsyncValue.data(null);
      } else {
        throw Exception('Failed to unlink RFID card');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> blockRfidCard() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.dio.post('/rfid/block');
      if (response.statusCode == 200) {
        state = AsyncValue.data(RfidCard.fromJson(response.data));
      } else {
        throw Exception('Failed to block RFID card');
      }
    } catch (e) {
      rethrow;
    }
  }
}

final rfidProvider = StateNotifierProvider<RfidNotifier, AsyncValue<RfidCard?>>((ref) {
  return RfidNotifier(ref);
});

class PrivacyNotifier extends StateNotifier<AsyncValue<PrivacySettings>> {
  final Ref ref;
  static const String _cacheKey = 'cached_privacy_settings';

  PrivacyNotifier(this.ref) : super(const AsyncValue.loading()) {
    loadCachedOrFetch();
  }

  Future<void> loadCachedOrFetch() async {
    try {
      state = const AsyncValue.loading();
      final storageService = ref.read(storageServiceProvider);
      final cachedData = storageService.getData(_cacheKey);
      if (cachedData != null && cachedData is Map) {
        final castedMap = Map<String, dynamic>.from(cachedData);
        state = AsyncValue.data(PrivacySettings.fromJson(castedMap));
      }
      await fetchPrivacySettings();
    } catch (e) {
      if (state.hasValue) {
        // Keep cached
      } else {
        state = AsyncValue.error(e, StackTrace.current);
      }
    }
  }

  Future<void> fetchPrivacySettings() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.dio.get('/privacy');
      if (response.statusCode == 200) {
        final settings = PrivacySettings.fromJson(response.data);
        final storageService = ref.read(storageServiceProvider);
        await storageService.saveData(_cacheKey, settings.toJson());
        state = AsyncValue.data(settings);
      }
    } catch (e) {
      if (!state.hasValue) {
        state = AsyncValue.error(e, StackTrace.current);
      }
    }
  }

  Future<void> updatePrivacySettings(PrivacySettings updated) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.dio.put('/privacy', data: updated.toJson());
      if (response.statusCode == 200) {
        final settings = PrivacySettings.fromJson(response.data);
        final storageService = ref.read(storageServiceProvider);
        await storageService.saveData(_cacheKey, settings.toJson());
        state = AsyncValue.data(settings);
      }
    } catch (e) {
      rethrow;
    }
  }
}

final privacyProvider = StateNotifierProvider<PrivacyNotifier, AsyncValue<PrivacySettings>>((ref) {
  return PrivacyNotifier(ref);
});

class FaqItem {
  final String question;
  final String answer;

  FaqItem({required this.question, required this.answer});
}

final faqProvider = FutureProvider<List<FaqItem>>((ref) async {
  try {
    await Future.delayed(const Duration(milliseconds: 300));
    return _getFaqList();
  } catch (e) {
    return _getFaqList();
  }
});

List<FaqItem> _getFaqList() {
  return [
    FaqItem(
      question: 'How do I find a nearby charging station?',
      answer: 'Go to the Map tab from the bottom navigation bar. You can search for stations, view their details, check connector availability, and get directions.',
    ),
    FaqItem(
      question: 'How do I start charging?',
      answer: 'Scan the QR code on the charger or enter the Charger ID manually on the QR Scan screen, select your connector, verify wallet balance, and tap Start Charging.',
    ),
    FaqItem(
      question: 'How do I stop a charging session?',
      answer: 'Go to the Live Session screen and tap Stop Charging. The session will end, and the total cost will be automatically deducted from your EcoMargin Wallet.',
    ),
    FaqItem(
      question: 'How is charging cost calculated?',
      answer: 'The cost is calculated based on the per-kWh rate of the selected charger, plus any applicable session fee or taxes. You can see the rate details on the Station Details screen.',
    ),
    FaqItem(
      question: 'How does the EcoMargin Wallet work?',
      answer: 'The EcoMargin Wallet holds your pre-loaded balance. When you start charging, the system reserves a minimum balance, and once completed, the final amount is deducted from the wallet.',
    ),
    FaqItem(
      question: 'How can I add money to my wallet?',
      answer: 'Go to the Wallet tab, tap Add Money, enter the desired amount, and complete the payment using credit/debit card, UPI, net banking, or other available payment methods.',
    ),
    FaqItem(
      question: 'What happens if my wallet balance is insufficient?',
      answer: 'If your wallet balance falls below the minimum required amount (typically 100 INR / \$10), you will not be able to start a charging session. Please top up your wallet.',
    ),
    FaqItem(
      question: 'How does RFID charging work?',
      answer: 'Once you link an RFID card to your account, you can simply tap the card on any EcoMargin charging station RFID reader to start and stop charging without opening the mobile app.',
    ),
    FaqItem(
      question: 'How do I link an RFID card?',
      answer: 'Go to Profile -> RFID Card, tap "Link RFID Card", enter the Card Number and Card UID printed on the card, and select a vehicle to link it.',
    ),
    FaqItem(
      question: 'What happens if I lose my RFID card?',
      answer: 'If you lose your RFID card, immediately go to Profile -> RFID Card and select "Block Card" or "Report Lost Card" to disable it. You can then unlink it and link a new card.',
    ),
    FaqItem(
      question: 'How can I view charging history?',
      answer: 'Go to Profile -> Charging History to see the list of all past charging sessions, including energy consumed, duration, cost, and receipts.',
    ),
    FaqItem(
      question: 'How do I update my profile?',
      answer: 'Go to Profile, tap Edit Profile (pencil icon or button), modify your details (Name, Mobile, Date of Birth), and tap Save to update your profile.',
    ),
    FaqItem(
      question: 'How can I change privacy settings?',
      answer: 'Go to Profile -> Privacy Settings, where you can toggle location permissions, push notifications, charging activity visibility, and usage analytics.',
    ),
    FaqItem(
      question: 'What should I do if a charger is unavailable?',
      answer: 'If a charger is in use or out of service, search the Map tab for other active stations nearby, or tap the Help & Support button to report the issue.',
    ),
    FaqItem(
      question: 'What should I do if charging fails?',
      answer: 'If charging fails to start, check that the connector is plugged in correctly, verify your wallet balance, restart the app, or call our 24/7 support hotline.',
    ),
    FaqItem(
      question: 'How can I contact EcoMargin support?',
      answer: 'Go to App Settings -> Help & Support. You can raise a complaint, email support@ecomargin.com, or call our support team directly.',
    ),
  ];
}
