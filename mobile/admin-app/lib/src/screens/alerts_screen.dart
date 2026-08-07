import 'package:flutter/material.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('System Alerts')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ListTile(
            leading: Icon(Icons.warning, color: Colors.amber),
            title: Text('High Network Peak'),
            subtitle: Text('Total load exceeded 1.4 MW output threshold.'),
          ),
        ],
      ),
    );
  }
}
