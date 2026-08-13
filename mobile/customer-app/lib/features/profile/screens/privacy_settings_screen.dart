import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/core_providers.dart';

class PrivacySettingsScreen extends ConsumerStatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  ConsumerState<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends ConsumerState<PrivacySettingsScreen> {
  bool _isUpdating = false;

  Future<void> _toggleSetting(PrivacySettings current, String key, bool value) async {
    setState(() => _isUpdating = true);
    try {
      PrivacySettings updated;
      switch (key) {
        case 'locationPermission':
          updated = current.copyWith(locationPermission: value);
          break;
        case 'locationSharing':
          updated = current.copyWith(locationSharing: value);
          break;
        case 'nearbyChargerPersonalization':
          updated = current.copyWith(nearbyChargerPersonalization: value);
          break;
        case 'pushNotifications':
          updated = current.copyWith(pushNotifications: value);
          break;
        case 'chargingActivityVisibility':
          updated = current.copyWith(chargingActivityVisibility: value);
          break;
        case 'usageAnalytics':
          updated = current.copyWith(usageAnalytics: value);
          break;
        case 'personalizedRecommendations':
          updated = current.copyWith(personalizedRecommendations: value);
          break;
        default:
          updated = current;
      }
      await ref.read(privacyProvider.notifier).updatePrivacySettings(updated);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update privacy settings. Using cached mode.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final privacyState = ref.watch(privacyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: privacyState.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF16A34A))),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.privacy_tip_outlined, size: 60, color: Colors.orange),
                const SizedBox(height: 16),
                const Text(
                  'Unable to sync settings with server.',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please check your network and try again. You can retry syncing with the server below.',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => ref.read(privacyProvider.notifier).loadCachedOrFetch(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry Connection', style: TextStyle(color: Colors.white)),
                )
              ],
            ),
          ),
        ),
        data: (settings) {
          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.all(24.0),
                children: [
                  const Text(
                    'Permissions & Sharing',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF8FAFC),
                    child: Column(
                      children: [
                        SwitchListTile(
                          activeColor: const Color(0xFF16A34A),
                          title: const Text('Location Permission', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: const Text('Allow EcoMargin to access your GPS location to search for nearest chargers.', style: TextStyle(fontSize: 12)),
                          value: settings.locationPermission,
                          onChanged: (val) => _toggleSetting(settings, 'locationPermission', val),
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          activeColor: const Color(0xFF16A34A),
                          title: const Text('Location Sharing', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: const Text('Share real-time navigation location with station operators.', style: TextStyle(fontSize: 12)),
                          value: settings.locationSharing,
                          onChanged: (val) => _toggleSetting(settings, 'locationSharing', val),
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          activeColor: const Color(0xFF16A34A),
                          title: const Text('Nearby Charger Personalization', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: const Text('Recommend stations based on historical charging behaviors.', style: TextStyle(fontSize: 12)),
                          value: settings.nearbyChargerPersonalization,
                          onChanged: (val) => _toggleSetting(settings, 'nearbyChargerPersonalization', val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Notifications & Activity',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF8FAFC),
                    child: Column(
                      children: [
                        SwitchListTile(
                          activeColor: const Color(0xFF16A34A),
                          title: const Text('Push Notifications', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: const Text('Get alerts for charging completion, payments, and rewards.', style: TextStyle(fontSize: 12)),
                          value: settings.pushNotifications,
                          onChanged: (val) => _toggleSetting(settings, 'pushNotifications', val),
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          activeColor: const Color(0xFF16A34A),
                          title: const Text('Charging Activity Visibility', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: const Text('Make your live charging status visible to other station users.', style: TextStyle(fontSize: 12)),
                          value: settings.chargingActivityVisibility,
                          onChanged: (val) => _toggleSetting(settings, 'chargingActivityVisibility', val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Analytics & Recommendations',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF8FAFC),
                    child: Column(
                      children: [
                        SwitchListTile(
                          activeColor: const Color(0xFF16A34A),
                          title: const Text('Usage Analytics', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: const Text('Allow anonymized app usage tracking to help us improve performance.', style: TextStyle(fontSize: 12)),
                          value: settings.usageAnalytics,
                          onChanged: (val) => _toggleSetting(settings, 'usageAnalytics', val),
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          activeColor: const Color(0xFF16A34A),
                          title: const Text('Personalized Recommendations', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: const Text('Receive promotional offers tailored to your vehicle type.', style: TextStyle(fontSize: 12)),
                          value: settings.personalizedRecommendations,
                          onChanged: (val) => _toggleSetting(settings, 'personalizedRecommendations', val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Legal & Agreements',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF8FAFC),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.privacy_tip_outlined, color: Colors.grey),
                          title: const Text('Privacy Policy', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                          trailing: const Icon(Icons.chevron_right, size: 20),
                          onTap: () => context.push('/privacy-policy'),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.description_outlined, color: Colors.grey),
                          title: const Text('Terms & Conditions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                          trailing: const Icon(Icons.chevron_right, size: 20),
                          onTap: () => context.push('/terms-conditions'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Data & Account Management',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF8FAFC),
                    child: ListTile(
                      leading: const Icon(Icons.delete_forever, color: Colors.red),
                      title: const Text('Delete Account', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: const Text('Request permanent removal of your account.', style: TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.red),
                      onTap: () => context.push('/delete-account'),
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
              if (_isUpdating)
                Container(
                  color: Colors.black.withValues(alpha: 0.15),
                  child: const Center(
                    child: CircularProgressIndicator(color: Color(0xFF16A34A)),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
