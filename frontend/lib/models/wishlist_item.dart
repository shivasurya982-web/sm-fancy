import 'product_model.dart';

class WishlistItem {
  final String productId;
  final String name;
  final String image;
  final double price;

  WishlistItem({
    required this.productId,
    required this.name,
    required this.image,
    required this.price,
  });

  factory WishlistItem.fromJson(Map<String, dynamic> json) {
    // Handle populated product from server
    if (json.containsKey('name') && (json.containsKey('_id') || json.containsKey('id'))) {
        return WishlistItem(
            productId: (json['_id'] ?? json['id'])?.toString() ?? '',
            name: json['name']?.toString() ?? '',
            image: normalizeAssetPath(json['imageUrl']?.toString() ?? json['image']?.toString() ?? ''),
            price: (json['price'] as num?)?.toDouble() ?? 0.0,
        );
    }

    return WishlistItem(
      productId: json['productId']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      image: normalizeAssetPath(json['image']?.toString() ?? ''),
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'name': name,
      'image': image,
      'price': price,
    };
  }
}
