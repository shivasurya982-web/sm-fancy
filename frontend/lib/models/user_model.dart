class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String avatar;
  final String role;
  final int loyaltyPoints;
  final double wallet;
  final bool isPremium;
  final bool isVerified;
  final String language;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone = '',
    this.avatar = '',
    this.role = 'user',
    this.loyaltyPoints = 0,
    this.wallet = 0.0,
    this.isPremium = false,
    this.isVerified = false,
    this.language = 'en',
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      avatar: json['avatar'] ?? '',
      role: json['role'] ?? 'user',
      loyaltyPoints: json['loyaltyPoints'] ?? 0,
      wallet: (json['wallet'] ?? 0).toDouble(),
      isPremium: json['isPremium'] ?? false,
      isVerified: json['isVerified'] ?? false,
      language: json['language'] ?? 'en',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'avatar': avatar,
    'role': role,
    'loyaltyPoints': loyaltyPoints,
    'wallet': wallet,
    'isPremium': isPremium,
    'isVerified': isVerified,
    'language': language,
  };

  UserModel copyWith({
    String? name, String? phone, String? avatar, String? language,
    int? loyaltyPoints, double? wallet, bool? isPremium,
  }) {
    return UserModel(
      id: id, email: email, role: role, isVerified: isVerified,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
      language: language ?? this.language,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      wallet: wallet ?? this.wallet,
      isPremium: isPremium ?? this.isPremium,
    );
  }
}
