import 'dart:async';
import 'package:flutter/material.dart';

class HeroBannerSlider extends StatefulWidget {
  final VoidCallback onFindStationsPressed;

  const HeroBannerSlider({
    super.key,
    required this.onFindStationsPressed,
  });

  @override
  State<HeroBannerSlider> createState() => _HeroBannerSliderState();
}

class _HeroBannerSliderState extends State<HeroBannerSlider> {
  late final PageController _pageController;
  int _currentPage = 1;
  Timer? _timer;

  final List<Map<String, String>> _banners = [
    {
      'title1': 'Powering',
      'title2': 'a Greener Future',
      'subtitle': 'Find, Book & Charge at the\nbest EV charging stations.',
    },
    {
      'title1': 'Powering',
      'title2': 'a Greener Future',
      'subtitle': 'Find, Book & Charge at the\nbest EV charging stations.',
    },
    {
      'title1': 'Powering',
      'title2': 'a Greener Future',
      'subtitle': 'Find, Book & Charge at the\nbest EV charging stations.',
    },
    {
      'title1': 'Powering',
      'title2': 'a Greener Future',
      'subtitle': 'Find, Book & Charge at the\nbest EV charging stations.',
    },
    {
      'title1': 'Powering',
      'title2': 'a Greener Future',
      'subtitle': 'Find, Book & Charge at the\nbest EV charging stations.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 1);
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_currentPage < _banners.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 190,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFF0D1B1E),
        image: const DecorationImage(
          image: NetworkImage('https://images.unsplash.com/photo-1563720223185-11003d516935?w=600&q=80'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black54,
            BlendMode.darken,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Dark gradient overlay to match screenshot
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xEE091316),
                    Color(0xCC091316),
                    Color(0x44091316),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),

            // Page View Content
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
              },
              itemCount: _banners.length,
              itemBuilder: (context, index) {
                final banner = _banners[index];
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Headline Title
                      Text(
                        banner['title1']!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
                      ),
                      Text(
                        banner['title2']!,
                        style: const TextStyle(
                          color: Color(0xFF22C55E),
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Subtitle
                      Text(
                        banner['subtitle']!,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // CTA Button: Find Stations >
                      ElevatedButton(
                        onPressed: widget.onFindStationsPressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Find Stations',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            SizedBox(width: 6),
                            Icon(Icons.chevron_right_rounded, size: 18),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Page Indicator Dots at Bottom Center of Hero Banner
            Positioned(
              bottom: 14,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_banners.length, (index) {
                  final isActive = _currentPage == index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isActive ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFF22C55E) : Colors.white54,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
