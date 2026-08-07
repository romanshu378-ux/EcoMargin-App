import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  final List<Map<String, String>> _notifications = const [
    {
      'title': 'Charging Session Completed',
      'body': 'Your EV reached 80% charge at GreenCharge Hub Sector 62. Total energy: 14.5 kWh.',
      'time': '10 mins ago',
      'icon': 'bolt',
    },
    {
      'title': 'Wallet Top-Up Successful',
      'body': '₹500.00 added to EcoMargin Wallet via Razorpay UPI.',
      'time': '2 hours ago',
      'icon': 'wallet',
    },
    {
      'title': 'New Fast Charger Near You!',
      'body': '120 kW Ultra-Fast DC charging station opened at Whitefield Road.',
      'time': '1 day ago',
      'icon': 'offer',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final item = _notifications[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF16A34A),
                child: Icon(Icons.notifications_active, color: Colors.white),
              ),
              title: Text(item['title']!, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(item['body']!),
              ),
              trailing: Text(item['time']!, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
            ),
          );
        },
      ),
    );
  }
}
