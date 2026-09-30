import '../models/order_item.dart';
import 'api_service.dart';
import 'package:flutter/foundation.dart';

class OrderService {
  static List<OrderItem> orders = [];

  static Future<List<OrderItem>> fetchMyOrders() async {
    try {
      final response = await ApiService.get('/orders');
      if (response is Map &&
          response['orders'] != null &&
          response['orders'] is List) {
        orders = (response['orders'] as List)
            .map((json) => OrderItem.fromJson(json))
            .toList();
      }
    } catch (e) {
      debugPrint('Fetch My Orders Error: $e');
    }
    return orders;
  }

  static Future<List<OrderItem>> fetchAllOrders() async {
    try {
      final response = await ApiService.get('/orders/admin/all');
      if (response is Map &&
          response['orders'] != null &&
          response['orders'] is List) {
        return (response['orders'] as List)
            .map((json) => OrderItem.fromJson(json))
            .toList();
      }
    } catch (e) {
      debugPrint('Fetch All Orders Error: $e');
    }
    return [];
  }

  static Future<OrderItem> placeOrder({
    required Map<String, dynamic> shippingAddress,
    required String paymentMethod,
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required double shipping,
    double tax = 0,
    required double total,
    Map<String, double>? customerLiveLocation,
  }) async {
    final response = await ApiService.post(
      '/orders',
      {
        'address': shippingAddress,
        'paymentMethod': paymentMethod,
        'items': items,
        'subtotal': subtotal,
        'shipping': shipping,
        'tax': tax,
        'total': total,
        'customerLiveLocation': customerLiveLocation,
      },
    );

    final order = OrderItem.fromJson(response);
    orders.insert(0, order);
    return order;
  }

  static Future<OrderItem> updateOrderStatus(
    String orderId,
    String status,
  ) async {
    final response = await ApiService.put(
      '/orders/admin/$orderId/status',
      {
        'status': status,
      },
    );
    final updated = OrderItem.fromJson(response);
    final idx = orders.indexWhere((o) => o.orderId == orderId);
    if (idx != -1) {
      orders[idx].status = status;
    }
    return updated;
  }

  static Future<OrderItem> getOrderById(String id) async {
    final response = await ApiService.get('/orders/$id');
    return OrderItem.fromJson(response);
  }

  static Future<void> deleteOrder(String orderId) async {
    await ApiService.delete('/orders/$orderId');
    orders.removeWhere((o) => o.orderId == orderId);
  }
}
