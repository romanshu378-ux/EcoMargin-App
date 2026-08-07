import 'package:flutter/material.dart';

class PaymentsScreen extends StatelessWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Payment Methods')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ListTile(
            leading: Icon(Icons.credit_card, color: Color(0xFF10B981)),
            title: Text('Visa ending in 4242'),
            subtitle: Text('Expires 12/28'),
            trailing: Icon(Icons.check_circle, color: Color(0xFF10B981)),
          ),
        ],
      ),
    );
  }
}
