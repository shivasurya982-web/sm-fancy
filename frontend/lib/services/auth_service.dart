import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
class AuthService {
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final response = await ApiService.post(
      '/auth/login',
      {
        'email': email,
        'password': password,
      },
    );

    if (response['token'] != null) {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('token', response['token']);

      await prefs.setString(
        'userId',
        response['user']['id'].toString(),
      );

      await prefs.setString(
        'userRole',
        response['user']['role'] ?? 'user',
      );

      await prefs.setString(
        'userName',
        response['user']['name'] ?? '',
      );

      await prefs.setString(
        'userEmail',
        response['user']['email'] ?? '',
      );
    }

    await ApiService.init();

    return response;
  }

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String recoveryHint,
    String role = 'user',
  }) async {
    final response = await ApiService.post(
      '/auth/register',
      {
        'name': name,
        'email': email,
        'password': password,
        'recoveryHint': recoveryHint,
        'role': role,
      },
    );

    if (response['token'] != null) {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('token', response['token']);

      await prefs.setString(
        'userId',
        response['user']['id'].toString(),
      );

      await prefs.setString(
        'userRole',
        response['user']['role'] ?? 'user',
      );

      await prefs.setString(
        'userName',
        response['user']['name'] ?? '',
      );

      await prefs.setString(
        'userEmail',
        response['user']['email'] ?? '',
      );
    }

    await ApiService.init();

    return response;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('token');
    await prefs.remove('userId');
    await prefs.remove('userRole');
    await prefs.remove('userName');
    await prefs.remove('userEmail');

    await ApiService.init();
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('token');
  }

  static Future<List<dynamic>> getUsers() async {
    return await ApiService.get('/auth/users');
  }

  static Future<void> changePassword(String currentPassword, String newPassword) async {
    await ApiService.put('/auth/change-password', {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }
}
