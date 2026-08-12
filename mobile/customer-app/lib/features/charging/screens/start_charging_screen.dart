import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import '../../../core/providers/core_providers.dart';
import '../../home/providers/home_providers.dart';
import '../../home/models/station.dart';

class StartChargingScreen extends ConsumerStatefulWidget {
  final String? connectorId;
  final String? chargerId;
  final String? stationId;

  const StartChargingScreen({
    super.key,
    this.connectorId,
    this.chargerId,
    this.stationId,
  });

  @override
  ConsumerState<StartChargingScreen> createState() => _StartChargingScreenState();
}

class _StartChargingScreenState extends ConsumerState<StartChargingScreen> {
  double _targetPercentage = 80.0;
  String? _selectedMethod;
  bool _isStarting = false;

  String _formatError(Object e) {
    if (e is DioException) {
      final response = e.response;
      final status = response?.statusCode;
      
      // Req 11 - Debug logging
      debugPrint('[DEBUG] API Method: ${e.requestOptions.method}');
      debugPrint('[DEBUG] API Path: ${e.requestOptions.path}');
      if (status != null) {
        debugPrint('[DEBUG] Response Status: $status');
      }
      if (response?.data != null) {
        debugPrint('[DEBUG] Response Body: ${response?.data}');
      }
      
      // Req 9 - Specific status code checks
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        return 'Unable to connect to server. Please check your network connection and try again.';
      }
      
      if (status != null) {
        switch (status) {
          case 401:
            return 'Authentication expired. Please log in again.';
          case 403:
            return 'Access denied. You do not have permission to start charging.';
          case 404:
            return 'Endpoint mismatch or service not found. Please contact support.';
          case 409:
            return 'A charging session conflict occurred. An active session might already exist.';
          case 400:
          case 422:
            String? serverMsg;
            if (response?.data is Map) {
              serverMsg = response?.data['message'] ?? response?.data['error'];
            } else if (response?.data is String) {
              try {
                final parsed = jsonDecode(response?.data as String);
                if (parsed is Map) {
                  serverMsg = parsed['message'] ?? parsed['error'];
                }
              } catch (_) {}
            }
            return serverMsg ?? 'Validation failed. Please verify your inputs and try again.';
          case 500:
            return 'Temporary server error. Please try again in a few moments.';
        }
      }
    }
    
