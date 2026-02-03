import 'package:flutter/material.dart';
import '../database/audit_database.dart';
import 'dart:async';

class SearchProvider with ChangeNotifier {
  List<Map<String, dynamic>> _results = [];
  List<Map<String, dynamic>> _favorites = [];
  List<Map<String, dynamic>> _recent = [];
  Timer? _searchTimer;
  
  List<Map<String, dynamic>> get results => _results;
  List<Map<String, dynamic>> get favorites => _favorites;
  List<Map<String, dynamic>> get recent => _recent;

  void initialize() {
    _loadFavorites();
    _loadRecent();
  }

  // Debounced search (100ms delay)
  void search(String query) {
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 100), () async {
      _results = await AuditDatabase.searchProducts(query);
      notifyListeners();
    });
  }

  // Instant barcode search
  Future<Map<String, dynamic>?> searchBarcode(String barcode) async {
    final results = await AuditDatabase.searchProducts(barcode);
    return results.isNotEmpty ? results.first : null;
  }

  // Toggle favorite
  void toggleFavorite(int productId) async {
    final db = await AuditDatabase.database;
    final product = await db.query('products', where: 'id = ?', whereArgs: [productId]);
    
    if (product.isNotEmpty) {
      final isFav = product.first['is_favorite'] == 1;
      await db.update(
        'products',
        {'is_favorite': isFav ? 0 : 1},
        where: 'id = ?',
        whereArgs: [productId],
      );
      _loadFavorites();
    }
  }

  void _loadFavorites() async {
    final db = await AuditDatabase.database;
    _favorites = await db.query(
      'products',
      where: 'is_favorite = 1 AND stock > 0',
      orderBy: 'name',
    );
    notifyListeners();
  }

  void _loadRecent() async {
    final db = await AuditDatabase.database;
    _recent = await db.query(
      'products',
      where: 'last_sold IS NOT NULL AND stock > 0',
      orderBy: 'last_sold DESC',
      limit: 20,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    super.dispose();
  }
}