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
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: vehicles.length,
        itemBuilder: (context, index) {
          final item = vehicles[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF16A34A),
                child: Icon(Icons.electric_car, color: Colors.white),
              ),
              title: Row(
                children: [
                  Text('${item.brand} ${item.model}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (item.isDefault) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('DEFAULT', style: TextStyle(fontSize: 10, color: Color(0xFF16A34A), fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
              subtitle: Text('${item.registrationNumber}\n${item.batteryCapacityKwh} kWh • ${item.connectorType}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () {
                  ref.read(vehicleProvider.notifier).removeVehicle(item.id);
                },
              ),
              onTap: () {
                ref.read(vehicleProvider.notifier).setDefault(item.id);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/add-edit-vehicle'),
        backgroundColor: const Color(0xFF16A34A),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add EV Vehicle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
