import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Driver Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const ListTile(
            leading: Icon(Icons.person, color: Color(0xFF10B981)),
            title: Text('Alex Rivers'),
            subtitle: Text('alex@example.com'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.electric_car, color: Color(0xFF10B981)),
            title: const Text('Tesla Model 3 Long Range'),
            subtitle: const Text('Plug Type: CCS2'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Sign Out', style: TextStyle(color: Colors.redAccent)),
            onTap: () => Navigator.pushReplacementNamed(context, '/login'),
          ),
        ],
      ),
    );
  }
}
