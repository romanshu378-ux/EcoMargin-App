import 'package:flutter/material.dart';

class QuickActionsWidget extends StatelessWidget {
  final VoidCallback onScanQr;
  final VoidCallback onFavorites;
  final VoidCallback onHistory;
  final VoidCallback onWallet;

  const QuickActionsWidget({
    super.key,
    required this.onScanQr,
    required this.onFavorites,
    required this.onHistory,
    required this.onWallet,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final actions = [
      {
        'title': 'Scan QR',
        'icon': Icons.qr_code_scanner_rounded,
        'onTap': onScanQr,
      },
      {
        'title': 'Favorites',
        'icon': Icons.favorite_border_rounded,
        'onTap': onFavorites,
      },
      {
        'title': 'Charging\nHistory',
        'icon': Icons.history_rounded,
        'onTap': onHistory,
      },
      {
        'title': 'Wallet',
        'icon': Icons.account_balance_wallet_outlined,
        'onTap': onWallet,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: actions.map((item) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    onTap: item['onTap'] as VoidCallback,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      height: 95,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                        border: Border.all(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            item['icon'] as IconData,
                            color: const Color(0xFF16A34A),
                            size: 26,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item['title'] as String,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              height: 1.1,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
