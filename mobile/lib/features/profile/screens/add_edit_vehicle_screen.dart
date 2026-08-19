import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/core_providers.dart';

class AddEditVehicleScreen extends ConsumerStatefulWidget {
  final EvVehicle? vehicle;

  const AddEditVehicleScreen({super.key, this.vehicle});

  @override
  ConsumerState<AddEditVehicleScreen> createState() => _AddEditVehicleScreenState();
}

class _AddEditVehicleScreenState extends ConsumerState<AddEditVehicleScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _brandController;
  late TextEditingController _modelController;
  late TextEditingController _variantController;
  late TextEditingController _regController;
  late TextEditingController _kwhController;
  late TextEditingController _nicknameController;

  String? _selectedType;
  String? _selectedConnector;
  bool _isSaving = false;

  final List<String> _connectorOptions = [
    'CCS2 (DC Fast)',
    'Type 2 (AC)',
    'GB/T (DC)',
    'CHAdeMO',
  ];

  final List<String> _typeOptions = [
    'Car',
    'Two-wheeler',
    'Three-wheeler',
    'Heavy Vehicle',
  ];

  @override
  void initState() {
    super.initState();
    final v = widget.vehicle;
    _brandController = TextEditingController(text: v?.brand ?? '');
    _modelController = TextEditingController(text: v?.model ?? '');
    _variantController = TextEditingController(text: v?.variant ?? '');
    _regController = TextEditingController(text: v?.registrationNumber ?? '');
    _kwhController = TextEditingController(text: v != null ? v.batteryCapacityKwh.toString() : '');
    _nicknameController = TextEditingController(text: v?.nickname ?? '');
    _selectedType = v?.type;
    _selectedConnector = v?.connectorType;

    // Set defaults if new vehicle
    if (v == null) {
      _selectedConnector = _connectorOptions[0];
      _selectedType = _typeOptions[0];
    }
  }

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _variantController.dispose();
    _regController.dispose();
    _kwhController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _saveVehicle() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final capacity = double.tryParse(_kwhController.text.trim()) ?? 0.0;
      final vehicleData = EvVehicle(
        id: widget.vehicle?.id ?? '',
        brand: _brandController.text.trim(),
        model: _modelController.text.trim(),
        variant: _variantController.text.trim().isEmpty ? null : _variantController.text.trim(),
        type: _selectedType,
        registrationNumber: _regController.text.trim().toUpperCase(),
        batteryCapacityKwh: capacity,
        connectorType: _selectedConnector ?? 'CCS2',
        nickname: _nicknameController.text.trim().isEmpty ? null : _nicknameController.text.trim(),
        isDefault: widget.vehicle?.isDefault ?? false,
      );

      if (widget.vehicle == null) {
        await ref.read(vehicleProvider.notifier).addVehicle(vehicleData);
      } else {
        await ref.read(vehicleProvider.notifier).updateVehicle(vehicleData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.vehicle == null ? 'Vehicle added successfully.' : 'Vehicle updated successfully.')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save vehicle: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.vehicle != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit EV Vehicle' : 'Add EV Vehicle'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            // Registration Number
            TextFormField(
              controller: _regController,
              enabled: !_isSaving,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: 'Vehicle Registration Number',
                hintText: 'e.g. MH 12 AB 1234',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Registration number is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Brand
            TextFormField(
              controller: _brandController,
              enabled: !_isSaving,
              decoration: InputDecoration(
                labelText: 'Vehicle Brand',
                hintText: 'e.g. Tata Motors, MG Motor',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Brand is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Model
            TextFormField(
              controller: _modelController,
              enabled: !_isSaving,
              decoration: InputDecoration(
                labelText: 'Model Name',
                hintText: 'e.g. Nexon EV, ZS EV',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Model is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Variant
            TextFormField(
              controller: _variantController,
              enabled: !_isSaving,
              decoration: InputDecoration(
                labelText: 'Vehicle Variant (Optional)',
                hintText: 'e.g. Max, Prime, Excite',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),

            // Vehicle Type dropdown
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: InputDecoration(
                labelText: 'Vehicle Type',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: _typeOptions
                  .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                  .toList(),
              onChanged: _isSaving ? null : (val) => setState(() => _selectedType = val),
            ),
            const SizedBox(height: 16),

            // Battery Capacity
            TextFormField(
              controller: _kwhController,
              enabled: !_isSaving,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Battery Capacity (kWh)',
                hintText: 'e.g. 40.5',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Battery capacity is required';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid decimal number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Connector Type
            DropdownButtonFormField<String>(
              value: _selectedConnector,
              decoration: InputDecoration(
                labelText: 'Connector Type',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: _connectorOptions
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: _isSaving ? null : (val) => setState(() => _selectedConnector = val),
            ),
            const SizedBox(height: 16),

            // Nickname
            TextFormField(
              controller: _nicknameController,
              enabled: !_isSaving,
              decoration: InputDecoration(
                labelText: 'Vehicle Nickname (Optional)',
                hintText: 'e.g. My Nexon, Blue Cruiser',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 32),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveVehicle,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  disabledBackgroundColor: const Color(0xFF16A34A).withOpacity(0.6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(isEdit ? 'Save Changes' : 'Save Vehicle', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
