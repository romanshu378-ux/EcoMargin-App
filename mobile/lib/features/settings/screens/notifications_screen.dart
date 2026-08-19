import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/core_providers.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> with WidgetsBindingObserver {
  bool _isMarkingAll = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.invalidate(notificationsProvider);
        ref.invalidate(unreadNotificationCountAsyncProvider);
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
          ref.invalidate(notificationsProvider);
          ref.invalidate(unreadNotificationCountAsyncProvider);
        }
      });
    }
  }

  String _formatNotificationTime(String? rawIso) {
    if (rawIso == null || rawIso.isEmpty) return '';
    try {
      final dt = DateTime.parse(rawIso).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
      if (diff.inHours < 24 && dt.day == now.day) {
        return DateFormat('hh:mm a').format(dt);
      }
      if (now.day - dt.day == 1 && now.month == dt.month && now.year == dt.year) {
        return 'Yesterday • ${DateFormat('hh:mm a').format(dt)}';
      }
      return DateFormat('dd MMM • hh:mm a').format(dt);
    } catch (_) {
      return rawIso.replaceAll('T', ' ').split('.')[0];
    }
  }

  IconData _getNotificationIcon(String type, String title) {
    final t = type.toUpperCase();
    final lowerTitle = title.toLowerCase();
    if (t.contains('CHARGING') || lowerTitle.contains('charging')) {
      return Icons.bolt_rounded;
    } else if (t.contains('TRANSACTION') || t.contains('WALLET') || lowerTitle.contains('wallet') || lowerTitle.contains('payment')) {
      return Icons.account_balance_wallet_rounded;
    } else if (t.contains('FAULT') || lowerTitle.contains('fault') || lowerTitle.contains('error') || lowerTitle.contains('low')) {
      return Icons.warning_amber_rounded;
    }
    return Icons.notifications_active_rounded;
  }

  Color _getNotificationIconColor(String type, String title) {
    final t = type.toUpperCase();
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('fault') || lowerTitle.contains('error')) {
      return Colors.red;
    } else if (lowerTitle.contains('low')) {
      return Colors.amber.shade800;
    } else if (t.contains('TRANSACTION') || lowerTitle.contains('wallet')) {
      return const Color(0xFF16A34A);
    }
    return const Color(0xFF16A34A);
  }

  Future<void> _markSingleAsRead(Map<String, dynamic> item) async {
    final id = item['id'];
    final isRead = item['isRead'] == true || item['read'] == true;
    if (id == null) return;

    if (!isRead) {
      try {
        final apiClient = ref.read(apiClientProvider);
        await apiClient.dio.post('/notifications/$id/read');
        ref.invalidate(notificationsProvider);
        ref.invalidate(unreadNotificationCountAsyncProvider);
      } catch (_) {}
    }

    final title = (item['title'] ?? '').toString();
    final type = (item['type'] ?? '').toString();

    // If it's a live/active charging notification, open live charging screen
    if (type.toUpperCase().contains('CHARGING') || title.toLowerCase().contains('charging')) {
      final activeSession = ref.read(chargingSessionProvider);
      if (activeSession.isCharging && mounted) {
        context.push('/live-charging');
      }
    }
  }

  Future<void> _markAllAsRead() async {
    if (_isMarkingAll) return;
    setState(() => _isMarkingAll = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.dio.post('/notifications/read-all');
      ref.read(unreadNotificationCountProvider.notifier).state = 0;
      ref.invalidate(notificationsProvider);
      ref.invalidate(unreadNotificationCountAsyncProvider);
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _isMarkingAll = false);
      }
    }
  }

  Widget _buildSkeletonLoading(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (context, index) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 80,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton.icon(
            onPressed: _isMarkingAll ? null : _markAllAsRead,
            icon: _isMarkingAll
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF16A34A)),
                  )
                : const Icon(Icons.done_all_rounded, size: 18, color: Color(0xFF16A34A)),
            label: const Text(
              'Mark all as read',
              style: TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF16A34A),
        onRefresh: () async {
          ref.invalidate(notificationsProvider);
          ref.invalidate(unreadNotificationCountAsyncProvider);
        },
        child: notificationsAsync.when(
          loading: () => _buildSkeletonLoading(isDark),
          error: (err, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off_rounded, color: Colors.red, size: 48),
                  const SizedBox(height: 12),
                  const Text(
                    'Unable to load notifications',
                    style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Please check your network connection and try again.',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      ref.invalidate(notificationsProvider);
                      ref.invalidate(unreadNotificationCountAsyncProvider);
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          data: (notifications) {
            if (notifications.isEmpty) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
                  width: double.infinity,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A).withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.notifications_none_rounded, size: 64, color: Color(0xFF16A34A)),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'No notifications yet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Updates about your charging sessions, wallet transactions, and alerts will appear here.',
                        style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final item = notifications[index];
                final title = item['title']?.toString() ?? 'Notification';
                final message = item['message']?.toString() ?? '';
                final type = item['type']?.toString() ?? 'SYSTEM';
                final isRead = item['isRead'] == true || item['read'] == true;
                final timeStr = _formatNotificationTime(item['createdAt']?.toString());

                final iconData = _getNotificationIcon(type, title);
                final iconColor = _getNotificationIconColor(type, title);

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: isRead
                        ? (isDark ? const Color(0xFF1E293B) : Colors.white)
                        : (isDark ? const Color(0xFF0F291E) : const Color(0xFFF0FDF4)),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isRead
                          ? (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))
                          : (isDark ? const Color(0xFF166534) : const Color(0xFF86EFAC)),
                      width: isRead ? 1.0 : 1.5,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      onTap: () => _markSingleAsRead(item),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Icon Badge
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: iconColor.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(iconData, color: iconColor, size: 22),
                            ),
                            const SizedBox(width: 14),

                            // Text Content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          title,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (!isRead) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF16A34A),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    message,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                                      height: 1.35,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    timeStr,
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
