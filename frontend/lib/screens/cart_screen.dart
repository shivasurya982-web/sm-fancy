import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';
import '../services/cart_service.dart';
import '../services/product_service.dart';
import '../models/cart_item.dart';
import '../config/theme.dart';
import '../bottom_navigation.dart';
import '../widgets/gold_button.dart';
import 'product_details_screen.dart';
import 'checkout_screen.dart';
import 'login_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _isLoading = true);
    await CartService.fetchCart();
    if (mounted) setState(() => _isLoading = false);
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
          child: ValueListenableBuilder<List<CartItem>>(
            valueListenable: CartService.cartItemsNotifier,
            builder: (context, items, _) {
              if (_isLoading && items.isEmpty) {
                return const Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.brushedPlatinum));
              }

              if (items.isEmpty) {
                return _buildEmptyState(context);
              }

              return Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
                        child: Text('CART',
                            style: Theme.of(context).textTheme.headlineLarge),
                      ),

                      // Scrollable List
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: _load,
                          color: AppTheme.brushedPlatinum,
                          backgroundColor: AppTheme.matteBlack,
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(24, 10, 24, 120),
                            itemCount: items.length,
                            separatorBuilder: (ctx, idx) =>
                                const SizedBox(height: 16),
                            itemBuilder: (context, index) =>
                                _buildCartItem(context, items[index]),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Floating Summary at the very bottom of the stack
                  Positioned(
                    bottom: 10,
                    left: 20,
                    right: 20,
                    child: _buildSummary(context, CartService.cartTotal),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCartItem(BuildContext context, CartItem item) {
    return GestureDetector(
      onTap: () async {
        try {
          final product = await ProductService.getProductById(item.productId);
          if (mounted) {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ProductDetailsScreen(product: product)));
          }
        } catch (_) {}
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.premiumCard(radius: 24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white.withOpacity(0.05),
                border: Border.all(color: AppTheme.glassBorder, width: 0.8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: item.image.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: item.image,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: Colors.white10),
                        errorWidget: (context, url, error) => const Icon(
                            Icons.diamond_outlined,
                            color: Colors.white10),
                      )
                    : const Icon(Icons.diamond_outlined, color: Colors.white10),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name.toUpperCase(),
                    style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        letterSpacing: 0.5,
                        color: AppTheme.polishedSilver),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${item.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w300,
                        fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildQtyBtn(Icons.remove_rounded, () async {
                        if (item.quantity > 1) {
                          await CartService.updateQuantity(
                              item.productId, item.quantity - 1);
                        }
                      }),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('${item.quantity}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                                color: AppTheme.polishedSilver)),
                      ),
                      _buildQtyBtn(Icons.add_rounded, () async {
                        await CartService.updateQuantity(
                            item.productId, item.quantity + 1);
                      }),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded,
                            size: 20, color: AppTheme.error),
                        onPressed: () async {
                          await CartService.removeFromCart(item.productId);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideX(begin: 0.05, end: 0);
  }

  Widget _buildQtyBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.05),
          border: Border.all(color: AppTheme.glassBorder, width: 0.8),
        ),
        child: Icon(icon, size: 14, color: AppTheme.brushedPlatinum),
      ),
    );
  }

  void _showLoginPrompt() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.deepCharcoal,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30), side: const BorderSide(color: AppTheme.platinumBorder)),
        title: const Text('LOGIN REQUIRED', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1)),
        content: const Text('Please login to complete your purchase.', style: TextStyle(color: AppTheme.coolGrey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('DISMISS', style: TextStyle(color: AppTheme.coolGrey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen()));
            },
            child: const Text('LOG IN'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(BuildContext context, double total) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.deepCharcoal.withOpacity(0.9),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: AppTheme.glassBorder, width: 1),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, 10))
        ],
      ),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('TOTAL',
                  style: TextStyle(
                      color: AppTheme.coolGrey,
                      fontWeight: FontWeight.w900,
                      fontSize: 8,
                      letterSpacing: 1.5)),
              Text(
                '₹${total.toStringAsFixed(0)}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: GoldButton(
              height: 48,
              label: 'CHECKOUT',
              onPressed: () {
                if (!ApiService.isLoggedIn) {
                  _showLoginPrompt();
                  return;
                }
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => CheckoutScreen()));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.shopping_bag_outlined, size: 60, color: Colors.white10),
          const SizedBox(height: 24),
          Text('CART IS EMPTY',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(letterSpacing: 2, color: AppTheme.polishedSilver)),
          const SizedBox(height: 48),
          TextButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => BottomNavigation()),
                  (route) => false);
            },
            child: const Text('EXPLORE SHOP',
                style: TextStyle(
                    color: AppTheme.brushedPlatinum,
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                    letterSpacing: 1.5)),
          ),
        ],
      ).animate().fadeIn(),
    );
  }
}
