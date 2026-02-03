import 'package:flutter/material.dart';
import '../models/product.dart';
import '../database/audit_safe_database_helper.dart';
import 'dart:async';

class FastSearchProvider with ChangeNotifier {
  final AuditSafeDatabaseHelper _db = AuditSafeDatabaseHelper();
  
  List<Product> _searchResults = [];
  List<Product> _recentProducts = [];
  List<Product> _favoriteProducts = [];
  bool _isSearching = false;
  Timer? _searchDebouncer;

  List<Product> get searchResults => _searchResults;
  List<Product> get recentProducts => _recentProducts;
  List<Product> get favoriteProducts => _favoriteProducts;
  bool get isSearching => _isSearching;

  // Initialize with cached data for instant access
  Future<void> initialize() async {
    await _loadRecentProducts();
    await _loadFavoriteProducts();
  }

  // Ultra-fast search with debouncing
  void searchProducts(String query) {
    _searchDebouncer?.cancel();
    
    if (query.isEmpty) {
      _searchResults = [..._favoriteProducts, ..._recentProducts];
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    _searchDebouncer = Timer(const Duration(milliseconds: 100), () async {
      try {
        final results = await _db.searchProducts(query);
        _searchResults = results.map((map) => Product.fromMap(map)).toList();
        _isSearching = false;
        notifyListeners();
      } catch (e) {
        debugPrint('Search error: $e');
        _isSearching = false;
        notifyListeners();
      }
    });
  }

  // Instant barcode search
  Future<Product?> searchByBarcode(String barcode) async {
    try {
      final db = await _db.database;
      final result = await db.query(
        'products',
        where: 'barcode = ? AND stock_quantity > 0',
        whereArgs: [barcode],
        limit: 1,
      );
      
      if (result.isNotEmpty) {
        final product = Product.fromMap(result.first);
        // Update recent products immediately
        _addToRecentProducts(product);
        return product;
      }
    } catch (e) {
      debugPrint('Barcode search error: $e');
    }
    return null;
  }

  // Load recent products (last 20 sold items)
  Future<void> _loadRecentProducts() async {
    try {
      final db = await _db.database;
      final results = await db.query(
        'products',
        where: 'last_sold_at IS NOT NULL AND stock_quantity > 0',
        orderBy: 'last_sold_at DESC',
        limit: 20,
      );
      
      _recentProducts = results.map((map) => Product.fromMap(map)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading recent products: $e');
    }
  }

  // Load favorite products
  Future<void> _loadFavoriteProducts() async {
    try {
      final db = await _db.database;
      final results = await db.query(
        'products',
        where: 'is_favorite = 1 AND stock_quantity > 0',
        orderBy: 'name ASC',
      );
      
      _favoriteProducts = results.map((map) => Product.fromMap(map)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading favorite products: $e');
    }
  }

  // Toggle favorite status
  Future<void> toggleFavorite(int productId) async {
    try {
      final db = await _db.database;
      
      // Get current status
      final result = await db.query(
        'products',
        columns: ['is_favorite'],
        where: 'id = ?',
        whereArgs: [productId],
      );
      
      if (result.isNotEmpty) {
        final currentStatus = result.first['is_favorite'] as int;
        final newStatus = currentStatus == 1 ? 0 : 1;
        
        await db.update(
          'products',
          {'is_favorite': newStatus},
          where: 'id = ?',
          whereArgs: [productId],
        );
        
        // Refresh favorites list
        await _loadFavoriteProducts();
      }
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
    }
  }

  // Add to recent products list
  void _addToRecentProducts(Product product) {
    _recentProducts.removeWhere((p) => p.id == product.id);
    _recentProducts.insert(0, product);
    
    // Keep only last 20
    if (_recentProducts.length > 20) {
      _recentProducts = _recentProducts.take(20).toList();
    }
    
    notifyListeners();
  }

  // Get suggestions for partial input
  Future<List<String>> getSuggestions(String query) async {
    if (query.length < 2) return [];
    
    try {
      final db = await _db.database;
      final results = await db.rawQuery('''
        SELECT DISTINCT name 
        FROM products 
        WHERE name LIKE ? AND stock_quantity > 0
        ORDER BY sale_count DESC
        LIMIT 5
      ''', ['$query%']);
      
      return results.map((row) => row['name'] as String).toList();
    } catch (e) {
      debugPrint('Error getting suggestions: $e');
      return [];
    }
  }

  // Clear search results
  void clearSearch() {
    _searchResults.clear();
    _searchDebouncer?.cancel();
    notifyListeners();
  }

  @override
  void dispose() {
    _searchDebouncer?.cancel();
    super.dispose();
  }
}