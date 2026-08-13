import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/core_providers.dart';

class VehicleManagementScreen extends ConsumerWidget {
  const VehicleManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicles = ref.watch(vehicleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Vehicles'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(vehicleProvider);
        },
        child: vehicles.isEmpty
            ? Center(
                child: ListView(
                  shrinkWrap: true,
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    Center(
                      child: Icon(Icons.electric_car_outlined, size: 80, color: Colors.grey),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No vehicles added yet',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Tap the button below to add your electric vehicle.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: vehicles.length,
                itemBuilder: (context, index) {
                  final item = vehicles[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        backgroundColor: item.isDefault
                            ? const Color(0xFF16A34A)
                            : const Color(0xFF16A34A).withOpacity(0.1),
                        child: Icon(
                          Icons.electric_car,
                          color: item.isDefault ? Colors.white : const Color(0xFF16A34A),
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${item.brand} ${item.model}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (item.isDefault) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF16A34A).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'PRIMARY',
                                style: TextStyle(fontSize: 10, color: Color(0xFF16A34A), fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            item.registrationNumber,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${item.batteryCapacityKwh} kWh • ${item.connectorType}${item.variant != null && item.variant!.isNotEmpty ? ' • ${item.variant}' : ''}',
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          if (item.nickname != null && item.nickname!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              '"${item.nickname}"',
                              style: const TextStyle(color: Color(0xFF16A34A), fontStyle: FontStyle.italic, fontSize: 12),
                            ),
                          ],
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                            onPressed: () {
                              context.push('/add-edit-vehicle', extra: item);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete Vehicle'),
                                  content: Text('Are you sure you want to delete ${item.brand} ${item.model}?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(ctx).pop(false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.of(ctx).pop(true),
                                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                try {
                                  await ref.read(vehicleProvider.notifier).removeVehicle(item.id);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Vehicle deleted successfully.')),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Failed to delete vehicle: $e'), backgroundColor: Colors.red),
                                    );
                                  }
                                }
                              }
                            },
                          ),
                        ],
                      ),
                      onTap: () async {
                        if (!item.isDefault) {
                          try {
                            await ref.read(vehicleProvider.notifier).setDefault(item.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('${item.brand} set as primary vehicle.')),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to update primary vehicle: $e'), backgroundColor: Colors.red),
                              );
                            }
                          }
                        }
                      },
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-edit-vehicle'),
        backgroundColor: const Color(0xFF16A34A),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add EV Vehicle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
