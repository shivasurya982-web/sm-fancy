import 'api_service.dart';

class AdminUserService {
  static Future<List<dynamic>> fetchUsers() async {
    final response = await ApiService.get('/users');

    if (response is List) {
      return response;
    }

    if (response is Map<String, dynamic>) {
      return response['users'] ?? [];
    }

    return [];
  }

  static Future<Map<String, dynamic>> getUser(String id) async {
    final response = await ApiService.get('/users/$id');
    return response;
  }

  static Future<void> deleteUser(String id) async {
    await ApiService.delete('/users/$id');
  }
}
