import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';
import '../providers/settings_provider.dart';
import '../providers/inventory_provider.dart';
import 'inventory_screen.dart';
import 'settings_screen.dart';
import '../widgets/pin_input_dialog.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  bool _isAuthenticated = false;
  final LocalAuthentication _localAuth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authenticate();
    });
  }

  Future<void> _authenticate() async {
    try {
      final settingsProvider = context.read<SettingsProvider>();
      await settingsProvider.loadSettings();
      
      // If no PIN is set, allow direct access without authentication
      if (settingsProvider.adminPin.isEmpty) {
        setState(() {
          _isAuthenticated = true;
        });
        return;
      }

      // Try biometric authentication first
      try {
        final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
        if (canCheckBiometrics) {
          final bool didAuthenticate = await _localAuth.authenticate(
            localizedReason: 'Authenticate to access admin panel',
            options: const AuthenticationOptions(
              biometricOnly: false,
              stickyAuth: true,
            ),
          );
          
          if (didAuthenticate) {
            setState(() {
              _isAuthenticated = true;
            });
            return;
          }
        }
      } catch (e) {
        debugPrint('Biometric authentication error: $e');
      }

      // Fall back to PIN authentication
      _showPinInput();
    } catch (e) {
      debugPrint('Authentication error: $e');
      setState(() {
        _isAuthenticated = true;
      });
    }
  }

  Future<void> _showPinInput() async {
    final pin = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const PinInputDialog(
        title: 'Enter Admin PIN',
      ),
    );

    if (pin != null) {
      final settingsProvider = context.read<SettingsProvider>();
      if (settingsProvider.verifyAdminPin(pin)) {
        setState(() {
          _isAuthenticated = true;
        });
      } else {
        _showMessage('Invalid PIN');
        Navigator.pop(context);
      }
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _showPinSetup() async {
    final pin = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const PinInputDialog(
        title: 'Set Admin PIN',
        isSetup: true,
      ),
    );

    if (pin != null) {
      await context.read<SettingsProvider>().setAdminPin(pin);
      _showMessage('Admin PIN set successfully');
    }
  }

  Future<void> _showChangePin() async {
    // First verify current PIN
    final currentPin = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const PinInputDialog(
        title: 'Enter Current PIN',
      ),
    );

    if (currentPin != null) {
      final settingsProvider = context.read<SettingsProvider>();
      if (settingsProvider.verifyAdminPin(currentPin)) {
        // Show new PIN setup
        final newPin = await showDialog<String>(
          context: context,
          barrierDismissible: true,
          builder: (context) => const PinInputDialog(
            title: 'Set New PIN',
            isSetup: true,
          ),
        );

        if (newPin != null) {
          await settingsProvider.setAdminPin(newPin);
          _showMessage('Admin PIN updated successfully');
        }
      } else {
        _showMessage('Invalid current PIN');
      }
    }
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthenticated) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Admin Authentication'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Inventory Management
            Card(
              child: ListTile(
                leading: const Icon(Icons.inventory),
                title: const Text('Inventory Management'),
                subtitle: const Text('Add, edit, delete products'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const InventoryScreen(),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 16),

            // Settings
            Card(
              child: ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Settings'),
                subtitle: const Text('Shop details, preferences'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
              ),
            ),

            // Security Settings (PIN Setup)
            Consumer<SettingsProvider>(
              builder: (context, settings, child) {
                if (settings.adminPin.isEmpty) {
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.security, color: Colors.orange),
                      title: const Text('Setup Security'),
                      subtitle: const Text('Set PIN for admin panel protection'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: _showPinSetup,
                    ),
                  );
                }
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.security, color: Colors.green),
                    title: const Text('Security Settings'),
                    subtitle: const Text('Admin PIN is configured'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      _showChangePin();
                    },
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // Low Stock Alert
            Consumer<InventoryProvider>(
              builder: (context, inventory, child) {
                final lowStockProducts = inventory.lowStockProducts;
                
                if (lowStockProducts.isEmpty) {
                  return const Card(
                    child: ListTile(
                      leading: Icon(Icons.check_circle, color: Colors.green),
                      title: Text('All products in stock'),
                      subtitle: Text('No low stock alerts'),
                    ),
                  );
                }

                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.warning, color: Colors.orange),
                    title: Text('${lowStockProducts.length} Low Stock Items'),
                    subtitle: Text(
                      lowStockProducts.take(2).map((p) => p.name).join(', ') +
                      (lowStockProducts.length > 2 ? '...' : ''),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const InventoryScreen(
                            showLowStockOnly: true,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}