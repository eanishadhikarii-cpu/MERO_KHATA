import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class SettingsProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  
  String _shopName = 'मेरो पसल';
  String _panNumber = '';
  String _address = '';
  String _language = 'ne';
  bool _isDarkMode = false;
  String _adminPin = '';

  String get shopName => _shopName;
  String get panNumber => _panNumber;
  String get address => _address;
  String get language => _language;
  bool get isDarkMode => _isDarkMode;
  String get adminPin => _adminPin;

  Future<void> loadSettings() async {
    try {
      _shopName = await _db.getSetting('shop_name') ?? 'मेरो पसल';
      _panNumber = await _db.getSetting('pan_number') ?? '';
      _address = await _db.getSetting('address') ?? '';
      _language = await _db.getSetting('language') ?? 'ne';
      _isDarkMode = (await _db.getSetting('dark_mode')) == 'true';
      _adminPin = await _db.getSetting('admin_pin') ?? '';
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }

  Future<void> updateShopName(String name) async {
    _shopName = name;
    await _db.setSetting('shop_name', name);
    notifyListeners();
  }

  Future<void> updatePanNumber(String pan) async {
    _panNumber = pan;
    await _db.setSetting('pan_number', pan);
    notifyListeners();
  }

  Future<void> updateAddress(String addr) async {
    _address = addr;
    await _db.setSetting('address', addr);
    notifyListeners();
  }

  Future<void> updateLanguage(String lang) async {
    _language = lang;
    await _db.setSetting('language', lang);
    notifyListeners();
  }

  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    await _db.setSetting('dark_mode', _isDarkMode.toString());
    notifyListeners();
  }

  Future<void> setAdminPin(String pin) async {
    _adminPin = pin;
    await _db.setSetting('admin_pin', pin);
    notifyListeners();
  }

  bool verifyAdminPin(String pin) {
    return _adminPin == pin;
  }
}