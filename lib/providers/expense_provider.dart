import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../database/enhanced_database_helper.dart';

class ExpenseProvider with ChangeNotifier {
  final EnhancedDatabaseHelper _db = EnhancedDatabaseHelper();
  List<Expense> _expenses = [];
  bool _isLoading = false;

  List<Expense> get expenses => _expenses;
  bool get isLoading => _isLoading;

  double get todayExpenses {
    final today = DateTime.now();
    return _expenses
        .where((e) => _isSameDay(e.expenseDate, today))
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  double get monthlyExpenses {
    final now = DateTime.now();
    return _expenses
        .where((e) => e.expenseDate.month == now.month && e.expenseDate.year == now.year)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  double get totalExpenses {
    return _expenses.fold(0.0, (sum, e) => sum + e.amount);
  }

  Map<String, double> get expensesByCategory {
    final Map<String, double> categoryTotals = {};
    for (final expense in _expenses) {
      categoryTotals[expense.category] = 
          (categoryTotals[expense.category] ?? 0) + expense.amount;
    }
    return categoryTotals;
  }

  Future<void> loadExpenses() async {
    _isLoading = true;
    notifyListeners();

    try {
      final db = await _db.database;
      final maps = await db.query('expenses', orderBy: 'expense_date DESC');
      _expenses = maps.map((map) => Expense.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error loading expenses: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addExpense(Expense expense) async {
    try {
      final db = await _db.database;
      await db.insert('expenses', expense.toMap());
      await loadExpenses();
      return true;
    } catch (e) {
      debugPrint('Error adding expense: $e');
      return false;
    }
  }

  Future<bool> deleteExpense(int expenseId) async {
    try {
      final db = await _db.database;
      await db.delete('expenses', where: 'id = ?', whereArgs: [expenseId]);
      await loadExpenses();
      return true;
    } catch (e) {
      debugPrint('Error deleting expense: $e');
      return false;
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }
}