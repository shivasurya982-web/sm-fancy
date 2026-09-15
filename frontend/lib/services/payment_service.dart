import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter/material.dart';
import 'api_service.dart';

class PaymentService {
  late Razorpay _razorpay;
  final Function(PaymentSuccessResponse) onSuccess;
  final Function(PaymentFailureResponse) onFailure;
  final Function(ExternalWalletResponse) onWallet;

  PaymentService({
    required this.onSuccess,
    required this.onFailure,
    required this.onWallet,
  }) {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, onSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, onFailure);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, onWallet);
  }

  void dispose() {
    _razorpay.clear();
  }

  static Future<Map<String, dynamic>> createOrder(double amount) async {
    final response = await ApiService.post('/payments/create-order', {
      'amount': amount,
      'currency': 'INR',
    });
    return response;
  }

  static Future<bool> verifyPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
    String? orderId,
  }) async {
    final response = await ApiService.post('/payments/verify', {
      'razorpay_order_id': razorpayOrderId,
      'razorpay_payment_id': razorpayPaymentId,
      'razorpay_signature': razorpaySignature,
      'orderId': orderId,
    });
    return response['verified'] ?? false;
  }

  void openCheckout({
    required String key,
    required double amount,
    required String orderId,
    required String name,
    required String description,
    required String email,
    required String contact,
    bool upiOnly = false,
  }) {
    var options = {
      'key': key,
      'amount': (amount * 100).toInt(), // amount in paise
      'name': 'FancyWorld',
      'order_id': orderId,
      'description': description,
      'prefill': {'contact': contact, 'email': email},
      if (upiOnly) 'method': {'upi': true},
      'external': {
        'wallets': ['paytm'],
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error: e');
    }
  }
}
