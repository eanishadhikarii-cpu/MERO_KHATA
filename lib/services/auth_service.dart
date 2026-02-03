

enum AuthInputType {
  phone,
  email,
  username,
  invalid,
}

class AuthService {
  static AuthService? _instance;
  
  AuthService._internal();
  
  factory AuthService() {
    _instance ??= AuthService._internal();
    return _instance!;
  }

  AuthInputType detectInputType(String input) {
    if (input.isEmpty) return AuthInputType.invalid;
    
    // Phone number detection (Nepali format)
    if (RegExp(r'^(\+977|977|0)?[0-9]{10}$').hasMatch(input.replaceAll(' ', ''))) {
      return AuthInputType.phone;
    }
    
    // Email detection
    if (RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(input)) {
      return AuthInputType.email;
    }
    
    // Username (alphanumeric)
    if (RegExp(r'^[a-zA-Z0-9_]{3,20}$').hasMatch(input)) {
      return AuthInputType.username;
    }
    
    return AuthInputType.invalid;
  }

  Future<bool> sendOTP(String phoneNumber) async {
    // Simulate OTP sending
    await Future.delayed(Duration(seconds: 2));
    return true;
  }

  Future<AuthResult> verifyOTP(String otp, String identifier) async {
    // Simulate OTP verification
    await Future.delayed(Duration(seconds: 1));
    
    if (otp == "123456") {
      return AuthResult(
        success: true,
        isNewUser: true,
        user: MockUser(identifier),
      );
    }
    
    return AuthResult(
      success: false,
      message: "Invalid OTP",
    );
  }

  Future<bool> setupUser(Map<String, String> userData) async {
    // Simulate user setup
    await Future.delayed(Duration(seconds: 2));
    return true;
  }

  Future<bool> completeSetup({
    required MockUser user,
    required String shopName,
    required String ownerName,
    required String shopType,
    required String appPin,
    String? gstNumber,
  }) async {
    // Simulate setup completion
    await Future.delayed(Duration(seconds: 2));
    user.isSetupCompleted = true;
    return true;
  }

  Future<bool> authenticateUser(String identifier, AuthInputType type) async {
    // Simulate user authentication
    await Future.delayed(Duration(seconds: 1));
    return identifier.isNotEmpty && type != AuthInputType.invalid;
  }
}

class AuthResult {
  final bool success;
  final bool isNewUser;
  final MockUser? user;
  final String? message;

  AuthResult({
    required this.success,
    this.isNewUser = false,
    this.user,
    this.message,
  });
}

class MockUser {
  final String identifier;
  bool isSetupCompleted = false;
  
  MockUser(this.identifier);
}