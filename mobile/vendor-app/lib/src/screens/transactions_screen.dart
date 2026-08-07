import 'package:flutter/material.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Session Transactions')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ListTile(
            title: Text('TX-V901 • SESS-9081'),
            subtitle: Text('42.5 kWh • Gross: \$18.70'),
            trailing: Text('\$16.83 Net', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF97316))),
          ),
        ],
      ),
    );
  }
}
