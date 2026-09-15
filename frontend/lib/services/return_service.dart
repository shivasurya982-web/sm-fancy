import 'api_service.dart';

class ReturnService {
  static Future<Map<String, dynamic>> requestReturn({
    required String orderId,
    required String reason,
    required String description,
    List<Map<String, dynamic>>? items,
  }) async {
    return await ApiService.post('/returns', {
      'orderId': orderId,
      'reason': reason,
      'description': description,
      'items': items,
    });
  }

  static Future<List<dynamic>> getMyReturns() async {
    return await ApiService.get('/returns/my');
  }
}
