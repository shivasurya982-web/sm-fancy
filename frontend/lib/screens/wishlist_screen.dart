import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/wishlist_service.dart';
import '../services/cart_service.dart';
import '../services/product_service.dart';
import '../config/theme.dart';
import '../bottom_navigation.dart';
import 'product_details_screen.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  @override
  void initState() {
    super.initState();
    WishlistService.loadWishlist();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isWeb = screenWidth > 800;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isWeb ? 500 : double.infinity),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
                child: Text(
                  'WISHLIST',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
              ),
              
              Expanded(
                child: ValueListenableBuilder<List<dynamic>>(
                  valueListenable: WishlistService.wishlistNotifier,
                  builder: (context, items, _) {
                    if (items.isEmpty) {
                      return _buildEmptyState(context);
                    }
                    return Builder(
                      builder: (context) {
                        final double screenWidth = MediaQuery.of(context).size.width;
                        final int crossAxisCount = screenWidth > 600 ? 3 : 2;
                        final double aspectRatio = screenWidth < 360 ? 0.56 : 0.62;
                        return GridView.builder(
                          padding: const EdgeInsets.fromLTRB(24, 20, 24, 120),
                          itemCount: items.length,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            childAspectRatio: aspectRatio,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 24,
                          ),
                          itemBuilder: (context, index) {
                            return _buildWishlistCard(items[index]);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWishlistCard(dynamic item) {
    return GestureDetector(
      onTap: () async {
        try {
          final product = await ProductService.getProductById(item.productId);
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ProductDetailsScreen(product: product)),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error loading product: $e')),
            );
          }
        }
      },
      child: Container(
        decoration: AppTheme.premiumCard(radius: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: _buildItemImage(item.image),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: () async {
                        await WishlistService.removeFromWishlist(item.productId);
                      },
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.black.withOpacity(0.4),
                        child: const Icon(Icons.close_rounded, color: Colors.white, size: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1, color: AppTheme.polishedSilver),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "₹${item.price.toStringAsFixed(0)}",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w300, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 36,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        textStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                      ),
                      onPressed: () async {
                        // Fetch full product for cart fallback
                        final product = await ProductService.getProductById(item.productId);
                        await CartService.addToCart(product);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('ADDED TO CART'), behavior: SnackBarBehavior.floating, duration: Duration(seconds: 1))
                          );
                        }
                      },
                      child: const Text("TRANSFER"),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 50.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildItemImage(String url) {
    if (url.isEmpty || url.contains('aura_perfume.jpg')) {
      return Container(color: Colors.white.withOpacity(0.05));
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(color: Colors.white.withOpacity(0.05)),
      errorWidget: (context, url, error) => Container(color: Colors.white.withOpacity(0.05)),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.favorite_border_rounded, size: 60, color: Colors.white10),
          const SizedBox(height: 24),
          Text('WISHLIST IS EMPTY', style: Theme.of(context).textTheme.titleLarge?.copyWith(letterSpacing: 2, color: AppTheme.polishedSilver)),
          const SizedBox(height: 12),
          const Text('Save luxury items you love here.', style: TextStyle(color: AppTheme.coolGrey, fontSize: 12)),
          const SizedBox(height: 48),
          TextButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => BottomNavigation()), (route) => false);
            },
            child: const Text('EXPLORE ARCHIVE', style: TextStyle(color: AppTheme.brushedPlatinum, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.5)),
          ),
        ],
      ).animate().fadeIn(),
    );
  }
}
