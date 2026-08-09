import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Favorite Stations'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF16A34A),
                child: Icon(Icons.favorite, color: Colors.white),
              ),
              title: const Text('GreenCharge Hub Sector 62', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Electronic City, Bengaluru\n60 kW DC Fast • Open 24/7'),
              trailing: IconButton(
                icon: const Icon(Icons.favorite, color: Colors.red),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Removed from favorites')),
                  );
                },
              ),
              onTap: () => context.push('/station-details'),
            ),
          ),
        ],
      ),
    );
  }
}
