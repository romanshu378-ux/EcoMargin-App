import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SearchStationScreen extends StatefulWidget {
  const SearchStationScreen({super.key});

  @override
  State<SearchStationScreen> createState() => _SearchStationScreenState();
}

class _SearchStationScreenState extends State<SearchStationScreen> {
  final _searchController = TextEditingController();
  String _filterConnector = 'All';

  final List<Map<String, dynamic>> _stations = [
    {
      'name': 'GreenCharge Hub Sector 62',
      'address': 'Electronic City, Bengaluru',
      'distance': '0.8 km',
      'power': '60 kW DC',
      'available': '4/6 Available',
      'price': '₹18.00/kWh',
    },
    {
      'name': 'EcoFast Station Whitefield',
      'address': 'ITPL Main Rd, Bengaluru',
      'distance': '2.4 km',
      'power': '120 kW DC',
      'available': '2/4 Available',
      'price': '₹20.00/kWh',
    },
    {
      'name': 'PowerGrid Hub Indiranagar',
      'address': '100 Feet Rd, Bengaluru',
      'distance': '4.1 km',
      'power': '22 kW AC',
      'available': '1/2 Available',
      'price': '₹14.00/kWh',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search by location, station name...',
            border: InputBorder.none,
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: ['All', 'DC Fast (>60kW)', 'AC Type 2', 'Available Now'].map((filter) {
                final isSelected = _filterConnector == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (val) => setState(() => _filterConnector = filter),
                    selectedColor: const Color(0xFF16A34A).withOpacity(0.2),
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _stations.length,
              itemBuilder: (context, index) {
                final station = _stations[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFF16A34A),
                      child: Icon(Icons.ev_station, color: Colors.white),
                    ),
                    title: Text(station['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${station['address']}\n${station['power']} • ${station['available']}'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(station['price'], style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                        Text(station['distance'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                    onTap: () => context.push('/station-details'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
