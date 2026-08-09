import 'package:flutter/material.dart';

class ChargingSessionScreen extends StatelessWidget {
  const ChargingSessionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Charging Session')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Spacer(),
            const Icon(Icons.bolt, size: 100, color: Color(0xFF10B981)),
            const SizedBox(height: 16),
            const Text('84%', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white)),
            const Text('Battery State of Charge', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text('18.4 kWh', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                      Text('Delivered', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  Column(
                    children: [
                      Text('₹8.10', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text('Current Cost', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  Column(
                    children: [
                      Text('145 kW', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber)),
                      Text('Power Rate', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Stop Charging Session', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
