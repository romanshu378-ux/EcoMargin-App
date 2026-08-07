import 'package:flutter/material.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  final List<Map<String, String>> _transactions = const [
    {
      'title': 'Wallet Top-Up (Razorpay)',
      'date': '07 Aug 2026, 01:10 PM',
      'amount': '+₹500.00',
      'isCredit': 'true',
    },
    {
      'title': 'EV Charging Session #CHG-409',
      'date': '07 Aug 2026, 02:30 PM',
      'amount': '-₹261.00',
      'isCredit': 'false',
    },
    {
      'title': 'Promo Cashback Received',
      'date': '01 Aug 2026, 10:00 AM',
      'amount': '+₹50.00',
      'isCredit': 'true',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _transactions.length,
        itemBuilder: (context, index) {
          final item = _transactions[index];
          final isCredit = item['isCredit'] == 'true';
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isCredit ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
                child: Icon(
                  isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                  color: isCredit ? Colors.green : Colors.red,
                ),
              ),
              title: Text(item['title']!, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(item['date']!),
              trailing: Text(
                item['amount']!,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isCredit ? Colors.green : Colors.red,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
