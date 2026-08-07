import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/home_providers.dart';

class SearchSectionWidget extends ConsumerWidget {
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onFilterPressed;

  const SearchSectionWidget({
    super.key,
    this.onSearchChanged,
    this.onFilterPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = ref.watch(currentLocationProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Location bar
          Row(
            children: [
              const Icon(
                Icons.location_on_rounded,
                color: Color(0xFF16A34A),
                size: 18,
              ),
              const SizedBox(width: 4),
              Text(
                'Current Location:',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.slate300 : const Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                location,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF16A34A)),
            ],
          ),
          const SizedBox(height: 10),

          // Search Bar & Filter Button
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    onChanged: onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search charging stations or area...',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.slate400 : const Color(0xFF94A3B8),
                      ),
                      prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF16A34A), size: 22),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Filter Icon Button
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF16A34A).withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: onFilterPressed,
                  icon: const Icon(Icons.tune_rounded, color: Colors.white, size: 22),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
