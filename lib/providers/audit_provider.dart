import 'package:flutter/material.dart';
import '../database/audit_database.dart';

class AuditProvider with ChangeNotifier {
  bool _isAuditMode = false;
  bool get isAuditMode => _isAuditMode;

  Future<void> loadAuditMode() async {
    _isAuditMode = await AuditDatabase.isAuditMode();
    notifyListeners();
  }

  Future<bool> toggleAuditMode(String pin) async {
    if (pin != '1234') return false; // Replace with actual PIN verification
    
    final db = await AuditDatabase.database;
    final newValue = !_isAuditMode;
    
    await db.update(
      'audit_settings',
      {
        'value': newValue.toString(),
        'locked_at': DateTime.now().toIso8601String(),
      },
      where: 'key = ?',
      whereArgs: ['audit_mode'],
    );
    
    _isAuditMode = newValue;
    notifyListeners();
    return true;
  }

  bool canEdit() => !_isAuditMode;
}