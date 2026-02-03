import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import '../../services/admin_auth_service.dart';
import '../../services/biometric_service.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen>
    with TickerProviderStateMixin {
  final List<TextEditingController> _pinControllers = 
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = 
      List.generate(6, (_) => FocusNode());
  
  final AdminAuthService _adminAuthService = AdminAuthService();
  final BiometricService _biometricService = BiometricService();
  
  bool _isLoading = false;
  String? _errorMessage;
  bool _canUseBiometric = false;
  List<BiometricType> _availableBiometrics = [];
  int _failedAttempts = 0;
  bool _isLocked = false;
  
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
    _setupAnimations();
    _disableScreenshots();
  }

  void _setupAnimations() {
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  void _disableScreenshots() {
    // Disable screenshots on admin screen for security
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  Future<void> _initializeAuth() async {
    final canUseBiometric = await _adminAuthService.canUseBiometric();
    final availableBiometrics = await _adminAuthService.getAvailableBiometrics();
    final securityStatus = await _adminAuthService.getSecurityStatus();
    
    setState(() {
      _canUseBiometric = canUseBiometric;
      _availableBiometrics = availableBiometrics;
      _failedAttempts = securityStatus['failed_attempts'];
      _isLocked = securityStatus['is_locked'];
    });

    // Auto-trigger biometric if available and no failed attempts
    if (_canUseBiometric && _failedAttempts == 0 && !_isLocked) {
      _authenticateWithBiometric();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Admin Panel Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red[600],
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.admin_panel_settings,
                      size: 48,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Admin Panel',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'Secure Access Required',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Lock Status or PIN Input
              if (_isLocked)
                _buildLockMessage()
              else
                _buildPinInput(),

              const SizedBox(height: 24),

              // Error Message
              if (_errorMessage != null) _buildErrorMessage(),

              const SizedBox(height: 24),

              // Biometric Button
              if (_canUseBiometric && !_isLocked) _buildBiometricButton(),

              const SizedBox(height: 16),

              // Failed Attempts Warning
              if (_failedAttempts > 0 && !_isLocked) _buildFailedAttemptsWarning(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPinInput() {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: Column(
            children: [
              const Text(
                'Enter Admin PIN',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) => _buildPinField(index)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPinField(int index) {
    return Container(
      width: 45,
      height: 55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _errorMessage != null ? Colors.red : Colors.grey[300]!,
          width: 2,
        ),
        color: Colors.white,
      ),
      child: TextField(
        controller: _pinControllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        obscureText: true,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (value) => _onPinChanged(value, index),
      ),
    );
  }

  Widget _buildBiometricButton() {
    final biometricName = _biometricService.getBiometricTypeName(_availableBiometrics);
    
    return Container(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _authenticateWithBiometric,
        icon: Icon(
          _availableBiometrics.contains(BiometricType.face)
              ? Icons.face
              : Icons.fingerprint,
          size: 24,
        ),
        label: Text(
          'Use $biometricName',
          style: const TextStyle(fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[600], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red[600], fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFailedAttemptsWarning() {
    final remainingAttempts = AdminAuthService.maxFailedAttempts - _failedAttempts;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber, color: Colors.orange[600], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Warning: $remainingAttempts attempt(s) remaining',
              style: TextStyle(color: Colors.orange[600], fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockMessage() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.lock, color: Colors.red[600], size: 48),
          const SizedBox(height: 12),
          Text(
            'Admin Panel Locked',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Too many failed attempts. Please wait before trying again.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red[600]),
          ),
        ],
      ),
    );
  }

  void _onPinChanged(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    // Clear error when user types
    if (_errorMessage != null) {
      setState(() {
        _errorMessage = null;
      });
    }

    // Auto-verify when all fields are filled
    if (index == 5 && value.isNotEmpty) {
      _authenticateWithPin();
    }
  }

  Future<void> _authenticateWithPin() async {
    final pin = _pinControllers.map((c) => c.text).join();
    
    if (pin.length != 6) {
      setState(() {
        _errorMessage = 'Please enter complete 6-digit PIN';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _adminAuthService.authenticateWithPin(pin);
      
      if (result.success) {
        _onAuthenticationSuccess();
      } else {
        setState(() {
          _errorMessage = result.message;
          _failedAttempts = result.failedAttempts;
          _isLocked = result.isLocked;
        });
        
        // Clear PIN fields and shake animation
        _clearPinFields();
        _shakeController.forward().then((_) => _shakeController.reset());
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Authentication failed. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _authenticateWithBiometric() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _adminAuthService.authenticateWithBiometrics();
      
      if (result.success) {
        _onAuthenticationSuccess();
      } else {
        setState(() {
          _errorMessage = result.message;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Biometric authentication failed';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onAuthenticationSuccess() {
    // Enable screenshots back
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    
    // Navigate to admin panel
    Navigator.pushReplacementNamed(context, '/admin_panel');
  }

  void _clearPinFields() {
    for (var controller in _pinControllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    for (var controller in _pinControllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    // Re-enable screenshots
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }
}