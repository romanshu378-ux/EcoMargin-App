import 'package:flutter/material.dart';

class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vendor Earnings')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text('Available Payout Balance', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            const Text('\$18,450.00', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFFF97316))),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF97316), minimumSize: const Size.fromHeight(50)),
              child: const Text('Request Bank Payout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
