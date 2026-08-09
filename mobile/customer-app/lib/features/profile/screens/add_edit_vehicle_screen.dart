import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/core_providers.dart';

class AddEditVehicleScreen extends ConsumerStatefulWidget {
  const AddEditVehicleScreen({super.key});

  @override
  ConsumerState<AddEditVehicleScreen> createState() => _AddEditVehicleScreenState();
}

class _AddEditVehicleScreenState extends ConsumerState<AddEditVehicleScreen> {
  final _brandController = TextEditingController(text: 'Tata Motors');
  final _modelController = TextEditingController(text: 'Nexon EV');
  final _regController = TextEditingController();
  final _kwhController = TextEditingController(text: '40.5');
  String _connector = 'CCS2 (DC Fast)';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add EV Vehicle'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _brandController,
              decoration: InputDecoration(
                labelText: 'Vehicle Brand',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _modelController,
              decoration: InputDecoration(
                labelText: 'Model Name',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _regController,
              decoration: InputDecoration(
                labelText: 'Registration Number (e.g. MH 12 AB 1234)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _kwhController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Battery Capacity (kWh)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _connector,
              decoration: InputDecoration(
                labelText: 'Connector Type',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: ['CCS2 (DC Fast)', 'Type 2 (AC)', 'GB/T (DC)', 'CHAdeMO']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) => setState(() => _connector = val!),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  final newVehicle = EvVehicle(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    brand: _brandController.text,
                    model: _modelController.text,
                    registrationNumber: _regController.text.isEmpty ? 'MH 01 EV 8888' : _regController.text,
                    batteryCapacityKwh: double.tryParse(_kwhController.text) ?? 40.0,
                    connectorType: _connector,
                    isDefault: false,
                  );
                  ref.read(vehicleProvider.notifier).addVehicle(newVehicle);
                  context.pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Save Vehicle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
