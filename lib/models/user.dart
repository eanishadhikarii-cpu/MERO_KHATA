class User {
  final String userId;
  final String? phone;
  final String? email;
  final String primaryLoginMethod;
  final String? shopId;
  final String? deviceId;
  final String? shopName;
  final String? ownerName;
  final String? shopType;
  final String? currency;
  final String? gstNumber;
  final String? appPin;
  final bool isSetupCompleted;
  final DateTime createdAt;

  User({
    required this.userId,
    this.phone,
    this.email,
    required this.primaryLoginMethod,
    this.shopId,
    this.deviceId,
    this.shopName,
    this.ownerName,
    this.shopType,
    this.currency,
    this.gstNumber,
    this.appPin,
    this.isSetupCompleted = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'phone': phone,
      'email': email,
      'primary_login_method': primaryLoginMethod,
      'shop_id': shopId,
      'device_id': deviceId,
      'shop_name': shopName,
      'owner_name': ownerName,
      'shop_type': shopType,
      'currency': currency,
      'gst_number': gstNumber,
      'app_pin': appPin,
      'is_setup_completed': isSetupCompleted ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      userId: map['user_id'],
      phone: map['phone'],
      email: map['email'],
      primaryLoginMethod: map['primary_login_method'],
      shopId: map['shop_id'],
      deviceId: map['device_id'],
      shopName: map['shop_name'],
      ownerName: map['owner_name'],
      shopType: map['shop_type'],
      currency: map['currency'],
      gstNumber: map['gst_number'],
      appPin: map['app_pin'],
      isSetupCompleted: (map['is_setup_completed'] ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  User copyWith({
    String? shopName,
    String? ownerName,
    String? shopType,
    String? currency,
    String? gstNumber,
    String? appPin,
    bool? isSetupCompleted,
  }) {
    return User(
      userId: userId,
      phone: phone,
      email: email,
      primaryLoginMethod: primaryLoginMethod,
      shopId: shopId,
      deviceId: deviceId,
      shopName: shopName ?? this.shopName,
      ownerName: ownerName ?? this.ownerName,
      shopType: shopType ?? this.shopType,
      currency: currency ?? this.currency,
      gstNumber: gstNumber ?? this.gstNumber,
      appPin: appPin ?? this.appPin,
      isSetupCompleted: isSetupCompleted ?? this.isSetupCompleted,
      createdAt: createdAt,
    );
  }
}