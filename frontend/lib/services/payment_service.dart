import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class PaymentService {
  static const String _pendingOrderKey = 'last_pending_payment_order_id';

  /// Initiates order creation and calls Payment Server.
  static Future<Map<String, dynamic>> initiateUPIDynamicQR({
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic> address,
    String? couponCode,
    double shipping = 0,
    String returnUrl = 'fancyworld://payment-done',
  }) async {
    final response = await ApiService.post('/payments/create-order', {
      'items': items,
      'address': address,
      'couponCode': couponCode,
      'shipping': shipping,
      'returnUrl': returnUrl,
    });
    return response;
  }

  /// Polls backend for actual verified payment status (S2S check).
  static Future<Map<String, dynamic>> checkPaymentStatus(String orderId) async {
    final response = await ApiService.get('/payments/orders/$orderId/payment-status');
    return response ?? {};
  }

  /// Persists pending order ID locally to handle app killed / reopened
  static Future<void> savePendingOrderId(String orderId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingOrderKey, orderId);
  }

  /// Gets stored pending order ID
  static Future<String?> getPendingOrderId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_pendingOrderKey);
  }

  /// Clears pending order ID
  static Future<void> clearPendingOrderId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingOrderKey);
  }
}
