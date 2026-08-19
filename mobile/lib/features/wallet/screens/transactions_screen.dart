import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txsAsync = ref.watch(walletTransactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(walletTransactionsProvider);
        },
        child: txsAsync.when(
          data: (txs) {
            if (txs.isEmpty) {
              return const Center(
                child: Text('No transaction history found', style: TextStyle(color: Colors.grey)),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: txs.length,
              itemBuilder: (context, index) {
                final tx = txs[index];
                final isCredit = tx['type'] == 'CREDIT';
                final title = isCredit ? 'Wallet Top-Up (Razorpay)' : 'EV Charging Session #${tx['sessionId'] ?? ''}';
                final amt = double.tryParse(tx['amount']?.toString() ?? '0') ?? 0.0;
                final amountText = isCredit ? '+₹${amt.toStringAsFixed(2)}' : '-₹${amt.abs().toStringAsFixed(2)}';
                final dateStr = tx['createdAt'] != null 
                    ? tx['createdAt'].toString().split('T')[0]
                    : 'Unknown Date';

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isCredit ? Colors.green.withValues(alpha: 0.15) : Colors.red.withValues(alpha: 0.15),
                      child: Icon(
                        isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                        color: isCredit ? Colors.green : Colors.red,
                      ),
                    ),
                    title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text(dateStr, style: const TextStyle(fontSize: 12)),
                    trailing: Text(
                      amountText,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isCredit ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFF16A34A)),
          ),
          error: (err, st) => Center(
            child: Text('Failed to load transactions: $err', style: const TextStyle(color: Colors.red)),
          ),
        ),
      ),
    );
  }
}
