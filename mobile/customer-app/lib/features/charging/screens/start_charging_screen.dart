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
  String _paymentMethod = 'EcoMargin Wallet (₹850.00)';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                  value: _paymentMethod,
                  isExpanded: true,
                  items: [
                    'EcoMargin Wallet (₹850.00)',
                    'UPI / GPay / PhonePe',
                    'Credit / Debit Card',
                  ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (val) => setState(() => _paymentMethod = val!),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Start Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () {
                  ref.read(chargingSessionProvider.notifier).startCharging();
                  context.push('/live-charging');
                },
                icon: const Icon(Icons.power_settings_new_rounded, color: Colors.white),
                label: const Text('Start Charging Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
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
