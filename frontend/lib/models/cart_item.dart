import 'product_model.dart';

class CartItem {
  final String productId;
  final String name;
  final String image;
  final double price;
  int quantity;

  CartItem({
    required this.productId,
    required this.name,
    required this.image,
    required this.price,
    this.quantity = 1,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    // If populated product comes from server
    if (json['product'] is Map) {
      final prodJson = json['product'] as Map<String, dynamic>;
      final prod = ProductModel.fromJson(prodJson);
      return CartItem(
        productId: prod.id,
        name: prod.name,
        image: prod.image,
        price: prod.price,
        quantity: json['quantity'] as int? ?? 1,
      );
    }

    // Otherwise flat fields
    return CartItem(
      productId: json['productId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      image: normalizeAssetPath(json['image']?.toString() ?? ''),
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      quantity: json['quantity'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'name': name,
      'image': image,
      'price': price,
      'quantity': quantity,
    };
  }
}
