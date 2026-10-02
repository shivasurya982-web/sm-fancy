import 'api_service.dart';
import 'package:flutter/foundation.dart';

class ReviewModel {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String productId;
  final String? orderId;
  final int rating;
  final String title;
  final String review;
  final List<String> images;
  final bool isVerifiedPurchase;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.productId,
    this.orderId,
    required this.rating,
    required this.title,
    required this.review,
    this.images = const [],
    required this.isVerifiedPurchase,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    final user = json['userId'];
    String name = 'Customer';
    String? avatar;
    String uId = '';

    if (user is Map) {
      name = user['name'] ?? 'Customer';
      avatar = user['avatar'];
      uId = user['_id'] ?? '';
    } else if (user is String) {
      uId = user;
    }

    List<String> reviewImages = [];
    if (json['images'] != null && json['images'] is List) {
      reviewImages = List<String>.from(json['images']);
    }

    return ReviewModel(
      id: json['_id'] ?? '',
      userId: uId,
      userName: name,
      userAvatar: avatar,
      productId: json['productId']?.toString() ?? '',
      orderId: json['orderId']?.toString(),
      rating: (json['rating'] as num?)?.toInt() ?? 5,
      title: json['title'] ?? '',
      review: json['review'] ?? '',
      images: reviewImages,
      isVerifiedPurchase: json['isVerifiedPurchase'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}

class ReviewService {
  static Future<Map<String, dynamic>> fetchReviews(String productId) async {
    try {
      final res = await ApiService.get('/reviews/$productId');
      if (res is Map) {
        final List<dynamic> list = res['reviews'] ?? [];
        final reviews = list.map((json) => ReviewModel.fromJson(json)).toList();
        final int total = res['total'] ?? 0;
        return {'reviews': reviews, 'total': total, 'breakdown': res['breakdown']};
      }
    } catch (e) {
      debugPrint('Fetch Reviews Error: $e');
    }
    return {'reviews': <ReviewModel>[], 'total': 0};
  }

  static Future<Map<String, dynamic>> checkEligibility(String productId) async {
    try {
      final res = await ApiService.get('/reviews/check-eligible/$productId');
      if (res is Map<String, dynamic>) return res;
      if (res is Map) return Map<String, dynamic>.from(res);
    } catch (_) {}
    return {'canReview': false};
  }

  static Future<ReviewModel> submitReview({
    required String productId,
    String? orderId,
    required int rating,
    String? title,
    required String review,
    List<String>? images,
  }) async {
    final res = await ApiService.post('/reviews', {
      'productId': productId,
      'orderId': orderId,
      'rating': rating,
      'title': title,
      'review': review,
      'images': images ?? [],
    });
    return ReviewModel.fromJson(res);
  }
}
