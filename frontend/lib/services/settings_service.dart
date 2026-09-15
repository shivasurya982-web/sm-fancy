import 'api_service.dart';

class SettingsService {
  static Map<String, dynamic>? _cachedSettings;

  static Future<Map<String, dynamic>> getSettings() async {
    if (_cachedSettings != null) return _cachedSettings!;
    
    try {
      final response = await ApiService.get('/settings');
      _cachedSettings = response;
      return response;
    } catch (e) {
      // Fallback defaults
      return {
        'onboardingBanners': [
          {
            'title': 'Elegance in\nEvery Detail',
            'description': 'Discover carefully selected jewellery crafted with precision and luxury in mind.',
            'image': 'assets/images/logo.png'
          }
        ],
        'splashTagline': 'Luxury that speaks. Elegance that stays.'
      };
    }
  }

  static Future<void> updateSettings(Map<String, dynamic> settings) async {
    await ApiService.post('/settings', settings);
    _cachedSettings = settings;
  }
}
