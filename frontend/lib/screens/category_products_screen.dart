import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';
import '../config/theme.dart';
import '../widgets/product_card.dart';
import 'product_details_screen.dart';

class CategoryProductsScreen extends StatefulWidget {
  final String category;

  const CategoryProductsScreen({super.key, required this.category});

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  List<ProductModel> _products = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final list = await ProductService.fetchProducts(category: widget.category);
      setState(() => _products = list);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.deepCharcoal,
      appBar: AppBar(
        title: Text(widget.category.toUpperCase(), style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 4)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20), onPressed: () => Navigator.pop(context)),
      ),
      body: Container(
        decoration: AppTheme.filigreeBackground(),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: AppTheme.glassBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search_outlined, color: AppTheme.coolGrey, size: 18),
                    const SizedBox(width: 12),
                    Text('SEARCH IN ${widget.category.toUpperCase()}...', style: const TextStyle(color: AppTheme.coolGrey, fontSize: 10, letterSpacing: 1)),
                  ],
                ),
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.brushedPlatinum))
                  : _products.isEmpty
                      ? _buildEmptyState()
                      : GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
                          itemCount: _products.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.64,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemBuilder: (ctx, idx) {
                            return ProductCard(
                              product: _products[idx],
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => ProductDetailsScreen(product: _products[idx])),
                              ),
                            ).animate().fadeIn(delay: (idx % 10 * 50).ms).scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOut);
                          },
                        ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inventory_2_outlined, size: 60, color: Colors.white10),
          const SizedBox(height: 24),
          const Text('NO PRODUCTS FOUND', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 14, color: AppTheme.polishedSilver)),
          const SizedBox(height: 8),
          const Text('Check back soon for new items.', style: TextStyle(color: AppTheme.coolGrey, fontSize: 12)),
        ],
      ),
    );
  }
}
