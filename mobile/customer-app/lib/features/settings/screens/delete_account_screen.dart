import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/core_providers.dart';

class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  bool _understandWarning = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delete Account'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Are you sure you want to delete your EcoMargin account?',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'This action is irreversible. All your wallet balances, saved EV vehicles, charging history, and accumulated loyalty rewards will be permanently deleted.',
              style: TextStyle(color: Color(0xFF64748B), height: 1.5),
            ),
            const SizedBox(height: 24),
            CheckboxListTile(
              value: _understandWarning,
              title: const Text('I understand that my account and data will be permanently erased.', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              activeColor: Colors.red,
              onChanged: (val) => setState(() => _understandWarning = val!),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _understandWarning
                    ? () {
                        showDialog(
                          context: context,
                          builder: (dialogCtx) => AlertDialog(
                            title: const Text('Delete Account', style: TextStyle(fontWeight: FontWeight.bold)),
                            content: const Text(
                              'Are you sure you want to delete your EcoMargin account?\nThis action may permanently remove your account data.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dialogCtx),
                                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                              ),
                              TextButton(
                                onPressed: () async {
                                  Navigator.pop(dialogCtx);
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (context) => const Center(
                                      child: CircularProgressIndicator(color: Color(0xFF16A34A)),
                                    ),
                                  );
                                  try {
                                    final apiClient = ref.read(apiClientProvider);
                                    final storageService = ref.read(storageServiceProvider);
                                    final response = await apiClient.dio.delete('/profile');
                                    
                                    if (context.mounted) {
                                      Navigator.pop(context); // pop loading
                                    }
                                    
                                    if (response.statusCode == 200) {
                                      await storageService.clearAllTokens();
                                      ref.read(authStateProvider.notifier).state = false;
                                      if (context.mounted) {
                                        context.go('/login');
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Your account was successfully deleted.')),
                                        );
                                      }
                                    } else {
                                      throw Exception('Failed deletion');
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      Navigator.pop(context); // pop loading if still there
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Failed to delete account. Please try again.'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: const Text('Delete Account', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Permanently Delete My Account', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
