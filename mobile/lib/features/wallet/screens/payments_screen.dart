import 'package:flutter/material.dart';

class PaymentsScreen extends StatelessWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Payment Methods'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const ListTile(
            leading: Icon(Icons.account_balance_wallet, color: Color(0xFF16A34A)),
            title: Text('EcoMargin Wallet', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Primary Default Balance: ₹850.00'),
            trailing: Icon(Icons.check_circle, color: Color(0xFF16A34A)),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.qr_code_2, color: Colors.blue),
            title: const Text('Google Pay / PhonePe UPI'),
            subtitle: const Text('driver@okaxis'),
            trailing: TextButton(onPressed: () {}, child: const Text('Remove')),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.credit_card, color: Colors.purple),
            title: const Text('HDFC Bank Visa Card'),
            subtitle: const Text('•••• •••• •••• 4092'),
            trailing: TextButton(onPressed: () {}, child: const Text('Remove')),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add, color: Color(0xFF16A34A)),
            label: const Text('Add New Payment Method', style: TextStyle(color: Color(0xFF16A34A))),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF16A34A)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
