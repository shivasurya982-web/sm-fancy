import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';
import '../services/category_service.dart';
import '../config/theme.dart';
import 'product_details_screen.dart';
import 'category_products_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<ProductModel> productSuggestions = [];
  List<String> categorySuggestions = [];
  List<String> recentSearches = [];
  bool isLoading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    CategoryService.fetchCategories();
    _loadRecentSearches();
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        recentSearches = prefs.getStringList('recent_searches') ?? [];
      });
    }
  }

  Future<void> _saveSearch(String query) async {
    if (query.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    List<String> searches = prefs.getStringList('recent_searches') ?? [];
    searches.remove(query);
    searches.insert(0, query);
    if (searches.length > 5) searches = searches.sublist(0, 5);
    await prefs.setStringList('recent_searches', searches);
    _loadRecentSearches();
  }

  @override
  void dispose() { _searchController.dispose(); _debounce?.cancel(); super.dispose(); }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (query.isEmpty) { 
        if (mounted) setState(() { productSuggestions = []; categorySuggestions = []; }); 
        return; 
      }
      _fetchSuggestions(query);
    });
  }

  Future<void> _fetchSuggestions(String query) async {
    if (mounted) setState(() => isLoading = true);
    try {
      final matchedCats = CategoryService.cachedCategories
          .map((c) => c['name']?.toString() ?? '')
          .where((cat) => cat.toLowerCase().contains(query.toLowerCase())).toList();
      final matchedProducts = await ProductService.fetchProducts(search: query, forceRefresh: true);
      if (mounted) setState(() { categorySuggestions = matchedCats; productSuggestions = matchedProducts; });
    } catch (_) {}
    if (mounted) setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isNarrow = screenWidth < 360;

    return Scaffold(
      backgroundColor: AppTheme.deepCharcoal,
      appBar: AppBar(
        title: TextField(
          controller: _searchController, autofocus: true, 
          onChanged: _onSearchChanged,
          onSubmitted: (v) => _saveSearch(v),
          decoration: const InputDecoration(hintText: 'Search products...', border: InputBorder.none, filled: false),
          style: const TextStyle(fontSize: 14, letterSpacing: 0.5),
        ),
      ),
      body: Container(
        decoration: AppTheme.filigreeBackground(),
        child: Column(
          children: [
            if (isLoading) const LinearProgressIndicator(minHeight: 1, valueColor: AlwaysStoppedAnimation(AppTheme.brushedPlatinum), backgroundColor: Colors.transparent),
            Expanded(
              child: _searchController.text.isEmpty
                  ? _buildRecentSearches(isNarrow)
                  : ListView(
                      padding: EdgeInsets.fromLTRB(isNarrow ? 16 : 24, 20, isNarrow ? 16 : 24, 40),
                      children: [
                        if (categorySuggestions.isNotEmpty) ...[
                          _buildSectionHeader('CATEGORIES'),
                          ...categorySuggestions.map((cat) => _buildCategoryTile(cat)),
                          const SizedBox(height: 20),
                        ],
                        if (productSuggestions.isNotEmpty) ...[
                          _buildSectionHeader('PRODUCTS'),
                          ...productSuggestions.map((product) => _buildProductTile(product)),
                        ],
                        if (categorySuggestions.isEmpty && productSuggestions.isEmpty && !isLoading)
                          const Padding(
                            padding: EdgeInsets.only(top: 80),
                            child: Center(child: Text('No results found.', style: TextStyle(color: AppTheme.coolGrey))),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSearches(bool isNarrow) {
    if (recentSearches.isEmpty) return const Center(child: Text('SEARCH', style: TextStyle(color: Colors.white10, fontWeight: FontWeight.w900, letterSpacing: 10, fontSize: 32)));
    return ListView(
      padding: EdgeInsets.fromLTRB(isNarrow ? 16 : 24, 20, isNarrow ? 16 : 24, 40),
      children: [
        _buildSectionHeader('RECENT SEARCHES'),
        ...recentSearches.map((s) => _buildRecentSearchTile(s)),
      ],
    );
  }

  Widget _buildSectionHeader(String title) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(title, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 8)));

  Widget _buildRecentSearchTile(String s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: AppTheme.premiumCard(radius: 20),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          onTap: () { _searchController.text = s; _fetchSuggestions(s); },
          leading: const Icon(Icons.history_rounded, color: AppTheme.coolGrey, size: 18),
          title: Text(s, style: const TextStyle(fontSize: 13, color: AppTheme.polishedSilver)),
          trailing: const Icon(Icons.arrow_outward_rounded, size: 14, color: Colors.white10),
        ),
      ),
    );
  }

  Widget _buildCategoryTile(String cat) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: AppTheme.premiumCard(radius: 20),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CategoryProductsScreen(category: cat))),
          leading: Container(
            padding: const EdgeInsets.all(8), 
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), shape: BoxShape.circle), 
            child: const Icon(Icons.grid_view_rounded, color: AppTheme.brushedPlatinum, size: 16)
          ),
          title: Text(cat.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1, color: AppTheme.polishedSilver)),
        ),
      ),
    );
  }

  Widget _buildProductTile(ProductModel product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: AppTheme.premiumCard(radius: 20),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailsScreen(product: product))),
          leading: Container(
            width: 40, height: 40, 
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.white.withValues(alpha: 0.05)), 
            child: ClipRRect(borderRadius: BorderRadius.circular(10), child: product.image.isNotEmpty ? Image.network(product.image, fit: BoxFit.cover) : const Icon(Icons.diamond_outlined, size: 20, color: Colors.white10))
          ),
          title: Text(product.name.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5, color: AppTheme.polishedSilver)),
          subtitle: Text("₹${product.price.toStringAsFixed(0)}", style: const TextStyle(color: AppTheme.coolGrey, fontSize: 10)),
        ),
      ),
    );
  }
}
