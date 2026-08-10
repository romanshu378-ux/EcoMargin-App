import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/core_providers.dart';

class StartChargingScreen extends ConsumerStatefulWidget {
  const StartChargingScreen({super.key});

  @override
  ConsumerState<StartChargingScreen> createState() => _StartChargingScreenState();
}

class _StartChargingScreenState extends ConsumerState<StartChargingScreen> {
  double _targetPercentage = 80.0;
  String? _selectedMethod;
  bool _isStarting = false;

  Future<void> _handleStartCharging() async {
    if (_isStarting) return; // Prevent duplicate taps
    setState(() => _isStarting = true);
    try {
      await ref.read(chargingSessionProvider.notifier).startCharging();
      if (!mounted) return;
      // Only navigate when backend confirms session started
      final session = ref.read(chargingSessionProvider);
      if (session.isCharging) {
        context.go('/live-charging');
      } else {
        _showError('Failed to start charging session. Please check your connection and try again.');
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().contains('timeout')
          ? 'Cannot reach the server. Please check your Wi-Fi and ensure the backend is running.'
          : 'Charging start failed: ${e.toString()}';
      _showError(msg);
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
              child: const Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Color(0xFF16A34A),
                    child: Icon(Icons.bolt, color: Colors.white),
                  ),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('GreenCharge Hub Sector 62', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text('Charger: CHG-DC-04 (60 kW DC)', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                    ],
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
