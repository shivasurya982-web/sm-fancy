import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';
import '../services/cart_service.dart';
import '../services/settings_service.dart';
import '../services/category_service.dart';
import '../services/user_service.dart';
import '../config/theme.dart';
import '../widgets/product_card.dart';
import 'product_details_screen.dart';
import 'categories_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'All';
  List<ProductModel> _allProducts = [];
  List<ProductModel> _filteredProducts = [];
  List<dynamic> _banners = [];
  List<dynamic> _categories = [];
  bool _isLoading = false;
  String _sortBy = 'Newest';
  
  double _minPrice = 0;
  double _maxPrice = 100000;
  bool _onlyInStock = false;
  
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    if (mounted && (_allProducts.isEmpty || forceRefresh)) {
        setState(() => _isLoading = true);
    }
    try {
      await Future.wait([
        _loadProducts(forceRefresh), 
        _loadSettings(), 
        _loadCategories()
      ]);
      _applyFilterAndSort();
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadProducts(bool forceRefresh) async {
    try {
      final list = await ProductService.fetchProducts(forceRefresh: forceRefresh);
      if (mounted) setState(() => _allProducts = list);
    } catch (_) {}
  }

  Future<void> _loadSettings() async {
    final settings = await SettingsService.getSettings();
    if (mounted) {
      setState(() {
        _banners = settings['homeBanners'] ?? settings['onboardingBanners'] ?? [];
      });
    }
  }

  Future<void> _loadCategories() async {
    final list = await CategoryService.fetchCategories();
    if (mounted) setState(() => _categories = list);
  }

  void _applyFilterAndSort() {
    final query = _searchController.text.toLowerCase();
    List<ProductModel> filtered = List.from(_allProducts);
    
    // Search Filter
    if (query.isNotEmpty) {
      filtered = filtered.where((p) => 
        p.name.toLowerCase().contains(query) || 
        p.category.toLowerCase().contains(query) ||
        p.description.toLowerCase().contains(query)
      ).toList();
    }

    // Category Filter
    if (_selectedCategory != 'All') {
      filtered = filtered.where((p) => p.category == _selectedCategory).toList();
    }
    
    // Price Filter
    filtered = filtered.where((p) => p.price >= _minPrice && p.price <= _maxPrice).toList();
    
    // Stock Filter
    if (_onlyInStock) {
      filtered = filtered.where((p) => p.stock > 0).toList();
    }
    
    // Sort
    if (_sortBy == 'Price: Low to High') {
      filtered.sort((a, b) => a.price.compareTo(b.price));
    } else if (_sortBy == 'Price: High to Low') {
      filtered.sort((a, b) => b.price.compareTo(a.price));
    }
    
    setState(() => _filteredProducts = filtered);
  }

  Widget _buildPriceAdjustBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.glassBorder, width: 0.8),
          color: Colors.white.withOpacity(0.05),
        ),
        child: Icon(icon, color: AppTheme.brushedPlatinum, size: 14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: () => _loadData(forceRefresh: true),
        color: AppTheme.brushedPlatinum,
        backgroundColor: AppTheme.matteBlack,
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: SizedBox(height: 100)),

            // 1. Search Bar (Same Page Logic)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              sliver: SliverToBoxAdapter(
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
                      const Icon(Icons.search_outlined, color: AppTheme.coolGrey, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (_) => _applyFilterAndSort(),
                          style: const TextStyle(color: AppTheme.polishedSilver, fontSize: 14),
                          decoration: const InputDecoration(
                            hintText: 'Search for pieces...',
                            hintStyle: TextStyle(color: AppTheme.coolGrey, fontSize: 13),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppTheme.coolGrey, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _applyFilterAndSort();
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),

            if (_banners.isNotEmpty && _searchController.text.isEmpty)
              SliverPadding(
                padding: const EdgeInsets.only(top: 20),
                sliver: SliverToBoxAdapter(
                  child: CarouselSlider(
                    options: CarouselOptions(
                      height: 220,
                      viewportFraction: 0.9,
                      enlargeCenterPage: true,
                      autoPlay: true,
                    ),
                    items: _banners.map((banner) {
                      return Container(
                        width: double.infinity,
                        decoration: AppTheme.premiumCard(radius: 32),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(32),
                          child: _buildBannerImage(banner['image']),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 48, 32, 20),
                child: Row(
                  children: [
                    Text(_searchController.text.isEmpty ? 'CURATED COLLECTIONS' : 'SEARCH RESULTS', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 9)),
                    const Spacer(),
                    if (_searchController.text.isEmpty)
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoriesScreen())),
                        child: Text('VIEW ALL', style: TextStyle(color: AppTheme.brushedPlatinum, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
                      ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () {
                         String tempSort = _sortBy;
                         double tempMin = _minPrice;
                         double tempMax = _maxPrice;
                         bool tempStock = _onlyInStock;

                         showModalBottomSheet(
                           context: context,
                           backgroundColor: Colors.transparent,
                           isScrollControlled: true,
                           builder: (ctx) => StatefulBuilder(
                             builder: (context, setSheetState) => Container(
                               padding: const EdgeInsets.all(32),
                               decoration: BoxDecoration(
                                 color: AppTheme.deepCharcoal,
                                 borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                                 border: Border.all(color: AppTheme.glassBorder),
                               ),
                               child: Column(
                                 mainAxisSize: MainAxisSize.min,
                                 crossAxisAlignment: CrossAxisAlignment.start,
                                 children: [
                                   Row(
                                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                     children: [
                                       Text('FILTERS & SORTING', style: Theme.of(context).textTheme.labelSmall),
                                       IconButton(
                                         onPressed: () => Navigator.pop(ctx),
                                         icon: const Icon(Icons.close_rounded, color: AppTheme.coolGrey, size: 20),
                                       ),
                                     ],
                                   ),
                                   const SizedBox(height: 24),
                                   const Text('SORT BY', style: TextStyle(color: AppTheme.coolGrey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                   const SizedBox(height: 12),
                                   
                                   ...['Newest', 'Price: Low to High', 'Price: High to Low'].map((opt) => GestureDetector(
                                      onTap: () => setSheetState(() => tempSort = opt),
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        child: Row(
                                          children: [
                                            Text(opt.toUpperCase(), style: TextStyle(color: tempSort == opt ? AppTheme.polishedSilver : AppTheme.coolGrey, fontWeight: tempSort == opt ? FontWeight.w900 : FontWeight.w400, fontSize: 12, letterSpacing: 1)),
                                            const Spacer(),
                                            if (tempSort == opt) const Icon(Icons.check_rounded, color: AppTheme.brushedPlatinum, size: 18),
                                          ],
                                        ),
                                      ),
                                   )),

                                   const SizedBox(height: 24),
                                   Row(
                                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                     children: [
                                       const Text('PRICE RANGE (₹)', style: TextStyle(color: AppTheme.coolGrey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                       Row(
                                         children: [
                                           _buildPriceAdjustBtn(Icons.remove, () => setSheetState(() { if (tempMax > tempMin + 100) tempMax -= 100; })),
                                           const SizedBox(width: 12),
                                           Text('₹${tempMax.round()}', style: const TextStyle(color: AppTheme.polishedSilver, fontSize: 11, fontWeight: FontWeight.bold)),
                                           const SizedBox(width: 12),
                                           _buildPriceAdjustBtn(Icons.add, () => setSheetState(() { if (tempMax < 100000) tempMax += 100; })),
                                         ],
                                       ),
                                     ],
                                   ),
                                   const SizedBox(height: 8),
                                   RangeSlider(
                                     values: RangeValues(tempMin, tempMax),
                                     min: 0, max: 100000, divisions: 1000,
                                     activeColor: AppTheme.brushedPlatinum, inactiveColor: Colors.white10,
                                     labels: RangeLabels('₹${tempMin.round()}', '₹${tempMax.round()}'),
                                     onChanged: (values) => setSheetState(() { tempMin = values.start; tempMax = values.end; }),
                                   ),
                                   
                                   const SizedBox(height: 24),
                                   Row(
                                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                     children: [
                                       const Text('ONLY IN STOCK', style: TextStyle(color: AppTheme.coolGrey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                       Switch(
                                         value: tempStock,
                                         activeColor: AppTheme.brushedPlatinum,
                                         onChanged: (val) => setSheetState(() => tempStock = val),
                                       ),
                                     ],
                                   ),
                                   
                                   const SizedBox(height: 40),
                                   SizedBox(
                                     width: double.infinity,
                                     child: ElevatedButton(
                                       onPressed: () {
                                          _sortBy = tempSort;
                                          _minPrice = tempMin;
                                          _maxPrice = tempMax;
                                          _onlyInStock = tempStock;
                                          _applyFilterAndSort();
                                          Navigator.pop(ctx);
                                       },
                                       child: const Text('APPLY FILTERS'),
                                     ),
                                   ),
                                   const SizedBox(height: 20),
                                 ],
                               ),
                             ),
                           ),
                         );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: AppTheme.capsuleDecoration(),
                        child: const Icon(Icons.tune_rounded, color: AppTheme.brushedPlatinum, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (_searchController.text.isEmpty)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 44,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length + 1,
                    separatorBuilder: (ctx, index) => const SizedBox(width: 12),
                    itemBuilder: (ctx, idx) {
                      final isAll = idx == 0;
                      final name = isAll ? 'ALL' : _categories[idx - 1]['name'].toString().toUpperCase();
                      final isSelected = _selectedCategory == (isAll ? 'All' : _categories[idx - 1]['name']);
                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedCategory = isAll ? 'All' : _categories[idx - 1]['name']);
                          _applyFilterAndSort();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.brushedPlatinum : Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: isSelected ? AppTheme.brushedPlatinum : AppTheme.glassBorder, width: 0.8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            name,
                            style: TextStyle(
                              color: isSelected ? Colors.black : AppTheme.coolGrey,
                              fontSize: 10,
                              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(32, 20, 32, 120),
              sliver: _isLoading
                  ? const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppTheme.brushedPlatinum)))
                  : _filteredProducts.isEmpty
                  ? const SliverFillRemaining(child: Center(child: Text('NO ITEMS FOUND', style: TextStyle(color: AppTheme.coolGrey, fontWeight: FontWeight.w900, letterSpacing: 2))))
                  : SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.64,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (ctx, idx) {
                          return ProductCard(
                            product: _filteredProducts[idx],
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => ProductDetailsScreen(product: _filteredProducts[idx])),
                            ),
                          ).animate().fadeIn(duration: 400.ms, delay: (idx % 4 * 100).ms).scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOut);
                        },
                        childCount: _filteredProducts.length,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerImage(String? url) {
    if (url == null || url.isEmpty) return Container(color: Colors.white10);
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      errorWidget: (context, url, error) => Container(color: Colors.white10),
    );
  }
}
