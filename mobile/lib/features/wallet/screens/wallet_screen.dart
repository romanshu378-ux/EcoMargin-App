import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/core_providers.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.invalidate(walletBalanceAsyncProvider);
        ref.invalidate(walletTransactionsProvider);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.invalidate(walletBalanceAsyncProvider);
          ref.invalidate(walletTransactionsProvider);
        }
      });
    }
  }

  void _showTransactionDetailsModal(BuildContext context, Map<String, dynamic> tx) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final type = (tx['type'] ?? '').toString().toUpperCase();
    final isCredit = type == 'CREDIT';
    final isRefund = type == 'REFUND';
    final amt = double.tryParse(tx['amount']?.toString() ?? '0') ?? 0.0;
    final amountText = isCredit || isRefund ? '+₹${amt.toStringAsFixed(2)}' : '-₹${amt.abs().toStringAsFixed(2)}';
    final status = (tx['status'] ?? 'SUCCESS').toString().toUpperCase();
    final refId = tx['referenceId']?.toString() ?? 'TXN-${tx['id']}';
    final dateStr = tx['createdAt'] != null ? tx['createdAt'].toString().replaceAll('T', ' ').split('.')[0] : 'N/A';
    final desc = tx['description'] ?? (isCredit ? 'Wallet Top-up' : 'EV Charging Session');
    final payMethod = tx['paymentMethod'] ?? (isCredit ? 'UPI / Card' : 'EcoMargin Wallet');
    final stationName = tx['stationName']?.toString();
    final sessionId = tx['sessionId']?.toString();
    final balBefore = double.tryParse(tx['balanceBefore']?.toString() ?? '');
    final balAfter = double.tryParse(tx['balanceAfter']?.toString() ?? '');

    Color statusColor;
    Color statusBg;
    IconData statusIcon;
    switch (status) {
      case 'SUCCESS':
      case 'COMPLETED':
        statusColor = const Color(0xFF16A34A);
        statusBg = const Color(0xFFDCFCE7);
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'PENDING':
      case 'INITIATED':
        statusColor = const Color(0xFFD97706);
        statusBg = const Color(0xFFFEF3C7);
        statusIcon = Icons.pending_actions_rounded;
        break;
      case 'FAILED':
      case 'CANCELLED':
        statusColor = Colors.red.shade700;
        statusBg = const Color(0xFFFEE2E2);
        statusIcon = Icons.error_rounded;
        break;
      default:
        statusColor = const Color(0xFF16A34A);
        statusBg = const Color(0xFFDCFCE7);
        statusIcon = Icons.info_rounded;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        desc,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text('Reference: $refId', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 14),
                      const SizedBox(width: 4),
                      Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            _buildModalRow('Amount Transacted', amountText, isDark, isHighlight: true, isCredit: isCredit || isRefund),
            _buildModalRow('Transaction Type', type, isDark),
            _buildModalRow('Date & Time', dateStr, isDark),
            _buildModalRow('Payment Method', payMethod, isDark),
            if (stationName != null) _buildModalRow('Charging Station', stationName, isDark),
            if (sessionId != null) _buildModalRow('Session ID', sessionId, isDark),
            if (balBefore != null) _buildModalRow('Balance Before', '₹${balBefore.toStringAsFixed(2)}', isDark),
            if (balAfter != null) _buildModalRow('Balance After', '₹${balAfter.toStringAsFixed(2)}', isDark),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Close Details', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModalRow(String label, String value, bool isDark, {bool isHighlight = false, bool isCredit = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: isHighlight ? 16 : 13,
                fontWeight: FontWeight.bold,
                color: isHighlight
                    ? (isCredit ? const Color(0xFF16A34A) : (isDark ? Colors.white : const Color(0xFF0F172A)))
                    : (isDark ? Colors.white : const Color(0xFF0F172A)),
              ),
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(BuildContext context, Map<String, dynamic> tx) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final type = (tx['type'] ?? '').toString().toUpperCase();
    final isCredit = type == 'CREDIT';
    final isRefund = type == 'REFUND';
    final title = tx['description'] ?? (isCredit ? 'Wallet Top Up' : 'EV Charging Session');
    final amt = double.tryParse(tx['amount']?.toString() ?? '0') ?? 0.0;
    final amountText = isCredit || isRefund ? '+₹${amt.toStringAsFixed(2)}' : '-₹${amt.abs().toStringAsFixed(2)}';
    final dateStr = tx['createdAt'] != null ? tx['createdAt'].toString().split('T')[0] : 'Today';
    final status = (tx['status'] ?? 'SUCCESS').toString().toUpperCase();

    return InkWell(
      onTap: () => _showTransactionDetailsModal(context, tx),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isCredit || isRefund ? const Color(0xFFDCFCE7) : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCredit ? Icons.add_circle_outline_rounded : (isRefund ? Icons.replay_rounded : Icons.ev_station_rounded),
                color: isCredit || isRefund ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(dateStr, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      if (status != 'SUCCESS' && status != 'COMPLETED') ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: status == 'PENDING' ? const Color(0xFFFEF3C7) : const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: status == 'PENDING' ? const Color(0xFFD97706) : Colors.red.shade700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Text(
                  amountText,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isCredit || isRefund ? const Color(0xFF16A34A) : (isDark ? Colors.white : const Color(0xFF0F172A)),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF94A3B8)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final balance = ref.watch(walletBalanceProvider);
    final walletAsync = ref.watch(walletBalanceAsyncProvider);
    final txsAsync = ref.watch(walletTransactionsProvider);

    final double displayBalance = walletAsync.maybeWhen(
      data: (bal) => bal,
      orElse: () => balance,
    );

    final bool isLowBalance = displayBalance >= 50.0 && displayBalance < 100.0;
    final bool isCriticallyLow = displayBalance < 50.0;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('EcoMargin Wallet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  ref.invalidate(walletBalanceAsyncProvider);
                  ref.invalidate(walletTransactionsProvider);
                }
              });
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF16A34A),
        onRefresh: () async {
          ref.invalidate(walletBalanceAsyncProvider);
          ref.invalidate(walletTransactionsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            // Balance Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF16A34A), Color(0xFF15803D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF16A34A).withOpacity(0.28),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Available Balance',
                        style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.shield_outlined, color: Colors.white, size: 12),
                            SizedBox(width: 4),
                            Text('Backend Secured', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '₹${displayBalance.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await context.push('/add-money');
                        ref.invalidate(walletBalanceAsyncProvider);
                        ref.invalidate(walletTransactionsProvider);
                      },
                      icon: const Icon(Icons.add_rounded, color: Color(0xFF16A34A)),
                      label: const Text('Top Up Balance', style: TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Non-blocking Low Balance Warning Banner (Requirements 9 & 10)
            if (isLowBalance) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2D2305) : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.5)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Your wallet balance is low (below ₹100). Minimum ₹50 required to start charging.',
                        style: TextStyle(fontSize: 12, color: Color(0xFFD97706), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (isCriticallyLow) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF321212) : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.red, size: 20),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Minimum ₹50 wallet balance required to start charging.',
                        style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/add-money'),
                      child: const Text('Add Money', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recent Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 20, color: Color(0xFF64748B)),
                  onPressed: () {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        ref.invalidate(walletTransactionsProvider);
                      }
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),

            txsAsync.when(
              loading: () => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      const CircularProgressIndicator(color: Color(0xFF16A34A)),
                      const SizedBox(height: 12),
                      Text('Loading transactions...', style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF64748B), fontSize: 12)),
                    ],
                  ),
                ),
              ),
              error: (err, st) => Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.red, size: 36),
                    const SizedBox(height: 8),
                    const Text('Unable to load transactions', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            ref.invalidate(walletTransactionsProvider);
                          }
                        });
                      },
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (txs) {
                if (txs.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(32),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 48, color: isDark ? Colors.white38 : Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text('No transactions yet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                        const SizedBox(height: 4),
                        const Text('Your wallet transactions will appear here.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B)), textAlign: TextAlign.center),
                      ],
                    ),
                  );
                }

                return Column(
                  children: txs.map((tx) {
                    return Column(
                      children: [
                        _buildTransactionTile(context, tx),
                        const Divider(height: 1),
                      ],
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
