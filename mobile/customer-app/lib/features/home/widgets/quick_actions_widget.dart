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
        'color': const Color(0xFF16A34A),
        'onTap': onScanQr,
      },
      {
        'title': 'Favorites',
        'icon': Icons.favorite_rounded,
        'color': const Color(0xFFEC4899),
        'onTap': onFavorites,
      },
      {
        'title': 'History',
        'icon': Icons.history_rounded,
        'color': const Color(0xFF3B82F6),
        'onTap': onHistory,
      },
      {
        'title': 'Wallet',
        'icon': Icons.account_balance_wallet_rounded,
        'color': const Color(0xFF8B5CF6),
        'onTap': onWallet,
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: actions.map((item) {
              final color = item['color'] as Color;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    onTap: item['onTap'] as VoidCallback,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: isDark ? Colors.transparent : const Color(0xFFF1F5F9),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              item['icon'] as IconData,
                              color: color,
                              size: 22,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item['title'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : const Color(0xFF334155),
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
        ],
      ),
    );
  }
}
