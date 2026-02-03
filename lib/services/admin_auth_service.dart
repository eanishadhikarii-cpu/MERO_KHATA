import 'package:local_auth/local_auth.dart';
import '../models/user.dart';
import 'secure_storage_service.dart';
import 'biometric_service.dart';

class AdminAuthService {
  final SecureStorageService _secureStorage = SecureStorageService();
  final BiometricService _biometricService = BiometricService();

  static const int maxFailedAttempts = 3;
  static const int lockDurationMinutes = 1; // 1 minute lock

  // Setup admin authentication (first time)
  Future<AdminAuthResult> setupAdminAuth({
    required User user,
    required String adminPin,
    bool enableBiometric = false,
  }) async {
    try {
      // Validate user is eligible for admin access
      if (!user.isSetupCompleted) {
        return AdminAuthResult(
          success: false,
          message: 'User setup must be completed first',
        );
      }

      // Generate device ID if not exists
      String? deviceId = await _secureStorage.getDeviceId();
      deviceId ??= DateTime.now().millisecondsSinceEpoch.toString();
      await _secureStorage.storeDeviceId(deviceId);

      // Store admin authentication data
      await _secureStorage.storeAdminAuth(
        adminUserId: user.userId,
        shopId: user.shopId ?? 'default_shop',
        deviceId: deviceId,
        pin: adminPin,
        biometricEnabled: enableBiometric,
      );

      return AdminAuthResult(
        success: true,
        message: 'Admin authentication setup successful',
      );
    } catch (e) {
      return AdminAuthResult(
        success: false,
        message: 'Setup failed: ${e.toString()}',
      );
    }
  }

  // Authenticate admin with PIN
  Future<AdminAuthResult> authenticateWithPin(String pin) async {
    try {
      // Check if admin is set up
      final isSetup = await _secureStorage.isAdminSetup();
      if (!isSetup) {
        return AdminAuthResult(
          success: false,
          message: 'Admin authentication not set up',
        );
      }

      // Check security status (failed attempts and lock)
      final securityStatus = await _secureStorage.getSecurityStatus();
      if (securityStatus['is_locked']) {
        return AdminAuthResult(
          success: false,
          message: 'Admin panel is temporarily locked. Try again later.',
          isLocked: true,
        );
      }

      // Verify PIN
      final isValidPin = await _secureStorage.verifyAdminPin(pin);
      
      if (isValidPin) {
        // Reset failed attempts on successful login
        await _secureStorage.updateFailedAttempts(0, null);
        await _secureStorage.updateLastLogin();
        
        return AdminAuthResult(
          success: true,
          message: 'Admin authentication successful',
        );
      } else {
        // Increment failed attempts
        final currentAttempts = securityStatus['failed_attempts'] + 1;
        DateTime? lockUntil;
        
        if (currentAttempts >= maxFailedAttempts) {
          lockUntil = DateTime.now().add(
            Duration(minutes: lockDurationMinutes),
          );
        }
        
        await _secureStorage.updateFailedAttempts(currentAttempts, lockUntil);
        
        String message = 'Invalid PIN';
        if (currentAttempts == maxFailedAttempts - 1) {
          message = 'Invalid PIN. 1 attempt remaining before lock.';
        } else if (currentAttempts >= maxFailedAttempts) {
          message = 'Too many failed attempts. Admin panel locked for $lockDurationMinutes minute(s).';
        }
        
        return AdminAuthResult(
          success: false,
          message: message,
          failedAttempts: currentAttempts,
          isLocked: lockUntil != null,
        );
      }
    } catch (e) {
      return AdminAuthResult(
        success: false,
        message: 'Authentication error: ${e.toString()}',
      );
    }
  }

  // Authenticate admin with biometrics
  Future<AdminAuthResult> authenticateWithBiometrics() async {
    try {
      // Check if admin is set up
      final isSetup = await _secureStorage.isAdminSetup();
      if (!isSetup) {
        return AdminAuthResult(
          success: false,
          message: 'Admin authentication not set up',
        );
      }

      // Check if biometric is enabled
      final isBiometricEnabled = await _secureStorage.isBiometricEnabled();
      if (!isBiometricEnabled) {
        return AdminAuthResult(
          success: false,
          message: 'Biometric authentication not enabled',
        );
      }

      // Check security status
      final securityStatus = await _secureStorage.getSecurityStatus();
      if (securityStatus['is_locked']) {
        return AdminAuthResult(
          success: false,
          message: 'Admin panel is temporarily locked',
          isLocked: true,
        );
      }

      // Perform biometric authentication
      final biometricResult = await _biometricService.authenticateWithBiometrics();
      
      if (biometricResult.success) {
        // Reset failed attempts on successful login
        await _secureStorage.updateFailedAttempts(0, null);
        await _secureStorage.updateLastLogin();
        
        return AdminAuthResult(
          success: true,
          message: 'Biometric authentication successful',
        );
      } else {
        return AdminAuthResult(
          success: false,
          message: biometricResult.errorMessage ?? 'Biometric authentication failed',
        );
      }
    } catch (e) {
      return AdminAuthResult(
        success: false,
        message: 'Biometric authentication error: ${e.toString()}',
      );
    }
  }

  // Check if admin authentication is set up
  Future<bool> isAdminSetup() async {
    return await _secureStorage.isAdminSetup();
  }

  // Check if biometric is available and enabled
  Future<bool> canUseBiometric() async {
    final isEnabled = await _secureStorage.isBiometricEnabled();
    final isAvailable = await _biometricService.isBiometricAvailable();
    return isEnabled && isAvailable;
  }

  // Enable/disable biometric authentication
  Future<bool> toggleBiometric(bool enable) async {
    try {
      if (enable) {
        // Check if biometric is available
        final isAvailable = await _biometricService.isBiometricAvailable();
        if (!isAvailable) return false;

        // Test biometric authentication
        final result = await _biometricService.authenticateWithBiometrics();
        if (!result.success) return false;
      }

      await _secureStorage.updateBiometricEnabled(enable);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get security status for UI
  Future<Map<String, dynamic>> getSecurityStatus() async {
    return await _secureStorage.getSecurityStatus();
  }

  // Get available biometric types for UI
  Future<List<BiometricType>> getAvailableBiometrics() async {
    return await _biometricService.getAvailableBiometrics();
  }

  // Logout admin (clear session, keep setup)
  Future<void> logoutAdmin() async {
    // Only clear session data, keep admin setup
    await _secureStorage.updateFailedAttempts(0, null);
  }

  // Reset admin authentication (complete reset)
  Future<void> resetAdminAuth() async {
    await _secureStorage.clearAdminAuth();
  }
}

class AdminAuthResult {
  final bool success;
  final String message;
  final int failedAttempts;
  final bool isLocked;

  AdminAuthResult({
    required this.success,
    required this.message,
    this.failedAttempts = 0,
    this.isLocked = false,
  });
}