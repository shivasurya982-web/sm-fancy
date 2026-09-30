import 'api_service.dart';

class CategoryService {
  static List<dynamic> _cachedCategories = [];

  static List<dynamic> get cachedCategories => _cachedCategories;

  static Future<List<dynamic>> fetchCategories({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedCategories.isNotEmpty) {
      return _cachedCategories;
    }
    
    final response = await ApiService.get('/categories');
    if (response is List) {
      _cachedCategories = response;
    } else {
      _cachedCategories = [];
    }
    return _cachedCategories;
  }

  static Future<void> addCategory(String name, String? image) async {
    await ApiService.post('/categories', {
      'name': name,
      'image': image ?? '',
    });
    _cachedCategories.clear();
  }

  static Future<void> updateCategory(String id, String name, String? image) async {
    await ApiService.put('/categories/$id', {
      'name': name,
      'image': image ?? '',
    });
    _cachedCategories.clear();
  }

  static Future<void> deleteCategory(String id) async {
    await ApiService.delete('/categories/$id');
    _cachedCategories.clear();
  }
}
