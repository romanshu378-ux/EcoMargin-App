import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChargingSessionState {
  final bool isCharging;
  final double kwhDelivered;
  final double totalCost;
  final double ratePerKwh;
  final String status;
  final Duration elapsed;

  ChargingSessionState({
    required this.isCharging,
    required this.kwhDelivered,
    required this.totalCost,
    required this.ratePerKwh,
    required this.status,
    required this.elapsed,
  });

  ChargingSessionState copyWith({
    bool? isCharging,
    double? kwhDelivered,
    double? totalCost,
    double? ratePerKwh,
    String? status,
    Duration? elapsed,
  }) {
    return ChargingSessionState(
      isCharging: isCharging ?? this.isCharging,
      kwhDelivered: kwhDelivered ?? this.kwhDelivered,
      totalCost: totalCost ?? this.totalCost,
      ratePerKwh: ratePerKwh ?? this.ratePerKwh,
      status: status ?? this.status,
      elapsed: elapsed ?? this.elapsed,
    );
  }
}

class SessionNotifier extends StateNotifier<ChargingSessionState> {
  Timer? _timer;

  SessionNotifier() : super(ChargingSessionState(
    isCharging: false,
    kwhDelivered: 0.0,
    totalCost: 0.0,
    ratePerKwh: 0.35,
    status: 'Idle',
    elapsed: Duration.zero,
  ));

  void startSession() {
    _timer?.cancel();
    state = ChargingSessionState(
      isCharging: true,
      kwhDelivered: 0.0,
      totalCost: 0.0,
      ratePerKwh: 0.35,
      status: 'Charging',
      elapsed: Duration.zero,
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!state.isCharging) {
        timer.cancel();
        return;
      }
      
      final nextKwh = state.kwhDelivered + 0.05;
      final nextCost = nextKwh * state.ratePerKwh;
      final nextElapsed = state.elapsed + const Duration(seconds: 1);

      state = state.copyWith(
        kwhDelivered: nextKwh,
        totalCost: nextCost,
        elapsed: nextElapsed,
      );
    });
  }

  void stopSession() {
    _timer?.cancel();
    state = state.copyWith(
      isCharging: false,
      status: 'Completed',
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final sessionProvider = StateNotifierProvider<SessionNotifier, ChargingSessionState>((ref) {
  return SessionNotifier();
});
