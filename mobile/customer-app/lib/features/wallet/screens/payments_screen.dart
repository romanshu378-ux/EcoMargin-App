import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';

class PaymentsScreen extends ConsumerWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(walletBalanceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Payment Methods'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.account_balance_wallet, color: Color(0xFF16A34A)),
            title: const Text('EcoMargin Wallet', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Primary Default Balance: ₹${balance.toStringAsFixed(2)}'),
            trailing: const Icon(Icons.check_circle, color: Color(0xFF16A34A)),
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
