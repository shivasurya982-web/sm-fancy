import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class UserService {
  static Future<void> saveUser({
    required String name,
    required String email,
    required String phone,
    String? profileImage,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('userName', name);
    await prefs.setString('userEmail', email);
    await prefs.setString('userPhone', phone);
    if (profileImage != null) {
      await prefs.setString('userProfileImage', profileImage);
    }

    // Update ApiService fields
    ApiService.currentUserName = name;
    ApiService.currentUserEmail = email;
  }

  static Future<String> getName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userName') ?? ApiService.currentUserName;
  }

  static Future<String> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userEmail') ?? ApiService.currentUserEmail;
  }

  static Future<String> getPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userPhone') ?? '';
  }

  static Future<String?> getProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userProfileImage');
  }

  static Future<Map<String, dynamic>> getProfile() async {
    return await ApiService.get('/auth/me');
  }

  // Recently Viewed Logic
  static Future<void> addToRecentlyViewed(String productId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> viewed = prefs.getStringList('recently_viewed') ?? [];
    
    // Remove if already exists to move to top
    viewed.remove(productId);
    viewed.insert(0, productId);
    
    // Limit to 10 items
    if (viewed.length > 10) {
      viewed = viewed.sublist(0, 10);
    }
    
    await prefs.setStringList('recently_viewed', viewed);
  }

  static Future<List<String>> getRecentlyViewed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('recently_viewed') ?? [];
  }
}
