import 'package:flutter/material.dart';
import '../models/sale.dart';
import '../models/product.dart';
import '../database/audit_safe_database_helper.dart';
import 'dart:convert';
import 'dart:async';

class PerformanceSalesProvider with ChangeNotifier {
  final AuditSafeDatabaseHelper _db = AuditSafeDatabaseHelper();
  
  List<SaleItem> _currentSaleItems = [];
  final bool _isLoading = false;
  Timer? _autoSaveTimer;
  
  List<SaleItem> get currentSaleItems => _currentSaleItems;
  bool get isLoading => _isLoading;

  double get currentSaleTotal {
    return _currentSaleItems.fold(0.0, (sum, item) => sum + item.totalAmount);
  }

  double get currentSaleVAT {
    return _currentSaleItems.fold(0.0, (sum, item) => 
        sum + (item.totalAmount * item.vatPercent / 100));
  }

  double get currentSaleGrandTotal {
    return currentSaleTotal + currentSaleVAT;
  }

  // Initialize with crash recovery
  Future<void> initialize() async {
    await _recoverFromCrash();
    _startAutoSave();
  }

  // Auto-save every 2 seconds
  void _startAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _saveDraft();
    });
  }

  // Non-blocking draft save
  void _saveDraft() async {
    if (_currentSaleItems.isNotEmpty) {
      final draftData = {
        'items': _currentSaleItems.map((item) => {
          'productId': item.productId,
          'productName': item.productName,
          'quantity': item.quantity,
          'unitPrice': item.unitPrice,
          'vatPercent': item.vatPercent,
          'totalAmount': item.totalAmount,
        }).toList(),
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      // Save in background without blocking UI
      _db.saveDraft('SALE', draftData);
    }
  }

  // Recover from crash
  Future<void> _recoverFromCrash() async {
    try {
      final draft = await _db.getLatestDraft('SALE');
      if (draft != null) {
        final draftData = jsonDecode(draft['draft_data']);
        final items = draftData['items'] as List;
        
        _currentSaleItems = items.map((item) => SaleItem(
          saleId: 0,
          productId: item['productId'],
          productName: item['productName'],
          quantity: item['quantity'],
          unitPrice: item['unitPrice'].toDouble(),
          originalPrice: item['unitPrice'].toDouble(),
          vatPercent: item['vatPercent'].toDouble(),
          totalAmount: item['totalAmount'].toDouble(),
        )).toList();
        
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error recovering from crash: $e');
    }
  }

  // Instant add to cart with auto-save
  void addItemToCurrentSale(Product product, int quantity) {
    final existingIndex = _currentSaleItems.indexWhere(
        (item) => item.productId == product.id);
    
    if (existingIndex >= 0) {
      final existingItem = _currentSaleItems[existingIndex];
      final newQuantity = existingItem.quantity + quantity;
      final newTotalAmount = newQuantity * product.sellingPrice;
      
      _currentSaleItems[existingIndex] = SaleItem(
        id: existingItem.id,
        saleId: existingItem.saleId,
        productId: existingItem.productId,
        productName: existingItem.productName,
        quantity: newQuantity,
        unitPrice: existingItem.unitPrice,
        originalPrice: existingItem.originalPrice,
        vatPercent: existingItem.vatPercent,
        totalAmount: newTotalAmount,
      );
    } else {
      _currentSaleItems.add(SaleItem(
        saleId: 0,
        productId: product.id!,
        productName: product.name,
        quantity: quantity,
        unitPrice: product.sellingPrice,
        originalPrice: product.sellingPrice,
        vatPercent: product.vatPercent,
        totalAmount: quantity * product.sellingPrice,
      ));
    }
    
    // Update product last sold info immediately
    _updateProductSaleInfo(product.id!);
    
    notifyListeners();
    _saveDraft(); // Auto-save immediately
  }

  void removeItemFromCurrentSale(int index) {
    if (index >= 0 && index < _currentSaleItems.length) {
      _currentSaleItems.removeAt(index);
      notifyListeners();
      _saveDraft();
    }
  }

  void updateItemQuantity(int index, int quantity) {
    if (index >= 0 && index < _currentSaleItems.length && quantity > 0) {
      final item = _currentSaleItems[index];
      _currentSaleItems[index] = SaleItem(
        id: item.id,
        saleId: item.saleId,
        productId: item.productId,
        productName: item.productName,
        quantity: quantity,
        unitPrice: item.unitPrice,
        originalPrice: item.originalPrice,
        vatPercent: item.vatPercent,
        totalAmount: quantity * item.unitPrice,
      );
      notifyListeners();
      _saveDraft();
    }
  }

  // High-performance sale completion
  Future<bool> completeSale({
    required String saleType,
    required String paymentMethod,
    int? customerId,
    String? customerName,
    String? customerPhone,
  }) async {
    if (_currentSaleItems.isEmpty) return false;

    try {
      final db = await _db.database;
      
      // Generate transaction numbers
      final transactionNumber = await _db.getNextTransactionNumber('SALE');
      final vatInvoiceNumber = await _db.getNextTransactionNumber('VAT-INV');
      final billNumber = 'MK${DateTime.now().millisecondsSinceEpoch}';
      
      final now = DateTime.now();
      
      // Create sale with audit trail
      final sale = Sale(
        billNumber: billNumber,
        saleDate: now,
        totalAmount: currentSaleTotal,
        vatAmount: currentSaleVAT,
        grandTotal: currentSaleGrandTotal,
        saleType: saleType,
        paymentMethod: paymentMethod,
        customerId: customerId,
        customerName: customerName,
        customerPhone: customerPhone,
        items: _currentSaleItems,
        createdAt: now,
      );

      // Atomic transaction for data integrity
      await db.transaction((txn) async {
        final saleId = await txn.insert('sales', {
          ...sale.toMap(),
          'transaction_number': transactionNumber,
          'vat_invoice_number': vatInvoiceNumber,
          'is_finalized': 1,
          'finalized_at': now.toIso8601String(),
          'created_by': 'user',
        });
        
        for (SaleItem item in _currentSaleItems) {
          await txn.insert('sale_items', {
            'sale_id': saleId,
            'product_id': item.productId,
            'product_name': item.productName,
            'quantity': item.quantity,
            'unit_price': item.unitPrice,
            'total_amount': item.totalAmount,
            'created_at': now.toIso8601String(),
          });
          
          // Update stock atomically
          await txn.rawUpdate(
            'UPDATE products SET stock_quantity = stock_quantity - ?, last_sold_at = ?, sale_count = sale_count + 1 WHERE id = ?',
            [item.quantity, now.toIso8601String(), item.productId],
          );
        }
      });
      
      // Clear cart and draft
      _currentSaleItems.clear();
      await _db.clearDraft('SALE');
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error completing sale: $e');
      return false;
    }
  }

  // Update product sale statistics
  Future<void> _updateProductSaleInfo(int productId) async {
    try {
      final db = await _db.database;
      await db.update(
        'products',
        {
          'last_sold_at': DateTime.now().toIso8601String(),
          'sale_count': 'sale_count + 1',
        },
        where: 'id = ?',
        whereArgs: [productId],
      );
    } catch (e) {
      debugPrint('Error updating product sale info: $e');
    }
  }

  void clearCurrentSale() {
    _currentSaleItems.clear();
    _db.clearDraft('SALE');
    notifyListeners();
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    super.dispose();
  }
}