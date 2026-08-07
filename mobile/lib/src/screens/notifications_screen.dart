import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ListTile(
            leading: Icon(Icons.bolt, color: Color(0xFF10B981)),
            title: Text('Session Complete'),
            subtitle: Text('Your battery reached 85%. Charged 42.5 kWh.'),
          ),
        ],
      ),
    );
  }
}
