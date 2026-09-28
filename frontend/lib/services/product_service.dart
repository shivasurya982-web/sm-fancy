import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import 'api_service.dart';

class ProductService {
  static List<ProductModel> _cachedAllProducts = [];
  static final Map<String, List<ProductModel>> _cachedByCategory = {};
  static DateTime? _lastFetchTime;
  static const Duration _cacheDuration = Duration(minutes: 5);

  static Future<List<ProductModel>> fetchProducts({String? search, String? category, String? excludeId, bool forceRefresh = false}) async {
    if (!forceRefresh && search == null && _cachedAllProducts.isNotEmpty && category == null && excludeId == null && _lastFetchTime != null && DateTime.now().difference(_lastFetchTime!) < _cacheDuration) {
      return _cachedAllProducts;
    }
    if (!forceRefresh && category != null && excludeId == null && _cachedByCategory.containsKey(category)) {
      return _cachedByCategory[category]!;
    }

    String query = '';
    final params = <String>[];
    if (search != null && search.isNotEmpty) params.add('search=${Uri.encodeComponent(search)}');
    if (category != null && category.isNotEmpty) params.add('category=${Uri.encodeComponent(category)}');
    if (excludeId != null && excludeId.isNotEmpty) params.add('excludeId=$excludeId');
    if (params.isNotEmpty) query = '?${params.join('&')}';

    final response = await ApiService.get('/products$query');
    List<ProductModel> results = [];
    if (response is Map<String, dynamic>) {
      final products = response['products'] as List<dynamic>? ?? [];
      results = products.map((json) => ProductModel.fromJson(json)).toList();
    } else if (response is List) {
      results = response.map((json) => ProductModel.fromJson(json)).toList();
    }

    if (search == null && category == null && excludeId == null) { 
      _cachedAllProducts = results; 
      _lastFetchTime = DateTime.now(); 
    } else if (category != null && search == null && excludeId == null) { 
      _cachedByCategory[category] = results; 
    }
    return results;
  }

  static Future<ProductModel> addProduct({
    required String name,
    required String description,
    required double price,
    required String category,
    List<Uint8List>? imagesBytes,
    List<String>? fileNames,
    String brand = '',
    int stock = 0,
    String? metalType,
    String? purity,
    String? weight,
    String? stoneInfo,
    double? makingCharge,
    String? hallmark,
    String? certification,
    bool isFeatured = false,
    bool isNewArrival = false,
    bool isTrending = false,
    bool isFlashSale = false,
  }) async {
    final uri = Uri.parse('${ApiService.baseUrl}/products');
    final request = http.MultipartRequest('POST', uri);
    final headers = await ApiService.authHeaders();
    request.headers.addAll(headers);
    request.headers.remove('Content-Type');

    request.fields['name'] = name;
    request.fields['description'] = description;
    request.fields['price'] = price.toString();
    request.fields['category'] = category;
    request.fields['brand'] = brand;
    request.fields['stock'] = stock.toString();
    if (metalType != null) request.fields['metalType'] = metalType;
    if (purity != null) request.fields['purity'] = purity;
    if (weight != null) request.fields['weight'] = weight;
    if (stoneInfo != null) request.fields['stoneInfo'] = stoneInfo;
    if (makingCharge != null) request.fields['makingCharge'] = makingCharge.toString();
    if (hallmark != null) request.fields['hallmark'] = hallmark;
    if (certification != null) request.fields['certification'] = certification;
    request.fields['isFeatured'] = isFeatured.toString();
    request.fields['isNewArrival'] = isNewArrival.toString();
    request.fields['isTrending'] = isTrending.toString();
    request.fields['isFlashSale'] = isFlashSale.toString();

    if (imagesBytes != null) {
      for (int i = 0; i < imagesBytes.length; i++) {
        request.files.add(http.MultipartFile.fromBytes('images', imagesBytes[i], filename: (fileNames != null && fileNames.length > i) ? fileNames[i] : 'product_$i.jpg'));
      }
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      _cachedAllProducts.clear();
      return ProductModel.fromJson(jsonDecode(response.body));
    }
    throw Exception(jsonDecode(response.body)['message'] ?? 'Failed to add product');
  }

  static Future<ProductModel> updateProduct(
    String id, {
    String? name,
    String? description,
    double? price,
    String? category,
    List<Uint8List>? imagesBytes,
    List<String>? fileNames,
    String? brand,
    int? stock,
    String? metalType,
    String? purity,
    String? weight,
    String? stoneInfo,
    double? makingCharge,
    String? hallmark,
    String? certification,
    bool? isFeatured,
    bool? isNewArrival,
    bool? isTrending,
    bool? isFlashSale,
  }) async {
    final uri = Uri.parse('${ApiService.baseUrl}/products/$id');
    final request = http.MultipartRequest('PUT', uri);
    final headers = await ApiService.authHeaders();
    request.headers.addAll(headers);
    request.headers.remove('Content-Type');

    if (name != null) request.fields['name'] = name;
    if (description != null) request.fields['description'] = description;
    if (price != null) request.fields['price'] = price.toString();
    if (category != null) request.fields['category'] = category;
    if (brand != null) request.fields['brand'] = brand;
    if (stock != null) request.fields['stock'] = stock.toString();
    if (metalType != null) request.fields['metalType'] = metalType;
    if (purity != null) request.fields['purity'] = purity;
    if (weight != null) request.fields['weight'] = weight;
    if (stoneInfo != null) request.fields['stoneInfo'] = stoneInfo;
    if (makingCharge != null) request.fields['makingCharge'] = makingCharge.toString();
    if (hallmark != null) request.fields['hallmark'] = hallmark;
    if (certification != null) request.fields['certification'] = certification;
    if (isFeatured != null) request.fields['isFeatured'] = isFeatured.toString();
    if (isNewArrival != null) request.fields['isNewArrival'] = isNewArrival.toString();
    if (isTrending != null) request.fields['isTrending'] = isTrending.toString();
    if (isFlashSale != null) request.fields['isFlashSale'] = isFlashSale.toString();

    if (imagesBytes != null) {
      for (int i = 0; i < imagesBytes.length; i++) {
        request.files.add(http.MultipartFile.fromBytes('images', imagesBytes[i], filename: (fileNames != null && fileNames.length > i) ? fileNames[i] : 'product_$i.jpg'));
      }
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      _cachedAllProducts.clear();
      return ProductModel.fromJson(jsonDecode(response.body));
    }
    throw Exception(jsonDecode(response.body)['message'] ?? 'Failed to update product');
  }

  static Future<void> deleteProduct(String id) async { await ApiService.delete('/products/$id'); _cachedAllProducts.clear(); }
  
  static Future<ProductModel> getProductById(String id) async {
    final response = await ApiService.get('/products/$id');
    return ProductModel.fromJson(response);
  }
}
