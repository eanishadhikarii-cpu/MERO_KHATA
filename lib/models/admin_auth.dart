class AdminAuth {
  final String adminUserId;
  final String shopId;
  final String deviceId;
  final String pinHash;
  final bool biometricEnabled;
  final DateTime? lastLoginAt;
  final int failedAttempts;
  final DateTime? lockedUntil;

  AdminAuth({
    required this.adminUserId,
    required this.shopId,
    required this.deviceId,
    required this.pinHash,
    this.biometricEnabled = false,
    this.lastLoginAt,
    this.failedAttempts = 0,
    this.lockedUntil,
  });

  Map<String, dynamic> toMap() {
    return {
      'admin_user_id': adminUserId,
      'shop_id': shopId,
      'device_id': deviceId,
      'pin_hash': pinHash,
      'biometric_enabled': biometricEnabled ? 1 : 0,
      'last_login_at': lastLoginAt?.toIso8601String(),
      'failed_attempts': failedAttempts,
      'locked_until': lockedUntil?.toIso8601String(),
    };
  }

  factory AdminAuth.fromMap(Map<String, dynamic> map) {
    return AdminAuth(
      adminUserId: map['admin_user_id'],
      shopId: map['shop_id'],
      deviceId: map['device_id'],
      pinHash: map['pin_hash'],
      biometricEnabled: (map['biometric_enabled'] ?? 0) == 1,
      lastLoginAt: map['last_login_at'] != null 
          ? DateTime.parse(map['last_login_at']) 
          : null,
      failedAttempts: map['failed_attempts'] ?? 0,
      lockedUntil: map['locked_until'] != null 
          ? DateTime.parse(map['locked_until']) 
          : null,
    );
  }

  AdminAuth copyWith({
    DateTime? lastLoginAt,
    int? failedAttempts,
    DateTime? lockedUntil,
    bool? biometricEnabled,
  }) {
    return AdminAuth(
      adminUserId: adminUserId,
      shopId: shopId,
      deviceId: deviceId,
      pinHash: pinHash,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      lockedUntil: lockedUntil,
    );
  }

  bool get isLocked {
    if (lockedUntil == null) return false;
    return DateTime.now().isBefore(lockedUntil!);
  }
}