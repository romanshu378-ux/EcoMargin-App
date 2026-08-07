import 'package:flutter/material.dart';

class OffersCouponsScreen extends StatelessWidget {
  const OffersCouponsScreen({super.key});

  final List<Map<String, String>> _coupons = const [
    {
      'code': 'ECOGREEN20',
      'title': '20% Cashback on First Charging Session',
      'desc': 'Get up to ₹100 cashback credited into your EcoMargin Wallet.',
      'expiry': 'Valid till 31 Aug 2026',
    },
    {
      'code': 'FASTCHARGE50',
      'title': 'Flat ₹50 OFF on DC Fast Chargers',
      'desc': 'Applicable on session power > 50 kW.',
      'expiry': 'Valid till 15 Aug 2026',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offers & Promo Coupons'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _coupons.length,
        itemBuilder: (context, index) {
          final item = _coupons[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item['code']!,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Coupon code ${item['code']} copied to clipboard!')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF0F172A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('COPY CODE'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  item['title']!,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  item['desc']!,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const Divider(color: Colors.white24, height: 20),
                Text(
                  item['expiry']!,
                  style: const TextStyle(color: Color(0xFF22C55E), fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
