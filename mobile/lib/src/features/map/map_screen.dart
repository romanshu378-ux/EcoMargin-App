import 'package:flutter/material.dart';
import '../charging/charger_details_screen.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Mock Map Background Representation
          Container(
            color: Theme.of(context).brightness == Brightness.dark 
                ? const Color(0xFF0D121F) 
                : Colors.grey[100],
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map_rounded, size: 96, color: const Color(0xFF10B981).withOpacity(0.2)),
                  const SizedBox(height: 8),
                  const Text('Map View Sandbox', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
          ),

          // Custom Marker Pins
          Positioned(
            left: 120,
            top: 250,
            child: GestureDetector(
              onTap: () => _showDetailsSheet(context, 'Austin Downtown Hub', '120 E 6th St'),
              child: const Column(
                children: [
                  Icon(Icons.location_on_rounded, size: 36, color: Color(0xFF10B981)),
                  Text('Downtown Hub', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          
          Positioned(
            right: 120,
            bottom: 300,
            child: GestureDetector(
              onTap: () => _showDetailsSheet(context, 'North Loop Charger Point', '5310 Airport Blvd'),
              child: const Column(
                children: [
                  Icon(Icons.location_on_rounded, size: 36, color: Color(0xFF10B981)),
                  Text('North Loop Pt', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),

          // Top Header Search Overlay
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                height: 54,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(27),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search_rounded, color: Colors.grey),
                    SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search nearby stations...',
                          border: InputBorder.none,
                          hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ),
                    ),
                    Icon(Icons.tune_rounded, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: const Color(0xFF10B981),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.explore_rounded), label: 'Explore'),
          BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner_rounded), label: 'Scan & Charge'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_rounded), label: 'Wallet'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: 'Profile'),
        ],
        onTap: (index) {
          if (index == 1) {
            _showQrScanMock(context);
          } else if (index == 2) {
            Navigator.pushNamed(context, '/wallet');
          } else if (index == 3) {
            Navigator.pushNamed(context, '/history');
          }
        },
      ),
    );
  }

  void _showDetailsSheet(BuildContext context, String title, String address) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return ChargerDetailsScreen(stationName: title, address: address);
      },
    );
  }

  void _showQrScanMock(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('QR Scanner Mock'),
        content: const Text('Scan QR code found on the connector to initiate session.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showDetailsSheet(context, 'Austin Downtown Hub', '120 E 6th St');
            },
            child: const Text('Simulate Scan'),
          ),
        ],
      ),
    );
  }
}
