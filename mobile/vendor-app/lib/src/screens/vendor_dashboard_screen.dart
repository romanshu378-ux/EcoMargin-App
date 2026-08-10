import 'package:flutter/material.dart';

class VendorDashboardScreen extends StatelessWidget {
  const VendorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ChargeTech CPO Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFC2410C), Color(0xFF0F172A)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Today\'s Revenue', style: TextStyle(color: Colors.grey, fontSize: 13)),
                SizedBox(height: 4),
                Text('\$1,480.50', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Card(
                  color: const Color(0xFF1E293B),
                  child: ListTile(
                    leading: const Icon(Icons.bolt, color: Color(0xFFF97316)),
                    title: const Text('42 Active'),
                    subtitle: const Text('Chargers Online'),
                    onTap: () => Navigator.pushNamed(context, '/chargers'),
                  ),
                ),
              ),
              Expanded(
                child: Card(
                  color: const Color(0xFF1E293B),
                  child: ListTile(
                    leading: const Icon(Icons.account_balance_wallet, color: Color(0xFF10B981)),
                    title: const Text('\$18.4k'),
                    subtitle: const Text('Wallet Balance'),
                    onTap: () => Navigator.pushNamed(context, '/earnings'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
