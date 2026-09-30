import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/wishlist_item.dart';
import 'api_service.dart';

class WishlistService {
  static List<WishlistItem> wishlistItems = [];
  static final ValueNotifier<List<WishlistItem>> wishlistNotifier = ValueNotifier([]);

  static Future<void> loadWishlist() async {
    // 1. Load from Local Storage (Instant)
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('local_wishlist');
      if (data != null) {
        final List decoded = jsonDecode(data);
        wishlistItems = decoded.map((json) => WishlistItem.fromJson(json)).toList();
        wishlistNotifier.value = List.from(wishlistItems);
      }
    } catch (e) {
      debugPrint('Wishlist local load error: $e');
    }

    // 2. Sync with server if logged in
    if (ApiService.isLoggedIn) {
      try {
        final profile = await ApiService.get('/auth/me');
        if (profile != null && profile['wishlist'] is List) {
          final List serverList = profile['wishlist'];
          final List<WishlistItem> items = [];
          for (var item in serverList) {
            if (item is Map<String, dynamic>) {
              items.add(WishlistItem.fromJson(item));
            }
          }
          if (items.isNotEmpty) {
            wishlistItems = items;
            await saveLocalWishlist();
            wishlistNotifier.value = List.from(wishlistItems);
          }
        }
      } catch (e) {
        debugPrint('Wishlist server load error: $e');
      }
    }
  }

  static Future<void> saveLocalWishlist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = jsonEncode(wishlistItems.map((item) => item.toJson()).toList());
      await prefs.setString('local_wishlist', data);
    } catch (_) {}
  }

  static Future<void> addToWishlist(WishlistItem item) async {
    final exists = wishlistItems.any((e) => e.productId == item.productId);
    if (!exists) {
      wishlistItems.add(item);
      wishlistNotifier.value = List.from(wishlistItems);
      await saveLocalWishlist();
      
      if (ApiService.isLoggedIn) {
        // Sync to server if your backend supports a specific wishlist POST route
        // For now we assume /auth/me update or similar
      }
    }
  }

  static Future<void> removeFromWishlist(String productId) async {
    wishlistItems.removeWhere((item) => item.productId == productId);
    wishlistNotifier.value = List.from(wishlistItems);
    await saveLocalWishlist();
    
    if (ApiService.isLoggedIn) {
      // Sync removal to server
    }
  }

  static bool isWishlisted(String productId) {
    return wishlistItems.any((item) => item.productId == productId);
  }
}
