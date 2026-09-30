class CouponModel {
  final String id;
  final String code;
  final String description;
  final String discountType; // 'percentage' | 'flat'
  final double discountValue;
  final double minOrderAmount;
  final double? maxDiscountAmount;
  final DateTime validUntil;
  final bool isActive;

  const CouponModel({
    required this.id,
    required this.code,
    required this.description,
    required this.discountType,
    required this.discountValue,
    this.minOrderAmount = 0,
    this.maxDiscountAmount,
    required this.validUntil,
    this.isActive = true,
  });

  factory CouponModel.fromJson(Map<String, dynamic> json) {
    return CouponModel(
      id: json['_id'] ?? '',
      code: json['code'] ?? '',
      description: json['description'] ?? '',
      discountType: json['discountType'] ?? 'percentage',
      discountValue: (json['discountValue'] ?? 0).toDouble(),
      minOrderAmount: (json['minOrderAmount'] ?? 0).toDouble(),
      maxDiscountAmount: json['maxDiscountAmount']?.toDouble(),
      validUntil: DateTime.tryParse(json['validUntil'] ?? '') ?? DateTime.now(),
      isActive: json['isActive'] ?? true,
    );
  }

  String get displayDiscount => discountType == 'percentage'
      ? '${discountValue.toInt()}% OFF'
      : '₹${discountValue.toInt()} OFF';
}
