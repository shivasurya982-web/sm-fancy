import 'product_model.dart';

class OrderItemProduct {
  final String productId;
  final String name;
  final double price;
  final int quantity;
  final String image;

  OrderItemProduct({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    this.image = '',
  });

  factory OrderItemProduct.fromJson(Map<String, dynamic> json) {
    return OrderItemProduct(
      productId: json['product']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      image: normalizeAssetPath(json['image']?.toString() ?? ''),
    );
  }
}

class OrderItem {
  final String orderId;
  final String orderNumber;
  final List<OrderItemProduct> items;
  final double subtotal;
  final double shipping;
  final double total;
  String status;
  final Map<String, String> shippingAddress;
  final String paymentMethod;
  final String? paymentStatus;
  final String? upiTransactionId;
  final DateTime date;
  final String customerName;
  final Map<String, double>? customerLiveLocation;

  OrderItem({
    required this.orderId,
    required this.orderNumber,
    required this.items,
    required this.subtotal,
    required this.shipping,
    required this.total,
    required this.status,
    required this.shippingAddress,
    required this.paymentMethod,
    this.paymentStatus,
    this.upiTransactionId,
    required this.date,
    this.customerName = '',
    this.customerLiveLocation,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List? ?? [];
    final itemsList = rawItems
        .map((item) => OrderItemProduct.fromJson(item))
        .toList();

    final addrJson = (json['address'] ?? json['shippingAddress']) as Map? ?? {};
    final address = <String, String>{
      'name':
          addrJson['fullName']?.toString() ??
          addrJson['name']?.toString() ??
          '',
      'phone': addrJson['phone']?.toString() ?? '',
      'street':
          addrJson['addressLine1']?.toString() ??
          addrJson['street']?.toString() ??
          '',
      'city': addrJson['city']?.toString() ?? '',
      'state': addrJson['state']?.toString() ?? '',
      'pincode':
          addrJson['pincode']?.toString() ??
          addrJson['zipCode']?.toString() ??
          '',
    };

    String custName = address['name'] ?? '';
    if (json['userId'] is Map) {
      custName =
          json['userId']['name']?.toString() ??
          json['userId']['fullName']?.toString() ??
          custName;
    }

    DateTime createdDate;
    try {
      createdDate = DateTime.parse(
        json['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
      );
    } catch (_) {
      createdDate = DateTime.now();
    }

    Map<String, double>? liveLocation;
    if (json['customerLiveLocation'] != null) {
      liveLocation = {
        'latitude': (json['customerLiveLocation']['latitude'] as num)
            .toDouble(),
        'longitude': (json['customerLiveLocation']['longitude'] as num)
            .toDouble(),
      };
    }

    return OrderItem(
      orderId: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      orderNumber: json['orderNumber']?.toString() ?? 'FW0000',
      items: itemsList,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      shipping: (json['shipping'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      status: json['status']?.toString() ?? 'Placed',
      shippingAddress: address,
      paymentMethod: json['paymentMethod']?.toString() ?? 'Cash on Delivery',
      paymentStatus: json['paymentStatus']?.toString(),
      upiTransactionId: json['upiTransactionId']?.toString() ?? json['upiReferenceNo']?.toString(),
      date: createdDate,
      customerName: custName,
      customerLiveLocation: liveLocation,
    );
  }
}
