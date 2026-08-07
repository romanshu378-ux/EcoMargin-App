import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CPO Alerts')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ListTile(
            leading: Icon(Icons.warning, color: Colors.amber),
            title: Text('High Usage Peak Detected'),
            subtitle: Text('Downtown Hub Fast Charge at 90% power load capacity.'),
          ),
        ],
      ),
    );
  }
}
