import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';

class RfidCardScreen extends ConsumerStatefulWidget {
  const RfidCardScreen({super.key});

  @override
  ConsumerState<RfidCardScreen> createState() => _RfidCardScreenState();
}

class _RfidCardScreenState extends ConsumerState<RfidCardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _cardUidController = TextEditingController();
  final _linkedVehicleController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardUidController.dispose();
    _linkedVehicleController.dispose();
    super.dispose();
  }

  String _maskCardNumber(String number) {
    if (number.length < 8) return number;
    return '${number.substring(0, 4)}-XXXX-XXXX-${number.substring(number.length - 4)}';
  }

  String _maskUid(String uid) {
    if (uid.length < 6) return uid;
    return '${uid.substring(0, 5)}:XX:XX';
  }

  void _showLinkDialog() {
    _cardNumberController.clear();
    _cardUidController.clear();
    _linkedVehicleController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Link RFID Card', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Enter the card number and UID printed on your EcoMargin RFID card.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _cardNumberController,
                  decoration: InputDecoration(
                    labelText: 'Card Number',
                    hintText: 'e.g. 1234-5678-9012-3456',
                    prefixIcon: const Icon(Icons.credit_card),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Card Number is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _cardUidController,
                  decoration: InputDecoration(
                    labelText: 'Card UID',
                    hintText: 'e.g. AA:BB:CC:DD',
                    prefixIcon: const Icon(Icons.nfc),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Card UID is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _linkedVehicleController,
                  decoration: InputDecoration(
                    labelText: 'Linked Vehicle (Optional)',
                    hintText: 'e.g. Tesla Model Y',
                    prefixIcon: const Icon(Icons.directions_car),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                Navigator.pop(context);
                setState(() => _isLoading = true);
                try {
                  await ref.read(rfidProvider.notifier).linkRfidCard(
                        _cardNumberController.text.trim(),
                        _cardUidController.text.trim(),
                        linkedVehicle: _linkedVehicleController.text.trim(),
                      );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('RFID card linked successfully.')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    String msg = 'Failed to link card.';
                    if (e.toString().contains('409')) {
                      msg = 'Conflict: Card number or UID is already registered to another account.';
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(msg), backgroundColor: Colors.red),
                    );
                  }
                } finally {
                  if (mounted) setState(() => _isLoading = false);
                }
              }
            },
            child: const Text('Link Card', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmAction(String title, String content, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: const Text('Confirm', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rfidState = ref.watch(rfidProvider);
    final userProfileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('RFID Card'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF16A34A)))
          : rfidState.when(
              loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF16A34A))),
              error: (err, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 60, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text(
                        'Failed to load RFID card details.',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        err.toString().contains('503')
                            ? 'Database service is temporarily unavailable. Please try again.'
                            : 'An unexpected connection error occurred.',
                        style: const TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => ref.read(rfidProvider.notifier).fetchRfidCard(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry', style: TextStyle(color: Colors.white)),
                      )
                    ],
                  ),
                ),
              ),
              data: (card) {
                if (card == null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.nfc_rounded, size: 100, color: Colors.grey.withValues(alpha: 0.3)),
                          const SizedBox(height: 24),
                          const Text(
                            'No RFID Card Linked',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Link your EcoMargin RFID card to quickly start and stop charging sessions at any charger with a single tap.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, height: 1.5),
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF16A34A),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              onPressed: _showLinkDialog,
                              icon: const Icon(Icons.link_rounded, color: Colors.white),
                              label: const Text(
                                'Link RFID Card',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                Color statusColor;
                switch (card.status.toUpperCase()) {
                  case 'ACTIVE':
                    statusColor = const Color(0xFF16A34A);
                    break;
                  case 'BLOCKED':
                    statusColor = Colors.red;
                    break;
                  default:
                    statusColor = Colors.orange;
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Premium Card UI
                      Container(
                        width: double.infinity,
                        height: 210,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF15803D), Color(0xFF16A34A), Color(0xFF22C55E)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF16A34A).withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'EcoMargin RFID',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    card.status,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Text(
                              _maskCardNumber(card.cardNumber),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('CARD UID', style: TextStyle(color: Colors.white70, fontSize: 10)),
                                    const SizedBox(height: 4),
                                    Text(
                                      _maskUid(card.cardUid),
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ],
                                ),
                                if (card.linkedVehicle.isNotEmpty)
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text('VEHICLE', style: TextStyle(color: Colors.white70, fontSize: 10)),
                                      const SizedBox(height: 4),
                                      Text(
                                        card.linkedVehicle,
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Card Information',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      // Details List
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFF8FAFC),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              _buildDetailRow('Card Status', card.status, statusColor, isStatus: true),
                              const Divider(height: 24),
                              _buildDetailRow('RFID Card Number', card.cardNumber, null),
                              const Divider(height: 24),
                              _buildDetailRow('Card UID', card.cardUid, null),
                              const Divider(height: 24),
                              _buildDetailRow('Linked Vehicle', card.linkedVehicle.isEmpty ? 'None' : card.linkedVehicle, null),
                              const Divider(height: 24),
                              _buildDetailRow(
                                'Linked Account',
                                userProfileAsync.maybeWhen(
                                  data: (profile) => profile.email,
                                  orElse: () => '',
                                ),
                                null,
                              ),
                              const Divider(height: 24),
                              _buildDetailRow('Issued Date', card.issuedDate, null),
                              const Divider(height: 24),
                              _buildDetailRow('Last Used', card.lastUsed.isEmpty ? 'Never' : card.lastUsed, null),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Actions Panel
                      const Text(
                        'Actions',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      if (card.status.toUpperCase() == 'ACTIVE') ...[
                        _buildActionButton(
                          icon: Icons.block_rounded,
                          label: 'Block Card',
                          color: Colors.red,
                          onTap: () => _confirmAction(
                            'Block RFID Card',
                            'Are you sure you want to block this card? You will not be able to use it for charging sessions until it is unblocked.',
                            () async {
                              setState(() => _isLoading = true);
                              try {
                                await ref.read(rfidProvider.notifier).blockRfidCard();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('RFID card blocked successfully.')),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Failed to block card.'), backgroundColor: Colors.red),
                                  );
                                }
                              } finally {
                                if (mounted) setState(() => _isLoading = false);
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildActionButton(
                          icon: Icons.report_problem_rounded,
                          label: 'Report Lost Card',
                          color: Colors.orange,
                          onTap: () => _confirmAction(
                            'Report Lost RFID Card',
                            'Report this card as lost? The card will be permanently blocked for safety.',
                            () async {
                              setState(() => _isLoading = true);
                              try {
                                await ref.read(rfidProvider.notifier).blockRfidCard();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Card reported lost and blocked.')),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Failed to block card.'), backgroundColor: Colors.red),
                                  );
                                }
                              } finally {
                                if (mounted) setState(() => _isLoading = false);
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      _buildActionButton(
                        icon: Icons.link_off_rounded,
                        label: 'Unlink RFID Card',
                        color: Colors.grey,
                        onTap: () => _confirmAction(
                          'Unlink RFID Card',
                          'Are you sure you want to unlink this card from your account? This will remove all vehicle associations.',
                          () async {
                            setState(() => _isLoading = true);
                            try {
                              await ref.read(rfidProvider.notifier).unlinkRfidCard();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('RFID card unlinked successfully.')),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Failed to unlink card.'), backgroundColor: Colors.red),
                                );
                              }
                            } finally {
                              if (mounted) setState(() => _isLoading = false);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color? valueColor, {bool isStatus = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        isStatus
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: valueColor?.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  value,
                  style: TextStyle(color: valueColor, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              )
            : Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color.withValues(alpha: 0.4), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: onTap,
        icon: Icon(icon, color: color),
        label: Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
    );
  }
}
