String normalizeAssetPath(String path) {
  if (path.startsWith('http') || path.isEmpty) return path;
  return path.startsWith('assets/') ? path.substring('assets/'.length) : path;
}

class ProductModel {
  final String id;
  final String name;
  final String image; 
  final List<String> images; 
  final String category;
  final double price;
  final String description;
  final double discount;
  final String brand;
  final int stock;

  // Rating & Reviews
  final double averageRating;
  final int numReviews;

  // Jewelry Specific
  final String? metalType;
  final String? purity;
  final String? weight;
  final String? stoneInfo;
  final double? makingCharge;
  final String? hallmark;
  final String? certification;
  final String? careInstructions;
  final String? authenticityInfo;

  final bool isFeatured;
  final bool isNewArrival;
  final bool isTrending;
  final bool isFlashSale;

  ProductModel({
    required this.id,
    required this.name,
    required this.image,
    this.images = const [],
    required this.category,
    required this.price,
    required this.description,
    this.discount = 0,
    this.brand = '',
    this.stock = 0,
    this.averageRating = 5.0,
    this.numReviews = 0,
    this.metalType,
    this.purity,
    this.weight,
    this.stoneInfo,
    this.makingCharge,
    this.hallmark,
    this.certification,
    this.careInstructions,
    this.authenticityInfo,
    this.isFeatured = false,
    this.isNewArrival = false,
    this.isTrending = false,
    this.isFlashSale = false,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    List<String> imagesList = [];
    if (json['images'] != null) {
      imagesList = List<String>.from(json['images']).map(normalizeAssetPath).toList();
    }

    return ProductModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      image: normalizeAssetPath(json['imageUrl']?.toString() ?? json['image']?.toString() ?? ''),
      images: imagesList,
      category: json['category']?.toString() ?? 'Other',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      description: json['description']?.toString() ?? '',
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      brand: json['brand']?.toString() ?? '',
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 5.0,
      numReviews: (json['numReviews'] as num?)?.toInt() ?? 0,
      metalType: json['metalType'],
      purity: json['purity'],
      weight: json['weight'],
      stoneInfo: json['stoneInfo'],
      makingCharge: (json['makingCharge'] as num?)?.toDouble(),
      hallmark: json['hallmark'],
      certification: json['certification'],
      careInstructions: json['careInstructions'],
      authenticityInfo: json['authenticityInfo'],
      isFeatured: json['isFeatured'] ?? false,
      isNewArrival: json['isNewArrival'] ?? false,
      isTrending: json['isTrending'] ?? false,
      isFlashSale: json['isFlashSale'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imageUrl': image,
      'images': images,
      'category': category,
      'price': price,
      'description': description,
      'discount': discount,
      'brand': brand,
      'stock': stock,
      'averageRating': averageRating,
      'numReviews': numReviews,
      'metalType': metalType,
      'purity': purity,
      'weight': weight,
      'stoneInfo': stoneInfo,
      'makingCharge': makingCharge,
      'hallmark': hallmark,
      'certification': certification,
      'careInstructions': careInstructions,
      'authenticityInfo': authenticityInfo,
      'isFeatured': isFeatured,
      'isNewArrival': isNewArrival,
      'isTrending': isTrending,
      'isFlashSale': isFlashSale,
    };
  }
}
