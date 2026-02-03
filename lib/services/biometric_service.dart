import 'package:local_auth/local_auth.dart';

class BiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();

  // Check if biometric authentication is available
  Future<bool> isBiometricAvailable() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } catch (e) {
      return false;
    }
  }

  // Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  // Authenticate using biometrics
  Future<BiometricResult> authenticateWithBiometrics() async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        return BiometricResult(
          success: false,
          errorMessage: 'Biometric authentication not available',
        );
      }

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Verify your identity to access Admin Panel',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      return BiometricResult(
        success: didAuthenticate,
        errorMessage: didAuthenticate ? null : 'Authentication failed',
      );
    } catch (e) {
      return BiometricResult(
        success: false,
        errorMessage: 'Biometric authentication error: ${e.toString()}',
      );
    }
  }

  // Check if user has enrolled biometrics
  Future<bool> hasEnrolledBiometrics() async {
    try {
      final availableBiometrics = await getAvailableBiometrics();
      return availableBiometrics.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Get biometric type name for UI
  String getBiometricTypeName(List<BiometricType> types) {
    if (types.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (types.contains(BiometricType.fingerprint)) {
      return 'Fingerprint';
    } else if (types.contains(BiometricType.iris)) {
      return 'Iris';
    } else {
      return 'Biometric';
    }
  }

  // Get appropriate icon for biometric type
  String getBiometricIcon(List<BiometricType> types) {
    if (types.contains(BiometricType.face)) {
      return '👤'; // Face icon
    } else if (types.contains(BiometricType.fingerprint)) {
      return '👆'; // Fingerprint icon
    } else {
      return '🔐'; // Generic security icon
    }
  }
}

class BiometricResult {
  final bool success;
  final String? errorMessage;

  BiometricResult({
    required this.success,
    this.errorMessage,
  });
}