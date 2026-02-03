import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Keys for secure storage
  static const String _adminAuthKey = 'admin_auth_data';
  static const String _deviceIdKey = 'device_id';

  // Hash PIN using SHA-256 with salt
  static String hashPin(String pin, String salt) {
    final bytes = utf8.encode(pin + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Generate salt for PIN hashing
  static String generateSalt() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  // Store admin authentication data
  Future<void> storeAdminAuth({
    required String adminUserId,
    required String shopId,
    required String deviceId,
    required String pin,
    bool biometricEnabled = false,
  }) async {
    final salt = generateSalt();
    final pinHash = hashPin(pin, salt);
    
    final authData = {
      'admin_user_id': adminUserId,
      'shop_id': shopId,
      'device_id': deviceId,
      'pin_hash': pinHash,
      'salt': salt,
      'biometric_enabled': biometricEnabled,
      'created_at': DateTime.now().toIso8601String(),
    };

    await _storage.write(
      key: _adminAuthKey,
      value: json.encode(authData),
    );
  }

  // Get admin authentication data
  Future<Map<String, dynamic>?> getAdminAuth() async {
    final authDataStr = await _storage.read(key: _adminAuthKey);
    if (authDataStr == null) return null;
    
    return json.decode(authDataStr);
  }

  // Verify admin PIN
  Future<bool> verifyAdminPin(String pin) async {
    final authData = await getAdminAuth();
    if (authData == null) return false;

    final storedHash = authData['pin_hash'];
    final salt = authData['salt'];
    final inputHash = hashPin(pin, salt);

    return storedHash == inputHash;
  }

  // Update biometric setting
  Future<void> updateBiometricEnabled(bool enabled) async {
    final authData = await getAdminAuth();
    if (authData == null) return;

    authData['biometric_enabled'] = enabled;
    await _storage.write(
      key: _adminAuthKey,
      value: json.encode(authData),
    );
  }

  // Check if admin is set up
  Future<bool> isAdminSetup() async {
    final authData = await getAdminAuth();
    return authData != null;
  }

  // Check if biometric is enabled
  Future<bool> isBiometricEnabled() async {
    final authData = await getAdminAuth();
    return authData?['biometric_enabled'] ?? false;
  }

  // Store device ID
  Future<void> storeDeviceId(String deviceId) async {
    await _storage.write(key: _deviceIdKey, value: deviceId);
  }

  // Get device ID
  Future<String?> getDeviceId() async {
    return await _storage.read(key: _deviceIdKey);
  }

  // Update last login time
  Future<void> updateLastLogin() async {
    final authData = await getAdminAuth();
    if (authData == null) return;

    authData['last_login_at'] = DateTime.now().toIso8601String();
    await _storage.write(
      key: _adminAuthKey,
      value: json.encode(authData),
    );
  }

  // Clear all admin data (logout/reset)
  Future<void> clearAdminAuth() async {
    await _storage.delete(key: _adminAuthKey);
  }

  // Store failed attempts and lock status
  Future<void> updateFailedAttempts(int attempts, DateTime? lockUntil) async {
    final authData = await getAdminAuth();
    if (authData == null) return;

    authData['failed_attempts'] = attempts;
    authData['locked_until'] = lockUntil?.toIso8601String();
    
    await _storage.write(
      key: _adminAuthKey,
      value: json.encode(authData),
    );
  }

  // Get failed attempts and lock status
  Future<Map<String, dynamic>> getSecurityStatus() async {
    final authData = await getAdminAuth();
    if (authData == null) {
      return {'failed_attempts': 0, 'is_locked': false};
    }

    final failedAttempts = authData['failed_attempts'] ?? 0;
    final lockedUntilStr = authData['locked_until'];
    
    bool isLocked = false;
    if (lockedUntilStr != null) {
      final lockedUntil = DateTime.parse(lockedUntilStr);
      isLocked = DateTime.now().isBefore(lockedUntil);
    }

    return {
      'failed_attempts': failedAttempts,
      'is_locked': isLocked,
      'locked_until': lockedUntilStr,
    };
  }
}