import 'package:flutter/material.dart';
import '../models/supplier.dart';
import '../database/enhanced_database_helper.dart';

class SupplierProvider with ChangeNotifier {
  final EnhancedDatabaseHelper _db = EnhancedDatabaseHelper();
  List<Supplier> _suppliers = [];
  bool _isLoading = false;

  List<Supplier> get suppliers => _suppliers;
  bool get isLoading => _isLoading;

  Future<void> loadSuppliers() async {
    _isLoading = true;
    notifyListeners();

    try {
      final db = await _db.database;
      final maps = await db.query('suppliers', orderBy: 'name ASC');
      _suppliers = maps.map((map) => Supplier.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error loading suppliers: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addSupplier(Supplier supplier) async {
    try {
      final db = await _db.database;
      await db.insert('suppliers', supplier.toMap());
      await loadSuppliers();
      return true;
    } catch (e) {
      debugPrint('Error adding supplier: $e');
      return false;
    }
  }

  Future<bool> updateSupplier(Supplier supplier) async {
    try {
      final db = await _db.database;
      await db.update(
        'suppliers',
        supplier.toMap(),
        where: 'id = ?',
        whereArgs: [supplier.id],
      );
      await loadSuppliers();
      return true;
    } catch (e) {
      debugPrint('Error updating supplier: $e');
      return false;
    }
  }

  Future<bool> deleteSupplier(int supplierId) async {
    try {
      final db = await _db.database;
      await db.delete('suppliers', where: 'id = ?', whereArgs: [supplierId]);
      await loadSuppliers();
      return true;
    } catch (e) {
      debugPrint('Error deleting supplier: $e');
      return false;
    }
  }
}