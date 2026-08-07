import 'package:flutter/material.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Network Monitor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.warning_amber_outlined, color: Colors.amber),
            onPressed: () => Navigator.pushNamed(context, '/alerts'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF065F46), Color(0xFF0F172A)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Platform Revenue', style: TextStyle(color: Colors.grey, fontSize: 13)),
                SizedBox(height: 4),
                Text('\$128,450.00', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
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
                    leading: const Icon(Icons.people, color: Color(0xFF10B981)),
                    title: const Text('4,892'),
                    subtitle: const Text('Drivers'),
                    onTap: () => Navigator.pushNamed(context, '/users'),
                  ),
                ),
              ),
              Expanded(
                child: Card(
                  color: const Color(0xFF1E293B),
                  child: ListTile(
                    leading: const Icon(Icons.store, color: Colors.purpleAccent),
                    title: const Text('38'),
                    subtitle: const Text('Vendors'),
                    onTap: () => Navigator.pushNamed(context, '/vendors'),
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
