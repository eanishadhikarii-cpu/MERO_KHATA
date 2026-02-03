import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _shopNameController = TextEditingController();
  final _panController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = context.read<SettingsProvider>();
      _shopNameController.text = settings.shopName;
      _panController.text = settings.panNumber;
      _addressController.text = settings.address;
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
          ),
        ],
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Shop Information
                const Text(
                  'Shop Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                TextField(
                  controller: _shopNameController,
                  decoration: const InputDecoration(
                    labelText: 'Shop Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                TextField(
                  controller: _panController,
                  decoration: const InputDecoration(
                    labelText: 'PAN Number',
                    border: OutlineInputBorder(),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                TextField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),

                const SizedBox(height: 32),

                // App Preferences
                const Text(
                  'App Preferences',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                Card(
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Dark Mode'),
                        subtitle: const Text('Use dark theme'),
                        value: settings.isDarkMode,
                        onChanged: (_) => settings.toggleDarkMode(),
                      ),
                      
                      ListTile(
                        title: const Text('Language'),
                        subtitle: Text(settings.language == 'ne' ? 'Nepali' : 'English'),
                        trailing: DropdownButton<String>(
                          value: settings.language,
                          items: const [
                            DropdownMenuItem(
                              value: 'ne',
                              child: Text('नेपाली'),
                            ),
                            DropdownMenuItem(
                              value: 'en',
                              child: Text('English'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              settings.updateLanguage(value);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Security
                const Text(
                  'Security',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                Card(
                  child: ListTile(
                    title: const Text('Change Admin PIN'),
                    subtitle: const Text('Update your admin access PIN'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: _changeAdminPin,
                  ),
                ),

                const SizedBox(height: 32),

                // App Information
                const Text(
                  'App Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                const Card(
                  child: Column(
                    children: [
                      ListTile(
                        title: Text('Version'),
                        subtitle: Text('1.0.0'),
                      ),
                      ListTile(
                        title: Text('Developer'),
                        subtitle: Text('Mero Khata Team'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _saveSettings() async {
    final settings = context.read<SettingsProvider>();
    
    await settings.updateShopName(_shopNameController.text.trim());
    await settings.updatePanNumber(_panController.text.trim());
    await settings.updateAddress(_addressController.text.trim());
    
    _showMessage('Settings saved successfully');
  }

  Future<void> _changeAdminPin() async {
    // This would show a PIN change dialog
    _showMessage('PIN change feature coming soon');
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _panController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}