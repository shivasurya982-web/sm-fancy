import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/product_model.dart';
import '../services/cart_service.dart';
import '../services/wishlist_service.dart';
import '../models/wishlist_item.dart';
import '../services/api_service.dart';
import '../services/user_service.dart';
import '../services/product_service.dart';
import '../config/theme.dart';
import '../widgets/gold_button.dart';
import '../widgets/product_card.dart';
import '../widgets/image_viewer.dart';
import 'checkout_screen.dart';
import 'login_screen.dart';

class ProductDetailsScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int _selectedQty = 1;
  bool _isAdding = false;
  int _activeImgIdx = 0;
  List<ProductModel> _relatedProducts = [];
  bool _isLoadingRelated = true;

  @override
  void initState() {
    super.initState();
    UserService.addToRecentlyViewed(widget.product.id);
    _loadRelatedProducts();
  }

  @override
  void didUpdateWidget(ProductDetailsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.product.id != widget.product.id) {
      _selectedQty = 1;
      _activeImgIdx = 0;
      _loadRelatedProducts();
    }
  }

  Future<void> _loadRelatedProducts() async {
    setState(() => _isLoadingRelated = true);
    try {
      final products = await ProductService.fetchProducts(
        category: widget.product.category,
        excludeId: widget.product.id,
      );
      if (mounted) {
        setState(() {
          _relatedProducts = products;
          _isLoadingRelated = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingRelated = false);
    }
  }

  bool _checkAuth() {
    if (!ApiService.isLoggedIn) {
      _showLoginPrompt();
      return false;
    }
    return true;
  }

  void _showLoginPrompt() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.deepCharcoal,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
            side: const BorderSide(color: AppTheme.platinumBorder)),
        title: const Text('LOGIN REQUIRED', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1)),
        content: const Text('Please login to explore more.',
            style: TextStyle(color: AppTheme.coolGrey)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('DISMISS',
                  style: TextStyle(color: AppTheme.coolGrey))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
            child: const Text('LOG IN'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isWide = screenWidth > 900;

    return Scaffold(
      backgroundColor: AppTheme.deepCharcoal,
      body: Container(
        decoration: AppTheme.filigreeBackground(),
        child: isWide ? _buildWideLayout() : _buildMobileLayout(),
      ),
    );
  }

  Widget _buildWideLayout() {
    final p = widget.product;
    final isLiked = WishlistService.isWishlisted(p.id);

    return Column(
      children: [
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCircularBtn(Icons.arrow_back_ios_new_rounded, () => Navigator.pop(context)),
                _buildCircularBtn(
                  isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  () async {
                    if (isLiked) {
                      await WishlistService.removeFromWishlist(p.id);
                    } else {
                      await WishlistService.addToWishlist(WishlistItem(productId: p.id, name: p.name, image: p.image, price: p.price));
                    }
                    setState(() {});
                  },
                  color: isLiked ? Colors.redAccent : AppTheme.brushedPlatinum,
                ),
              ],
            ),
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 1,
                      child: Container(
                        height: 550,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(color: AppTheme.glassBorder),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(32),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              PageView.builder(
                                itemCount: p.images.isNotEmpty ? p.images.length : 1,
                                onPageChanged: (v) => setState(() => _activeImgIdx = v),
                                itemBuilder: (ctx, idx) => _buildHeroImage(p.images.isNotEmpty ? p.images[idx] : p.image),
                              ),
                              if (p.images.length > 1)
                                Positioned(
                                  bottom: 24, left: 0, right: 0,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(p.images.length, (idx) => _buildPageIndicator(idx == _activeImgIdx)),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeaderSection(),
                          const SizedBox(height: 32),
                          _buildDescriptionAndSpecs(),
                          const SizedBox(height: 48),
                          _buildPurchaseSection(),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 80),
                _buildRelatedProductsSection(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    final p = widget.product;
    final isLiked = WishlistService.isWishlisted(p.id);
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isNarrow = screenWidth < 360;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: isNarrow ? 260 : 320,
          pinned: true,
          stretch: true,
          backgroundColor: Colors.transparent,
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: _buildCircularBtn(Icons.arrow_back_ios_new_rounded, () => Navigator.pop(context), size: 18),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: _buildCircularBtn(
                isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                () async {
                  if (!_checkAuth()) return;
                  if (isLiked) {
                    await WishlistService.removeFromWishlist(p.id);
                  } else {
                    await WishlistService.addToWishlist(WishlistItem(productId: p.id, name: p.name, image: p.image, price: p.price));
                  }
                  setState(() {});
                },
                color: isLiked ? Colors.redAccent : AppTheme.brushedPlatinum,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                PageView.builder(
                  itemCount: p.images.isNotEmpty ? p.images.length : 1,
                  onPageChanged: (v) => setState(() => _activeImgIdx = v),
                  itemBuilder: (ctx, idx) => _buildHeroImage(p.images.isNotEmpty ? p.images[idx] : p.image),
                ),
                if (p.images.length > 1)
                  Positioned(
                    bottom: 40, left: 0, right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(p.images.length, (idx) => _buildPageIndicator(idx == _activeImgIdx)),
                    ),
                  ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Transform.translate(
            offset: const Offset(0, -30),
            child: Container(
              padding: EdgeInsets.fromLTRB(isNarrow ? 16 : 24, 32, isNarrow ? 16 : 24, 40),
              decoration: BoxDecoration(
                color: AppTheme.deepCharcoal.withValues(alpha: 0.95),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                border: Border.all(color: AppTheme.glassBorder, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderSection(),
                  const SizedBox(height: 24),
                  _buildDescriptionAndSpecs(),
                  const SizedBox(height: 28),
                  _buildPurchaseSection(),
                  const SizedBox(height: 40),
                  _buildRelatedProductsSection(),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderSection() {
    final p = widget.product;
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isNarrow = screenWidth < 360;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(p.category.toUpperCase(), style: const TextStyle(color: AppTheme.coolGrey, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                p.name.toUpperCase(), 
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: isNarrow ? 20 : 22, fontWeight: FontWeight.w900, color: AppTheme.polishedSilver, letterSpacing: 1, height: 1.1),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '₹${p.price.toStringAsFixed(0)}', 
              style: TextStyle(fontSize: isNarrow ? 20 : 22, fontWeight: FontWeight.w300, color: AppTheme.brushedPlatinum, letterSpacing: -0.5),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDescriptionAndSpecs() {
    final p = widget.product;
    final hasSpecs = (p.metalType != null && p.metalType!.isNotEmpty) ||
                     (p.purity != null && p.purity!.isNotEmpty) ||
                     (p.weight != null && p.weight!.isNotEmpty) ||
                     (p.stoneInfo != null && p.stoneInfo!.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (p.description.isNotEmpty) ...[
          const Text('DESCRIPTION', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(height: 10),
          Text(p.description, style: const TextStyle(color: AppTheme.coolGrey, height: 1.5, fontSize: 13)),
        ],
        if (hasSpecs) ...[
          const SizedBox(height: 24),
          const Divider(color: AppTheme.glassBorder, thickness: 1),
          const SizedBox(height: 20),
          const Text('SPECIFICATIONS', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(height: 14),
          if (p.metalType != null && p.metalType!.isNotEmpty) _buildSpecRow('METAL', p.metalType!),
          if (p.purity != null && p.purity!.isNotEmpty) _buildSpecRow('PURITY', p.purity!),
          if (p.weight != null && p.weight!.isNotEmpty) _buildSpecRow('WEIGHT', p.weight!),
          if (p.stoneInfo != null && p.stoneInfo!.isNotEmpty) _buildSpecRow('STONES', p.stoneInfo!),
        ],
      ],
    );
  }

  Widget _buildPurchaseSection() {
    final p = widget.product;
    if (p.stock <= 0) return const Center(child: Text('UNAVAILABLE', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.w900, letterSpacing: 2)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('QUANTITY', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
                const SizedBox(height: 10),
                _buildQtyPicker(),
              ],
            ),
            Text('${p.stock} IN STOCK', style: const TextStyle(color: AppTheme.success, fontSize: 10, fontWeight: FontWeight.w900)),
          ],
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              flex: 1,
              child: _buildActionBtn('ADD TO CART', () async {
                setState(() => _isAdding = true);
                await CartService.addToCart(p, quantity: _selectedQty);
                if (mounted) {
                  setState(() => _isAdding = false);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to Cart'), duration: Duration(seconds: 1)));
                }
              }, isGlass: true),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: GoldButton(
                height: 52,
                label: 'BUY NOW',
                onPressed: () {
                  if (!ApiService.isLoggedIn) {
                    _showLoginPrompt();
                    return;
                  }
                  CartService.addToCart(p, quantity: _selectedQty);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckoutScreen()));
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRelatedProductsSection() {
    if (_isLoadingRelated) return const Center(child: CircularProgressIndicator(color: AppTheme.brushedPlatinum));
    if (_relatedProducts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: AppTheme.glassBorder, thickness: 1),
        const SizedBox(height: 28),
        const Text('MORE FROM THIS CATEGORY', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2.5)),
        const SizedBox(height: 10),
        Text('More ${widget.product.category}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.polishedSilver)),
        const SizedBox(height: 20),
        Builder(
          builder: (context) {
            final double screenWidth = MediaQuery.of(context).size.width;
            final double aspectRatio = screenWidth < 360 ? 0.55 : (screenWidth < 400 ? 0.60 : 0.64);
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _relatedProducts.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: screenWidth > 600 ? 3 : 2,
                childAspectRatio: aspectRatio,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (ctx, idx) => ProductCard(
                product: _relatedProducts[idx],
                onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ProductDetailsScreen(product: _relatedProducts[idx]))),
              ).animate().fadeIn(delay: (idx * 50).ms),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCircularBtn(IconData icon, VoidCallback onTap, {double size = 20, Color? color}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: Colors.white.withValues(alpha: 0.05),
          child: IconButton(
            icon: Icon(icon, size: size, color: color ?? AppTheme.brushedPlatinum),
            onPressed: onTap,
          ),
        ),
      ),
    );
  }

  Widget _buildPageIndicator(bool isSelected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isSelected ? 24 : 8,
      height: 2,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        color: isSelected ? AppTheme.brushedPlatinum : AppTheme.platinumBorder,
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.coolGrey, fontSize: 10, letterSpacing: 1)),
          Text(value.toUpperCase(), style: const TextStyle(color: AppTheme.polishedSilver, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildHeroImage(String url) {
    return GestureDetector(
      onTap: () {
        FullScreenImageViewer.show(context, url, title: widget.product.name);
      },
      child: CachedNetworkImage(
        imageUrl: url, fit: BoxFit.cover,
        placeholder: (_, __) => Container(color: AppTheme.matteBlack),
        errorWidget: (_, __, ___) => const Icon(Icons.diamond_outlined, color: AppTheme.platinumBorder),
      ),
    );
  }

  Widget _buildQtyPicker() {
    return Container(
      width: 120,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(100), border: Border.all(color: AppTheme.glassBorder, width: 1), color: Colors.white.withValues(alpha: 0.05)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(onPressed: () { if (_selectedQty > 1) setState(() => _selectedQty--); }, icon: const Icon(Icons.remove, size: 14, color: AppTheme.brushedPlatinum)),
          Text('$_selectedQty', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppTheme.polishedSilver)),
          IconButton(onPressed: () { if (_selectedQty < widget.product.stock) setState(() => _selectedQty++); }, icon: const Icon(Icons.add, size: 14, color: AppTheme.brushedPlatinum)),
        ],
      ),
    );
  }

  Widget _buildActionBtn(String label, VoidCallback onTap, {bool isGlass = false}) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: isGlass ? Colors.white.withValues(alpha: 0.08) : AppTheme.brushedPlatinum,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: AppTheme.glassBorder, width: 1),
            ),
            alignment: Alignment.center,
            child: _isAdding && isGlass
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 1, color: Colors.white))
                : Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: isGlass ? Colors.white : Colors.black, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
          ),
        ),
      ),
    );
  }
}
