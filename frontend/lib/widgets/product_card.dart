import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/theme.dart';
import '../models/product_model.dart';
import '../services/wishlist_service.dart';
import '../models/wishlist_item.dart';
import '../services/cart_service.dart';

class ProductCard extends StatefulWidget {
  final ProductModel product;
  final VoidCallback? onTap;

  const ProductCard({super.key, required this.product, this.onTap});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> with SingleTickerProviderStateMixin {
  bool _isAdding = false;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final isLiked = WishlistService.isWishlisted(product.id);
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isNarrow = screenWidth < 360;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: AppTheme.premiumCard(radius: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: _buildImage(product.image),
                      ),
                    ),
                  ),
                  
                  if (product.stock <= 0)
                    Positioned.fill(
                      child: Container(
                        margin: const EdgeInsets.all(6.0),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            'UNAVAILABLE', 
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 8, letterSpacing: 1),
                          ),
                        ),
                      ),
                    ),
                  
                  // Glassy Wishlist Icon
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () async {
                        if (isLiked) {
                          await WishlistService.removeFromWishlist(product.id);
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Removed from Wishlist'), duration: Duration(seconds: 1)));
                        } else {
                          await WishlistService.addToWishlist(WishlistItem(
                            productId: product.id,
                            name: product.name,
                            image: product.image,
                            price: product.price,
                          ));
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to Wishlist'), duration: Duration(seconds: 1)));
                        }
                        if (mounted) setState(() {});
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 0.5),
                        ),
                        child: Icon(
                          isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: isLiked ? Colors.redAccent : AppTheme.coolGrey,
                          size: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Info Section
            Padding(
              padding: EdgeInsets.fromLTRB(isNarrow ? 8 : 12, 4, isNarrow ? 8 : 12, isNarrow ? 8 : 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: isNarrow ? 9 : 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      color: AppTheme.polishedSilver,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '₹${product.price.toStringAsFixed(0)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w300,
                            fontSize: isNarrow ? 12 : 13,
                          ),
                        ),
                      ),
                      
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () async {
                          if (_isAdding) return;
                          _animController.forward().then((_) => _animController.reverse());
                          setState(() => _isAdding = true);
                          await CartService.addToCart(product);
                          if (mounted) {
                            setState(() => _isAdding = false);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to Cart'), duration: Duration(seconds: 1)));
                          }
                        },
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 1.0, end: 0.8).animate(_animController),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppTheme.brushedPlatinum,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.shopping_bag_outlined, 
                              color: Colors.black, 
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String url) {
    if (url.isEmpty) {
      return Container(
        color: Colors.white.withValues(alpha: 0.05),
        child: const Center(child: Icon(Icons.diamond_outlined, color: Colors.white10, size: 24)),
      );
    }
    
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(color: Colors.white.withValues(alpha: 0.05)),
      errorWidget: (context, url, error) => Container(
        color: Colors.white.withValues(alpha: 0.05),
        child: const Center(child: Icon(Icons.diamond_outlined, color: Colors.white10)),
      ),
    );
  }
}
