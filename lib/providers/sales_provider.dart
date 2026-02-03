import 'package:flutter/material.dart';
import '../models/sale.dart';
import '../models/product.dart';
import '../database/database_helper.dart';

class SalesProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  List<Sale> _sales = [];
  final List<SaleItem> _currentSaleItems = [];
  bool _isLoading = false;

  List<Sale> get sales => _sales;
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

  Future<void> loadSales({DateTime? startDate, DateTime? endDate}) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _sales = await _db.getSales(startDate: startDate, endDate: endDate);
    } catch (e) {
      debugPrint('Error loading sales: $e');
    }
    
    _isLoading = false;
    notifyListeners();
  }

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
        itemDiscount: existingItem.itemDiscount,
        vatPercent: existingItem.vatPercent,
        totalAmount: newTotalAmount,
        priceOverridden: existingItem.priceOverridden,
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
    notifyListeners();
  }

  void removeItemFromCurrentSale(int index) {
    if (index >= 0 && index < _currentSaleItems.length) {
      _currentSaleItems.removeAt(index);
      notifyListeners();
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
        itemDiscount: item.itemDiscount,
        vatPercent: item.vatPercent,
        totalAmount: quantity * item.unitPrice,
        priceOverridden: item.priceOverridden,
      );
      notifyListeners();
    }
  }

  void clearCurrentSale() {
    _currentSaleItems.clear();
    notifyListeners();
  }

  Future<bool> completeSale({
    required String saleType,
    required String paymentMethod,
    int? customerId,
    String? customerName,
    String? customerPhone,
  }) async {
    if (_currentSaleItems.isEmpty) return false;

    try {
      final billNumber = await _db.generateBillNumber();
      final now = DateTime.now();
      
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

      final saleId = await _db.insertSale(sale);
      if (saleId > 0) {
        clearCurrentSale();
        await loadSales();
        return true;
      }
    } catch (e) {
      debugPrint('Error completing sale: $e');
    }
    return false;
  }

  List<Sale> get todaySales {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);
    
    return _sales.where((sale) =>
        sale.saleDate.isAfter(startOfDay) && sale.saleDate.isBefore(endOfDay)
    ).toList();
  }

  List<Sale> get creditSales {
    return _sales.where((sale) => sale.saleType == 'credit').toList();
  }

  List<Sale> get cashSales {
    return _sales.where((sale) => sale.saleType == 'cash').toList();
  }

  double get todaysTotalSales {
    return todaySales.fold(0.0, (sum, sale) => sum + sale.grandTotal);
  }

  double get totalCreditAmount {
    return creditSales.fold(0.0, (sum, sale) => sum + sale.grandTotal);
  }

  double get todaysProfit {
    return todaysTotalSales * 0.2; // Assume 20% profit margin
  }
}