    final str = e.toString();
    if (str.contains('timeout') || str.contains('SocketException')) {
      return 'Unable to connect to server. Please check your network connection and try again.';
    }
    return 'Charging start failed. Please try again.';
  }

  void _showInsufficientBalanceDialog({required double balance, required double requiredBalance}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 28),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('Insufficient Wallet Balance', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your wallet balance is insufficient to start this charging session.',
              style: TextStyle(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Available Balance:', style: TextStyle(fontSize: 13)),
                      Text('₹${balance.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Minimum Required:', style: TextStyle(fontSize: 13)),
                      Text('₹${requiredBalance.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF16A34A))),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.push('/add-money');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Add Money', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleStartCharging() async {
    if (_isStarting) return; // Prevent duplicate taps
    setState(() => _isStarting = true);
    
    double minRequiredBalance = 50.0; // Standard business logic fallback
    
    try {
      // 1. Fetch current configuration from backend
      try {
        final apiClient = ref.read(apiClientProvider);
        final configResponse = await apiClient.dio.get('/charging-sessions/config');
        if (configResponse.statusCode == 200 && configResponse.data != null) {
          final data = configResponse.data;
          minRequiredBalance = double.tryParse(data['minRequiredBalance']?.toString() ?? '50.0') ?? 50.0;
        }
      } catch (e) {
        debugPrint('[DEBUG] Config fetch failed, using fallback ₹$minRequiredBalance: $e');
      }

      // 2. Fetch current wallet balance
      try {
        await ref.read(chargingSessionProvider.notifier).fetchWalletBalance();
      } catch (e) {
        debugPrint('[DEBUG] Failed to fetch latest wallet balance: $e');
      }
      final balance = ref.read(walletBalanceProvider);
      
      // Debug logging wallet balance and required amount
      debugPrint('[DEBUG] Current Wallet Balance: ₹$balance');
      debugPrint('[DEBUG] Required Wallet Balance: ₹$minRequiredBalance');
      
      if (balance < minRequiredBalance) {
        if (!mounted) return;
        setState(() => _isStarting = false);
        _showInsufficientBalanceDialog(balance: balance, requiredBalance: minRequiredBalance);
        return;
      }

      // 3. Start charging session
      await ref.read(chargingSessionProvider.notifier).startCharging(
        chargerId: widget.chargerId,
        connectorId: widget.connectorId,
      );
      if (!mounted) return;
      
      final session = ref.read(chargingSessionProvider);
      
      // Debug logging session start result
      debugPrint('[DEBUG] Session ID: ${session.sessionId}');
      debugPrint('[DEBUG] Charging Start Result (isCharging): ${session.isCharging}');
      
      if (session.isCharging) {
        context.go('/live-charging');
      } else {
        _showError('Failed to start charging session. Please check your connection and try again.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isStarting = false);
      
      // Catch backend-side balance check error (402 or 400 with code INSUFFICIENT_WALLET_BALANCE)
      if (e is DioException && e.response != null) {
        final data = e.response!.data;
        Map<String, dynamic>? errorData;
        if (data is Map) {
          errorData = Map<String, dynamic>.from(data);
        } else if (data is String) {
          try {
            errorData = Map<String, dynamic>.from(jsonDecode(data) as Map);
          } catch (_) {}
        }
        if (errorData != null && errorData['code'] == 'INSUFFICIENT_WALLET_BALANCE') {
          final avail = double.tryParse(errorData['availableBalance']?.toString() ?? '0') ?? 0.0;
          final req = double.tryParse(errorData['requiredBalance']?.toString() ?? '50.0') ?? 50.0;
          _showInsufficientBalanceDialog(balance: avail, requiredBalance: req);
          return;
        }
      }
      
      _showError(_formatError(e));
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final balance = ref.watch(walletBalanceProvider);
    final walletMethod = 'EcoMargin Wallet (₹${balance.toStringAsFixed(2)})';
    final paymentMethods = [
      walletMethod,
      'UPI / GPay / PhonePe',
      'Credit / Debit Card',
    ];
    final currentMethod = _selectedMethod ?? walletMethod;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Configure Charging Session'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Station Header Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
               child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Color(0xFF16A34A),
                    child: Icon(Icons.bolt, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (() {
                            final stations = ref.read(stationsProvider).value;
                            ChargingStation? station;
                            if (stations != null) {
                              for (final s in stations) {
                                if (s.id == widget.stationId) {
                                  station = s;
                                  break;
                                }
                              }
                            }
                            return station?.name ?? 'GreenCharge Hub Sector 62';
                          })(),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Charger: ${widget.chargerId ?? "CHG-DC-04"} (60 kW DC)',
                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Target Battery Slider
            const Text('Target Battery Limit', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Charge Limit', style: TextStyle(color: Color(0xFF64748B))),
                      Text('${_targetPercentage.toInt()}%', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                    ],
                  ),
                  Slider(
                    value: _targetPercentage,
                    min: 50,
                    max: 100,
                    divisions: 10,
                    activeColor: const Color(0xFF16A34A),
                    label: '${_targetPercentage.toInt()}%',
                    onChanged: (val) => setState(() => _targetPercentage = val),
                  ),
                  const Text('Recommended: 80% to protect battery health.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Payment Option
            const Text('Payment Method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: paymentMethods.contains(currentMethod) ? currentMethod : walletMethod,
                  isExpanded: true,
                  items: paymentMethods.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (val) => setState(() => _selectedMethod = val!),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Start Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                // Disabled (null onPressed) while request is in-flight
                onPressed: _isStarting ? null : _handleStartCharging,
                icon: _isStarting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.power_settings_new_rounded, color: Colors.white),
                label: Text(
                  _isStarting ? 'Starting...' : 'Start Charging Now',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  disabledBackgroundColor: const Color(0xFF4ADE80),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
