import 'package:flutter/material.dart';
import '../database/audit_safe_database_helper.dart';

class AuditModeProvider with ChangeNotifier {
  final AuditSafeDatabaseHelper _db = AuditSafeDatabaseHelper();
  
  bool _isAuditModeActive = false;
  DateTime? _auditLockDate;
  bool _isLoading = false;

  bool get isAuditModeActive => _isAuditModeActive;
  DateTime? get auditLockDate => _auditLockDate;
  bool get isLoading => _isLoading;

  Future<void> loadAuditSettings() async {
    _isLoading = true;
    notifyListeners();

    try {
      _isAuditModeActive = await _db.isAuditModeActive();
      
      final db = await _db.database;
      final result = await db.query(
        'audit_settings',
        where: 'key = ?',
        whereArgs: ['audit_lock_date'],
      );
      
      if (result.isNotEmpty) {
        final dateStr = result.first['value'] as String;
        if (dateStr.isNotEmpty) {
          _auditLockDate = DateTime.parse(dateStr);
        }
      }
    } catch (e) {
      debugPrint('Error loading audit settings: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> enableAuditMode(DateTime lockDate, String adminPin) async {
    try {
      // Verify admin PIN first
      if (!await _verifyAdminPin(adminPin)) {
        return false;
      }

      final db = await _db.database;
      final now = DateTime.now().toIso8601String();
      
      await db.transaction((txn) async {
        await txn.update(
          'audit_settings',
          {
            'value': 'true',
            'locked_at': now,
            'locked_by': 'admin'
          },
          where: 'key = ?',
          whereArgs: ['audit_mode_enabled'],
        );
        
        await txn.update(
          'audit_settings',
          {
            'value': lockDate.toIso8601String(),
            'locked_at': now,
            'locked_by': 'admin'
          },
          where: 'key = ?',
          whereArgs: ['audit_lock_date'],
        );
      });

      _isAuditModeActive = true;
      _auditLockDate = lockDate;
      notifyListeners();
      
      return true;
    } catch (e) {
      debugPrint('Error enabling audit mode: $e');
      return false;
    }
  }

  Future<bool> disableAuditMode(String adminPin) async {
    try {
      if (!await _verifyAdminPin(adminPin)) {
        return false;
      }

      final db = await _db.database;
      await db.update(
        'audit_settings',
        {'value': 'false'},
        where: 'key = ?',
        whereArgs: ['audit_mode_enabled'],
      );

      _isAuditModeActive = false;
      notifyListeners();
      
      return true;
    } catch (e) {
      debugPrint('Error disabling audit mode: $e');
      return false;
    }
  }

  Future<bool> canEditTransaction(DateTime transactionDate) async {
    if (_isAuditModeActive) return false;
    
    return !(await _db.isDateLocked(transactionDate));
  }

  Future<bool> performDayClose(DateTime date) async {
    try {
      final db = await _db.database;
      
      // Calculate day totals
      final dateStr = date.toIso8601String().split('T')[0];
      final salesResult = await db.rawQuery('''
        SELECT 
          COALESCE(SUM(grand_total), 0) as total_sales,
          COALESCE(SUM(CASE WHEN payment_method = 'cash' THEN grand_total ELSE 0 END), 0) as total_cash
        FROM sales 
        WHERE DATE(sale_date) = ?
      ''', [dateStr]);
      
      final totals = salesResult.first;
      
      // Insert day close record
      await db.insert('day_close_records', {
        'close_date': dateStr,
        'closed_at': DateTime.now().toIso8601String(),
        'closed_by': 'admin',
        'total_sales': totals['total_sales'],
        'total_cash': totals['total_cash'],
        'is_finalized': 1,
      });
      
      // Mark all sales as day closed
      await db.update(
        'sales',
        {'day_closed': 1},
        where: 'DATE(sale_date) = ?',
        whereArgs: [dateStr],
      );
      
      return true;
    } catch (e) {
      debugPrint('Error performing day close: $e');
      return false;
    }
  }

  Future<bool> _verifyAdminPin(String pin) async {
    // This should integrate with your existing PIN verification
    // For now, using a simple check
    return pin == '1234'; // Replace with actual PIN verification
  }
}