import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import '../../models/user.dart';
import '../../services/admin_auth_service.dart';
import '../../services/biometric_service.dart';

class AdminSetupScreen extends StatefulWidget {
  final User user;

  const AdminSetupScreen({super.key, required this.user});

  @override
  State<AdminSetupScreen> createState() => _AdminSetupScreenState();
}

class _AdminSetupScreenState extends State<AdminSetupScreen> {
  final List<TextEditingController> _pinControllers = 
      List.generate(6, (_) => TextEditingController());
  final List<TextEditingController> _confirmPinControllers = 
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _pinFocusNodes = 
      List.generate(6, (_) => FocusNode());
  final List<FocusNode> _confirmPinFocusNodes = 
      List.generate(6, (_) => FocusNode());

  final AdminAuthService _adminAuthService = AdminAuthService();
  final BiometricService _biometricService = BiometricService();

  bool _isLoading = false;
  String? _errorMessage;
  bool _enableBiometric = false;
  bool _biometricAvailable = false;
  List<BiometricType> _availableBiometrics = [];

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    final isAvailable = await _biometricService.isBiometricAvailable();
    final availableBiometrics = await _biometricService.getAvailableBiometrics();
    
    setState(() {
      _biometricAvailable = isAvailable;
      _availableBiometrics = availableBiometrics;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Admin Access'),
        centerTitle: true,
        backgroundColor: Colors.red[600],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.admin_panel_settings,
                    size: 48,
                    color: Colors.red[600],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Setup Admin Panel Access',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Create a secure PIN to access admin features like inventory management, reports, and settings.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Create PIN Section
            const Text(
              'Create Admin PIN',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter a 6-digit PIN for admin access',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (index) => _buildPinField(index, true)),
            ),
            const SizedBox(height: 24),

            // Confirm PIN Section
            const Text(
              'Confirm Admin PIN',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Re-enter the same 6-digit PIN',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (index) => _buildPinField(index, false)),
            ),
            const SizedBox(height: 24),

            // Biometric Option
            if (_biometricAvailable) _buildBiometricOption(),

            // Error Message
            if (_errorMessage != null) _buildErrorMessage(),

            const SizedBox(height: 32),

            // Setup Button
            ElevatedButton(
              onPressed: _isLoading ? null : _setupAdminAuth,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Setup Admin Access',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
            const SizedBox(height: 16),

            // Security Note
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.security, color: Colors.blue[600], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your PIN is encrypted and stored securely on this device. It cannot be recovered if forgotten.',
                      style: TextStyle(
                        color: Colors.blue[600],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPinField(int index, bool isMainPin) {
    final controllers = isMainPin ? _pinControllers : _confirmPinControllers;
    final focusNodes = isMainPin ? _pinFocusNodes : _confirmPinFocusNodes;
    
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
        controller: controllers[index],
        focusNode: focusNodes[index],
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
        onChanged: (value) => _onPinChanged(value, index, isMainPin),
      ),
    );
  }

  Widget _buildBiometricOption() {
    final biometricName = _biometricService.getBiometricTypeName(_availableBiometrics);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Biometric Authentication',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enable $biometricName for faster admin access',
          style: const TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: SwitchListTile(
            title: Text('Enable $biometricName'),
            subtitle: const Text('Use biometric authentication for admin login'),
            value: _enableBiometric,
            onChanged: (value) {
              setState(() {
                _enableBiometric = value;
              });
            },
            secondary: Icon(
              _availableBiometrics.contains(BiometricType.face)
                  ? Icons.face
                  : Icons.fingerprint,
              color: Colors.blue[600],
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
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

  void _onPinChanged(String value, int index, bool isMainPin) {
    final controllers = isMainPin ? _pinControllers : _confirmPinControllers;
    final focusNodes = isMainPin ? _pinFocusNodes : _confirmPinFocusNodes;
    final nextFocusNodes = isMainPin ? _confirmPinFocusNodes : _pinFocusNodes;

    if (value.isNotEmpty) {
      if (index < 5) {
        focusNodes[index + 1].requestFocus();
      } else if (isMainPin) {
        // Move to confirm PIN first field
        nextFocusNodes[0].requestFocus();
      }
    } else if (value.isEmpty && index > 0) {
      focusNodes[index - 1].requestFocus();
    }

    // Clear error when user types
    if (_errorMessage != null) {
      setState(() {
        _errorMessage = null;
      });
    }
  }

  Future<void> _setupAdminAuth() async {
    final pin = _pinControllers.map((c) => c.text).join();
    final confirmPin = _confirmPinControllers.map((c) => c.text).join();

    // Validate PIN
    if (pin.length != 6) {
      setState(() {
        _errorMessage = 'PIN must be exactly 6 digits';
      });
      return;
    }

    if (pin != confirmPin) {
      setState(() {
        _errorMessage = 'PINs do not match';
      });
      return;
    }

    if (!RegExp(r'^\d{6}$').hasMatch(pin)) {
      setState(() {
        _errorMessage = 'PIN must contain only numbers';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Test biometric if enabled
      if (_enableBiometric) {
        final biometricResult = await _biometricService.authenticateWithBiometrics();
        if (!biometricResult.success) {
          setState(() {
            _errorMessage = 'Biometric setup failed. Please try again.';
            _enableBiometric = false;
          });
          return;
        }
      }

      // Setup admin authentication
      final result = await _adminAuthService.setupAdminAuth(
        user: widget.user,
        adminPin: pin,
        enableBiometric: _enableBiometric,
      );

      if (result.success) {
        // Show success message and navigate
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Admin access setup successful!'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.pushReplacementNamed(context, '/admin_panel');
      } else {
        setState(() {
          _errorMessage = result.message;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Setup failed. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _pinControllers) {
      controller.dispose();
    }
    for (var controller in _confirmPinControllers) {
      controller.dispose();
    }
    for (var focusNode in _pinFocusNodes) {
      focusNode.dispose();
    }
    for (var focusNode in _confirmPinFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }
}