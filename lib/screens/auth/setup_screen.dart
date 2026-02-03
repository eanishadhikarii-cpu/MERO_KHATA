import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../working_home_screen.dart';

class SetupScreen extends StatefulWidget {
  final MockUser user;

  const SetupScreen({super.key, required this.user});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _shopNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _gstController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  
  final _authService = AuthService();
  String _selectedShopType = 'General Store';
  String _selectedCurrency = 'NPR';
  bool _isLoading = false;

  final List<String> _shopTypes = [
    'General Store',
    'Grocery Store',
    'Medical Store',
    'Electronics Store',
    'Clothing Store',
    'Hardware Store',
    'Stationery Store',
    'Mobile Shop',
    'Other',
  ];

  final List<String> _currencies = ['NPR', 'INR', 'USD'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Your Shop'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            // Welcome Message
            const Text(
              'Welcome to Mero Khata!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Let\'s set up your shop details',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),

            // Shop Name (Required)
            TextFormField(
              controller: _shopNameController,
              decoration: InputDecoration(
                labelText: 'Shop Name *',
                hintText: 'Enter your shop name',
                prefixIcon: const Icon(Icons.store),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Shop name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Owner Name
            TextFormField(
              controller: _ownerNameController,
              decoration: InputDecoration(
                labelText: 'Owner Name',
                hintText: 'Enter owner name',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Shop Type Dropdown
            DropdownButtonFormField<String>(
              value: _selectedShopType,
              decoration: InputDecoration(
                labelText: 'Shop Type',
                prefixIcon: const Icon(Icons.category),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: _shopTypes.map((type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedShopType = value!;
                });
              },
            ),
            const SizedBox(height: 16),

            // Currency Dropdown
            DropdownButtonFormField<String>(
              value: _selectedCurrency,
              decoration: InputDecoration(
                labelText: 'Currency',
                prefixIcon: const Icon(Icons.currency_exchange),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: _currencies.map((currency) {
                return DropdownMenuItem(value: currency, child: Text(currency));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCurrency = value!;
                });
              },
            ),
            const SizedBox(height: 16),

            // GST Number (Optional)
            TextFormField(
              controller: _gstController,
              decoration: InputDecoration(
                labelText: 'GST Number (Optional)',
                hintText: 'Enter GST registration number',
                prefixIcon: const Icon(Icons.receipt_long),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // PIN Section
            const Text(
              'Create App PIN for Offline Access',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This PIN will allow you to access the app when offline',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // Create PIN
            TextFormField(
              controller: _pinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                labelText: 'Create 6-digit PIN *',
                hintText: 'Enter 6-digit PIN',
                prefixIcon: const Icon(Icons.lock),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.length != 6) {
                  return 'PIN must be exactly 6 digits';
                }
                if (!RegExp(r'^\d{6}$').hasMatch(value)) {
                  return 'PIN must contain only numbers';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Confirm PIN
            TextFormField(
              controller: _confirmPinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                labelText: 'Confirm PIN *',
                hintText: 'Re-enter 6-digit PIN',
                prefixIcon: const Icon(Icons.lock_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value != _pinController.text) {
                  return 'PINs do not match';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),

            // Complete Setup Button
            ElevatedButton(
              onPressed: _isLoading ? null : _completeSetup,
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
                      'Complete Setup',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _completeSetup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _authService.completeSetup(
        user: widget.user,
        shopName: _shopNameController.text.trim(),
        ownerName: _ownerNameController.text.trim(),
        shopType: _selectedShopType,
        appPin: _pinController.text,
        gstNumber: _gstController.text.trim().isEmpty ? null : _gstController.text.trim(),
      );

      if (success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const WorkingHomeScreen(),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Setup failed. Please try again.')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _ownerNameController.dispose();
    _gstController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }
}