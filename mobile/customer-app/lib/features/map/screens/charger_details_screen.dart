import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ChargerDetailsScreen extends StatelessWidget {
  final String? connectorId;
  final String? chargerId;
  final String? stationId;

  const ChargerDetailsScreen({
    super.key,
    this.connectorId,
    this.chargerId,
    this.stationId,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Charger Specifications'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Charger ID', style: TextStyle(color: Color(0xFF64748B))),
                      Text(chargerId ?? 'CHG-DC-04', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(height: 24),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Connector Standard', style: TextStyle(color: Color(0xFF64748B))),
                      Text('CCS2 Dual Gun', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(height: 24),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Max Output Power', style: TextStyle(color: Color(0xFF64748B))),
                      Text('60 kW (Ultra Fast)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                    ],
                  ),
                  const Divider(height: 24),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Voltage Range', style: TextStyle(color: Color(0xFF64748B))),
                      Text('200V - 1000V DC', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(height: 24),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Tariff Rate', style: TextStyle(color: Color(0xFF64748B))),
                      Text('₹18.00 / kWh', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Compatible Vehicles', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                Chip(label: Text('Tata Nexon EV Max')),
                Chip(label: Text('MG ZS EV')),
                Chip(label: Text('Hyundai Ioniq 5')),
                Chip(label: Text('Kia EV6')),
                Chip(label: Text('Mahindra XUV400')),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => context.push(
                  '/start-charging',
                  extra: {
                    'connectorId': connectorId,
                    'chargerId': chargerId,
                    'stationId': stationId,
                  },
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Proceed to Start Charging', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
