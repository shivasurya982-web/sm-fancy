import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item.dart';
import '../models/product_model.dart';
import 'api_service.dart';

class CartService {
  static List<CartItem> cartItems = [];
  static final ValueNotifier<int> cartCount = ValueNotifier<int>(0);
  static final ValueNotifier<List<CartItem>> cartItemsNotifier = ValueNotifier([]);

  static double get cartTotal {
    double total = 0;
    for (var item in cartItems) {
      total += item.price * item.quantity;
    }
    return total;
  }

  static Future<void> loadLocalCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('local_cart');
      if (data != null) {
        final List decoded = jsonDecode(data);
        cartItems = decoded.map((json) => CartItem.fromJson(json)).toList();
        _updateNotifiers();
      }
    } catch (e) {
      debugPrint('Cart local load error: $e');
    }
  }

  static Future<void> saveLocalCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = jsonEncode(cartItems.map((item) => item.toJson()).toList());
      await prefs.setString('local_cart', data);
    } catch (_) {}
  }

  static Future<List<CartItem>> fetchCart() async {
    // 1. Always load local first for speed
    await loadLocalCart();

    // 2. Sync with server if logged in
    if (ApiService.isLoggedIn) {
      try {
        final response = await ApiService.get('/cart');
        if (response != null) {
          List<dynamic>? list;
          if (response is Map && response['items'] is List) {
            list = response['items'] as List;
          } else if (response is List) {
            list = response;
          }
          
          if (list != null && list.isNotEmpty) {
            cartItems = list.map((json) => CartItem.fromJson(json)).toList();
            await saveLocalCart(); // Cache server state locally
            _updateNotifiers();
          }
        }
      } catch (e) {
        debugPrint('Error fetching cart from server: $e');
      }
    }
    return cartItems;
  }

  static Future<void> addToCart(ProductModel product, {int quantity = 1}) async {
    // 1. Local Update (Instant)
    final idx = cartItems.indexWhere((item) => item.productId == product.id);
    if (idx > -1) {
      cartItems[idx].quantity += quantity;
    } else {
      cartItems.add(CartItem(
        productId: product.id,
        name: product.name,
        image: product.image,
        price: product.price,
        quantity: quantity,
      ));
    }
    _updateNotifiers();
    await saveLocalCart();

    // 2. Server Sync
    if (ApiService.isLoggedIn) {
      try {
        await ApiService.post('/cart', {
          'productId': product.id,
          'quantity': quantity,
        });
        // We don't necessarily need to refresh everything here if local is correct
      } catch (e) {
        debugPrint('Sync to cart failed: $e');
      }
    }
  }

  static Future<void> updateQuantity(String productId, int quantity) async {
    final idx = cartItems.indexWhere((item) => item.productId == productId);
    if (idx > -1) {
      cartItems[idx].quantity = quantity;
      _updateNotifiers();
      await saveLocalCart();
    }

    if (ApiService.isLoggedIn) {
      try {
        await ApiService.put('/cart/$productId', {'quantity': quantity});
      } catch (e) {
        debugPrint('Error updating quantity on server: $e');
      }
    }
  }

  static Future<void> removeFromCart(String productId) async {
    cartItems.removeWhere((item) => item.productId == productId);
    _updateNotifiers();
    await saveLocalCart();

    if (ApiService.isLoggedIn) {
      try {
        await ApiService.delete('/cart/$productId');
      } catch (e) {
        debugPrint('Error removing from cart on server: $e');
      }
    }
  }

  static Future<void> clearCart() async {
    cartItems = [];
    _updateNotifiers();
    await saveLocalCart();

    if (ApiService.isLoggedIn) {
      try {
        await ApiService.delete('/cart');
      } catch (e) {
        debugPrint('Error clearing cart on server: $e');
      }
    }
  }

  static void _updateNotifiers() {
    cartItemsNotifier.value = List.from(cartItems);
    cartCount.value = cartItems.fold(0, (sum, item) => sum + item.quantity);
  }
}
