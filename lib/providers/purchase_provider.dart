import 'package:flutter/material.dart';
import '../models/purchase.dart';
import '../database/enhanced_database_helper.dart';

class PurchaseProvider with ChangeNotifier {
  final EnhancedDatabaseHelper _db = EnhancedDatabaseHelper();
  List<Purchase> _purchases = [];
  bool _isLoading = false;

  List<Purchase> get purchases => _purchases;
  bool get isLoading => _isLoading;

  double get todayPurchases {
    final today = DateTime.now();
    return _purchases
        .where((p) => _isSameDay(p.purchaseDate, today))
        .fold(0.0, (sum, p) => sum + p.grandTotal);
  }

  double get pendingPayments {
    return _purchases
        .where((p) => p.paymentStatus == 'pending')
        .fold(0.0, (sum, p) => sum + p.grandTotal);
  }

  double get monthlyPurchases {
    final now = DateTime.now();
    return _purchases
        .where((p) => p.purchaseDate.month == now.month && p.purchaseDate.year == now.year)
        .fold(0.0, (sum, p) => sum + p.grandTotal);
  }

  Future<void> loadPurchases() async {
    _isLoading = true;
    notifyListeners();

    try {
      final db = await _db.database;
      final maps = await db.query('purchases', orderBy: 'created_at DESC');
      _purchases = maps.map((map) => Purchase.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error loading purchases: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addPurchase(Purchase purchase) async {
    try {
      final db = await _db.database;
      await db.transaction((txn) async {
        final purchaseId = await txn.insert('purchases', purchase.toMap());
        
        for (final item in purchase.items) {
          await txn.insert('purchase_items', {
            ...item.toMap(),
            'purchase_id': purchaseId,
          });
          
          // Update product stock and cost price
          await txn.rawUpdate(
            'UPDATE products SET stock_quantity = stock_quantity + ?, cost_price = ? WHERE id = ?',
            [item.quantity, item.costPrice, item.productId],
          );
        }
      });
      
      await loadPurchases();
      return true;
    } catch (e) {
      debugPrint('Error adding purchase: $e');
      return false;
    }
  }

  Future<void> markAsPaid(int purchaseId) async {
    try {
      final db = await _db.database;
      await db.update(
        'purchases',
        {'payment_status': 'paid'},
        where: 'id = ?',
        whereArgs: [purchaseId],
      );
      await loadPurchases();
    } catch (e) {
      debugPrint('Error marking purchase as paid: $e');
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }
}