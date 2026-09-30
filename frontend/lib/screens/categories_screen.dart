import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/theme.dart';
import '../services/category_service.dart';
import 'category_products_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<dynamic> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final list = await CategoryService.fetchCategories();
      if (mounted) setState(() { _categories = list; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isNarrow = screenWidth < 360;

    return Scaffold(
      backgroundColor: AppTheme.deepCharcoal,
      appBar: AppBar(title: const Text('ALL CATEGORIES')),
      body: Container(
        decoration: AppTheme.filigreeBackground(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(isNarrow ? 20 : 32, 16, isNarrow ? 20 : 32, 24),
              child: Text('CATEGORIES', style: Theme.of(context).textTheme.headlineLarge?.copyWith(letterSpacing: 2, fontSize: isNarrow ? 22 : 28)),
            ),
            Expanded(
              child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: AppTheme.brushedPlatinum))
              : _categories.isEmpty
                  ? const Center(child: Text('No categories found.', style: TextStyle(color: AppTheme.coolGrey)))
                  : ListView.separated(
                      padding: EdgeInsets.fromLTRB(isNarrow ? 16 : 24, 0, isNarrow ? 16 : 24, 120),
                      itemCount: _categories.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (ctx, idx) {
                          final cat = _categories[idx];
                          final String name = cat['name'] ?? 'General';
                          final String? image = cat['image'];
                          return GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CategoryProductsScreen(category: name))),
                            child: Container(
                                height: isNarrow ? 150 : 180,
                                decoration: AppTheme.premiumCard(radius: 24),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: Stack(
                                      children: [
                                      Positioned.fill(child: _buildCategoryImage(image)),
                                      Positioned.fill(child: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent], begin: Alignment.bottomCenter, end: Alignment.topCenter)))),
                                      Padding(
                                          padding: EdgeInsets.all(isNarrow ? 16 : 24),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                                Text(name.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: isNarrow ? 18 : 22, fontWeight: FontWeight.w900, color: AppTheme.polishedSilver, letterSpacing: 1)),
                                                const SizedBox(height: 4),
                                                const Text('VIEW COLLECTION', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: AppTheme.coolGrey)),
                                            ],
                                          ),
                                      ),
                                      ],
                                  ),
                                ),
                            ),
                          ).animate().fadeIn(delay: (idx * 50).ms).scale(begin: const Offset(0.98, 0.98), curve: Curves.easeOut);
                      },
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryImage(String? image) {
    if (image == null || image.isEmpty) return Container(color: Colors.white.withValues(alpha: 0.05));
    return CachedNetworkImage(imageUrl: image, fit: BoxFit.cover, errorWidget: (_,__,___) => Container(color: Colors.white10));
  }
}
