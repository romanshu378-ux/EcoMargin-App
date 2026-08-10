import 'package:flutter/material.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  double _balance = 45.50;

  void _depositFunds() {
    setState(() => _balance += 25.00);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Deposited \$25.00 via Google Pay!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Wallet')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Wallet balance card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF047857)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TOTAL BALANCE', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      '\$${_balance.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    const Text('Currency: USD', style: TextStyle(color: Colors.white60, fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              ElevatedButton.icon(
                onPressed: _depositFunds,
                icon: const Icon(Icons.add_card_rounded),
                label: const Text('Quick Deposit \$25.00', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 32),
              
              const Text('Recent Deposits', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 12),
              
              // Transactions list
              Expanded(
                child: ListView(
                  children: [
                    _buildTxRow('Google Pay Topup', 'Success', '+\$25.00', 'Today, 08:30'),
                    _buildTxRow('Debit Session SESS-202', 'Success', '-\$17.11', 'Yesterday, 18:45'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTxRow(String title, String status, String amount, String date) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.wallet_rounded, color: Color(0xFF10B981), size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      subtitle: Text('$date • $status', style: const TextStyle(fontSize: 11, color: Colors.grey)),
      trailing: Text(amount, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: amount.startsWith('+') ? const Color(0xFF10B981) : null)),
    );
  }
}
