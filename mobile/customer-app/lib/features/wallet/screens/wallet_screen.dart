import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/core_providers.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(walletBalanceProvider);
    final txsAsync = ref.watch(walletTransactionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Digital Wallet')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Available Balance', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 8),
                Text(
                  '₹${balance.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.push('/add-money'),
            child: const Text('Top Up Balance'),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () => context.push('/transactions'),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          txsAsync.when(
            data: (txs) {
              if (txs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text('No recent transactions', style: TextStyle(color: Colors.grey)),
                  ),
                );
              }
              final recentTxs = txs.take(3).toList();
              return Column(
                children: recentTxs.map((tx) {
                  final isCredit = tx['type'] == 'CREDIT';
                  final title = isCredit ? 'Wallet Top Up' : 'EV Charging Session';
                  final amt = double.tryParse(tx['amount']?.toString() ?? '0') ?? 0.0;
                  final amountText = isCredit ? '+₹${amt.toStringAsFixed(2)}' : '-₹${amt.abs().toStringAsFixed(2)}';
                  final dateStr = tx['createdAt'] != null 
                      ? tx['createdAt'].toString().split('T')[0]
                      : 'Today';

                  return Column(
                    children: [
                      _buildTransactionTile(context, title, amountText, dateStr, isCredit),
                      const Divider(height: 1),
                    ],
                  );
                }).toList(),
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: CircularProgressIndicator(color: Color(0xFF16A34A)),
              ),
            ),
            error: (err, st) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text('Failed to load transactions: $err', style: const TextStyle(color: Colors.red)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(BuildContext context, String title, String amount, String date, bool isCredit) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: isCredit ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
        child: Icon(
          isCredit ? Icons.arrow_downward : Icons.arrow_upward,
          color: isCredit ? Colors.green : Colors.red,
        ),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(date, style: const TextStyle(fontSize: 12)),
      trailing: Text(
        amount,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isCredit ? Colors.green : Colors.red,
          fontSize: 15,
        ),
      ),
    );
  }
}
