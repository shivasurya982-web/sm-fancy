class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String? image;
  final String type; // order, offer, promotion, system, chat
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? data;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    this.image,
    this.type = 'system',
    this.isRead = false,
    required this.createdAt,
    this.data,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      image: json['image'],
      type: json['type'] ?? 'system',
      isRead: json['isRead'] ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      data: json['data'],
    );
  }
}

class ReviewModel {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String productId;
  final double rating;
  final String? title;
  final String? review;
  final List<String> images;
  final bool isVerifiedPurchase;
  final DateTime createdAt;

  const ReviewModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.productId,
    required this.rating,
    this.title,
    this.review,
    this.images = const [],
    this.isVerifiedPurchase = false,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    final user = json['userId'];
    return ReviewModel(
      id: json['_id'] ?? '',
      userId: user is Map ? user['_id'] ?? '' : user ?? '',
      userName: user is Map ? user['name'] ?? 'User' : 'User',
      userAvatar: user is Map ? user['avatar'] : null,
      productId: json['productId'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      title: json['title'],
      review: json['review'],
      images: List<String>.from(json['images'] ?? []),
      isVerifiedPurchase: json['isVerifiedPurchase'] ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}
