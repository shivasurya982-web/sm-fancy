import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

class BannerSlider extends StatelessWidget {
  const BannerSlider({super.key});

  @override
  Widget build(BuildContext context) {
    final banners = [
      {
        "title": "Festival Sale",
        "subtitle": "Up to 50% OFF",
        "icon": Icons.local_offer,
      },
      {
        "title": "New Arrivals",
        "subtitle": "Latest Fashion Collection",
        "icon": Icons.shopping_bag,
      },
      {
        "title": "Wedding Collection",
        "subtitle": "Exclusive Fancy Items",
        "icon": Icons.favorite,
      },
    ];

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isSmall = screenWidth < 360;

    return CarouselSlider.builder(
      itemCount: banners.length,
      options: CarouselOptions(
        height: isSmall ? 160 : 180,
        autoPlay: true,
        viewportFraction: 1,
        autoPlayInterval: const Duration(seconds: 3),
      ),
      itemBuilder: (context, index, realIndex) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF0D0D0D),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: EdgeInsets.all(isSmall ? 14 : 20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        banners[index]["title"] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: const Color(0xFFD4AF37),
                          fontSize: isSmall ? 18 : 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        banners[index]["subtitle"] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isSmall ? 12 : 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4AF37),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          "Shop Now",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: isSmall ? 8 : 16),
                Icon(
                  banners[index]["icon"] as IconData,
                  size: isSmall ? 48 : 60,
                  color: const Color(0xFFD4AF37),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
