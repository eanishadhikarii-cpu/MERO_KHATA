import 'package:flutter/material.dart';
import '../models/product.dart';
import '../database/database_helper.dart';

class InventoryProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  List<Product> _products = [];
  bool _isLoading = false;

  List<Product> get products => _products;
  bool get isLoading => _isLoading;

  List<Product> get lowStockProducts => 
      _products.where((p) => p.stockQuantity <= 5).toList();

  Future<void> loadProducts() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _products = await _db.getProducts();
    } catch (e) {
      debugPrint('Error loading products: $e');
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addProduct(Product product) async {
    try {
      final id = await _db.insertProduct(product);
      if (id > 0) {
        await loadProducts();
        return true;
      }
    } catch (e) {
      debugPrint('Error adding product: $e');
    }
    return false;
  }

  Future<bool> updateProduct(Product product) async {
    try {
      final result = await _db.updateProduct(product);
      if (result > 0) {
        await loadProducts();
        return true;
      }
    } catch (e) {
      debugPrint('Error updating product: $e');
    }
    return false;
  }

  Future<bool> deleteProduct(int id) async {
    try {
      final result = await _db.deleteProduct(id);
      if (result > 0) {
        await loadProducts();
        return true;
      }
    } catch (e) {
      debugPrint('Error deleting product: $e');
    }
    return false;
  }

  Future<Product?> getProductByBarcode(String barcode) async {
    try {
      return await _db.getProductByBarcode(barcode);
    } catch (e) {
      debugPrint('Error getting product by barcode: $e');
      return null;
    }
  }

  List<Product> searchProducts(String query) {
    if (query.isEmpty) return _products;
    
    return _products.where((product) =>
        product.name.toLowerCase().contains(query.toLowerCase()) ||
        (product.barcode?.contains(query) ?? false)
    ).toList();
  }
}