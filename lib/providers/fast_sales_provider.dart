import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../database/audit_database.dart';
import 'dart:async';
import 'dart:convert';

class FastSalesProvider with ChangeNotifier {
  List<Map<String, dynamic>> _cart = [];
  Timer? _autoSaveTimer;
  
  List<Map<String, dynamic>> get cart => _cart;
  double get total => _cart.fold(0.0, (sum, item) => sum + (item['price'] * item['qty']));

  void initialize() {
    _recoverDraft();
    _startAutoSave();
  }

  // Auto-save every 2 seconds (non-blocking)
  void _startAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (_cart.isNotEmpty) _saveDraft();
    });
  }

  // Add product to cart (instant)
  void addProduct(Map<String, dynamic> product, int qty) {
    final existing = _cart.indexWhere((item) => item['id'] == product['id']);
    
    if (existing >= 0) {
      _cart[existing]['qty'] += qty;
    } else {
      _cart.add({
        'id': product['id'],
        'name': product['name'],
        'price': product['price'],
        'qty': qty,
      });
    }
    
    _updateProductStats(product['id']);
    notifyListeners();
  }

  // Complete sale (atomic transaction)
  Future<bool> completeSale() async {
    if (_cart.isEmpty) return false;
    
    try {
      final db = await AuditDatabase.database;
      final transactionNumber = await AuditDatabase.getNextNumber('SALE');
      final vatNumber = await AuditDatabase.getNextNumber('VAT-INV');
      
      await db.transaction((txn) async {
        // Insert sale
        await txn.insert('sales', {
          'transaction_number': transactionNumber,
          'vat_invoice_number': vatNumber,
          'total': total,
          'is_finalized': 1,
          'finalized_at': DateTime.now().toIso8601String(),
          'created_at': DateTime.now().toIso8601String(),
        });
        
        // Update stock
        for (final item in _cart) {
          await txn.rawUpdate(
            'UPDATE products SET stock = stock - ?, sale_count = sale_count + 1 WHERE id = ?',
            [item['qty'], item['id']],
          );
        }
      });
      
      _clearCart();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Background draft save
  void _saveDraft() async {
    final db = await AuditDatabase.database;
    await db.insert(
      'drafts',
      {
        'type': 'SALE',
        'data': jsonEncode(_cart),
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Crash recovery
  void _recoverDraft() async {
    final db = await AuditDatabase.database;
    final result = await db.query('drafts', where: 'type = ?', whereArgs: ['SALE']);
    
    if (result.isNotEmpty) {
      final data = result.first['data'] as String;
      final updatedAt = DateTime.parse(result.first['updated_at'] as String);
      
      // Only recover if draft is recent (within 1 hour)
      if (DateTime.now().difference(updatedAt).inHours < 1) {
        _cart = List<Map<String, dynamic>>.from(jsonDecode(data));
        notifyListeners();
      }
    }
  }

  void _updateProductStats(int productId) async {
    final db = await AuditDatabase.database;
    await db.update(
      'products',
      {'last_sold': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [productId],
    );
  }

  void _clearCart() {
    _cart.clear();
    AuditDatabase.database.then((db) => db.delete('drafts', where: 'type = ?', whereArgs: ['SALE']));
    notifyListeners();
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    super.dispose();
  }
}