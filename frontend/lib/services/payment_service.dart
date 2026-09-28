import 'api_service.dart';

class PaymentService {
  /// Initiates order creation and returns metadata for Dynamic UPI QR.
  static Future<Map<String, dynamic>> initiateUPIDynamicQR({
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic> address,
    String? couponCode,
    double shipping = 0,
  }) async {
    final response = await ApiService.post('/payments/create-order', {
      'items': items,
      'address': address,
      'couponCode': couponCode,
      'shipping': shipping,
    });
    return response;
  }

  /// Polls the backend for the actual payment status (verified via webhook).
  static Future<Map<String, dynamic>> checkPaymentStatus(String orderId) async {
    final response = await ApiService.get('/payments/status/$orderId');
    return response ?? {};
  }
}
