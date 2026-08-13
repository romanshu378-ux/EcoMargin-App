import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/home_providers.dart';

class AppHeader extends ConsumerWidget {
  final VoidCallback onMenuPressed;
  final VoidCallback onNotificationPressed;

  const AppHeader({
    super.key,
    required this.onMenuPressed,
    required this.onNotificationPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Hamburger Menu Icon
          IconButton(
            onPressed: onMenuPressed,
            icon: const Icon(
              Icons.menu_rounded,
              color: Color(0xFF1E293B),
              size: 26,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),

          // Center: Logo & Tagline
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // EcoMargin Icon
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFF16A34A),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.bolt_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Eco',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF16A34A),
                            letterSpacing: -0.5,
                          ),
                        ),
                        TextSpan(
                          text: 'Margin',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Text(
                    'Powering a Greener Future',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Right: Notification Bell Icon with Green Dot Badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: onNotificationPressed,
                icon: const Icon(
                  Icons.notifications_none_outlined,
                  color: Color(0xFF1E293B),
                  size: 26,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              if (unreadCount > 0)
                Positioned(
                  top: 2,
                  right: 2,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: const Color(0xFF16A34A),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
