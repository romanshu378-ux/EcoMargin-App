import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class StationDetailsScreen extends StatelessWidget {
  final String stationId;

  const StationDetailsScreen({
    super.key,
    required this.stationId,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Station Overview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Station link copied to clipboard')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Station Banner Image
            Image.network(
              'https://images.unsplash.com/photo-1558441719-6705166e2860?w=800&q=80',
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'GreenCharge Hub Sector 62',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'OPEN 24/7',
                          style: TextStyle(
                            color: Color(0xFF16A34A),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF64748B)),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Plot 42, Electronic City Phase 1, Bengaluru, Karnataka 560100',
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text(
                    'Available Connectors',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  // Connectors List
                  _buildConnectorTile(
                    context,
                    title: 'DC Fast Charger (CCS2)',
                    power: '60 kW Fast',
                    status: 'Available',
                    price: '₹18.00 / kWh',
                    isAvailable: true,
                  ),
                  const SizedBox(height: 10),
                  _buildConnectorTile(
                    context,
                    title: 'AC Dual Charger (Type 2)',
                    power: '22 kW Standard',
                    status: 'In Use',
                    price: '₹14.00 / kWh',
                    isAvailable: false,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Station Amenities',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _AmenityChip(icon: Icons.wifi, label: 'Free Wifi'),
                      _AmenityChip(icon: Icons.coffee, label: 'Cafeteria'),
                      _AmenityChip(icon: Icons.wc, label: 'Restroom'),
                      _AmenityChip(icon: Icons.local_parking, label: 'Parking'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Opening Google Maps Directions...')),
                  );
                },
                icon: const Icon(Icons.directions_outlined, color: Color(0xFF16A34A)),
                label: const Text('Directions', style: TextStyle(color: Color(0xFF16A34A))),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF16A34A)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => context.go('/start-charging'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Start Charging', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectorTile(
    BuildContext context, {
    required String title,
    required String power,
    required String status,
    required String price,
    required bool isAvailable,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E293B)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isAvailable ? const Color(0xFF16A34A).withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.flash_on,
                  color: isAvailable ? const Color(0xFF16A34A) : Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text('$power • $price', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                ],
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () => context.go('/charger-details'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isAvailable ? const Color(0xFF16A34A) : Colors.grey,
              minimumSize: const Size(70, 36),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(isAvailable ? 'Select' : 'Occupied', style: const TextStyle(fontSize: 12, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _AmenityChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _AmenityChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: const Color(0xFF16A34A).withOpacity(0.1),
          child: Icon(icon, color: const Color(0xFF16A34A), size: 20),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
      ],
    );
  }
}
