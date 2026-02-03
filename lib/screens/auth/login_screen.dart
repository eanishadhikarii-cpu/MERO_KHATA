import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'otp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _controller = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // App Logo/Title
              const Icon(
                Icons.store,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
              const Text(
                'Mero Khata',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Shop Accounting Made Simple',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 48),

              // Input Field
              TextField(
                controller: _controller,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Phone Number or Email',
                  hintText: 'Enter your phone or email',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  errorText: _errorMessage,
                ),
                onChanged: (value) {
                  if (_errorMessage != null) {
                    setState(() {
                      _errorMessage = null;
                    });
                  }
                },
              ),
              const SizedBox(height: 24),

              // Send OTP Button
              ElevatedButton(
                onPressed: _isLoading ? null : _sendOTP,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Send OTP',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
              const SizedBox(height: 16),

              // Input Type Indicator
              if (_controller.text.isNotEmpty)
                _buildInputTypeIndicator(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputTypeIndicator() {
    final inputType = _authService.detectInputType(_controller.text);
    String text;
    Color color;
    IconData icon;

    switch (inputType) {
      case AuthInputType.phone:
        text = 'Phone Number - OTP via SMS';
        color = Colors.green;
        icon = Icons.phone;
        break;
      case AuthInputType.email:
        text = 'Email Address - OTP via Email';
        color = Colors.blue;
        icon = Icons.email;
        break;
      case AuthInputType.username:
        text = 'Username - OTP via SMS';
        color = Colors.orange;
        icon = Icons.account_circle;
        break;
      case AuthInputType.invalid:
        text = 'Invalid format';
        color = Colors.red;
        icon = Icons.error;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(color: color, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Future<void> _sendOTP() async {
    final input = _controller.text.trim();
    
    if (input.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter phone number or email';
      });
      return;
    }

    final inputType = _authService.detectInputType(input);
    if (inputType == AuthInputType.invalid) {
      setState(() {
        _errorMessage = 'Please enter valid phone number or email';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await _authService.sendOTP(input);
      
      if (success) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OTPScreen(phoneOrEmail: input),
          ),
        );
      } else {
        setState(() {
          _errorMessage = 'Failed to send OTP. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Something went wrong. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}