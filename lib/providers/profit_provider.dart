import 'package:flutter/material.dart';
import '../database/enhanced_database_helper.dart';

class ProfitProvider with ChangeNotifier {
  final EnhancedDatabaseHelper _db = EnhancedDatabaseHelper();
  bool _isLoading = false;

  // Financial metrics
  double _totalSales = 0.0;
  double _cashSales = 0.0;
  double _creditSales = 0.0;
  double _grossProfit = 0.0;
  double _totalExpenses = 0.0;
  double _vatCollected = 0.0;
  double _vatPaid = 0.0;
  int _totalTransactions = 0;
  Map<String, double> _expensesByCategory = {};

  // Getters
  bool get isLoading => _isLoading;
  double get totalSales => _totalSales;
  double get cashSales => _cashSales;
  double get creditSales => _creditSales;
  double get grossProfit => _grossProfit;
  double get totalExpenses => _totalExpenses;
  double get vatCollected => _vatCollected;
  double get vatPaid => _vatPaid;
  double get vatPayable => _vatCollected - _vatPaid;
  double get netProfit => _grossProfit - _totalExpenses;
  int get totalTransactions => _totalTransactions;
  Map<String, double> get expensesByCategory => _expensesByCategory;

  double get averageSale => _totalTransactions > 0 ? _totalSales / _totalTransactions : 0.0;
  double get profitMargin => _totalSales > 0 ? (_grossProfit / _totalSales) * 100 : 0.0;

  Future<void> loadDailyProfit(DateTime date) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _calculateProfitForPeriod(date, date);
    } catch (e) {
      debugPrint('Error loading daily profit: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadMonthlyProfit(DateTime date) async {
    _isLoading = true;
    notifyListeners();

    try {
      final startOfMonth = DateTime(date.year, date.month, 1);
      final endOfMonth = DateTime(date.year, date.month + 1, 0);
      await _calculateProfitForPeriod(startOfMonth, endOfMonth);
    } catch (e) {
      debugPrint('Error loading monthly profit: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _calculateProfitForPeriod(DateTime startDate, DateTime endDate) async {
    final db = await _db.database;
    
    // Reset values
    _totalSales = 0.0;
    _cashSales = 0.0;
    _creditSales = 0.0;
    _grossProfit = 0.0;
    _totalExpenses = 0.0;
    _vatCollected = 0.0;
    _vatPaid = 0.0;
    _totalTransactions = 0;
    _expensesByCategory = {};

    final startDateStr = startDate.toIso8601String().split('T')[0];
    final endDateStr = endDate.toIso8601String().split('T')[0];

    // Calculate sales metrics
    final salesResult = await db.rawQuery('''
      SELECT 
        COUNT(*) as transaction_count,
        COALESCE(SUM(grand_total), 0) as total_sales,
        COALESCE(SUM(vat_amount), 0) as vat_collected,
        COALESCE(SUM(profit_amount), 0) as gross_profit,
        COALESCE(SUM(CASE WHEN sale_type = 'cash' THEN grand_total ELSE 0 END), 0) as cash_sales,
        COALESCE(SUM(CASE WHEN sale_type = 'credit' THEN grand_total ELSE 0 END), 0) as credit_sales
      FROM sales 
      WHERE DATE(sale_date) BETWEEN ? AND ?
    ''', [startDateStr, endDateStr]);

    if (salesResult.isNotEmpty) {
      final row = salesResult.first;
      _totalTransactions = row['transaction_count'] as int;
      _totalSales = (row['total_sales'] as num).toDouble();
      _vatCollected = (row['vat_collected'] as num).toDouble();
      _grossProfit = (row['gross_profit'] as num).toDouble();
      _cashSales = (row['cash_sales'] as num).toDouble();
      _creditSales = (row['credit_sales'] as num).toDouble();
    }

    // Calculate VAT paid on purchases
    final vatPaidResult = await db.rawQuery('''
      SELECT COALESCE(SUM(vat_amount), 0) as vat_paid
      FROM purchases 
      WHERE DATE(purchase_date) BETWEEN ? AND ?
    ''', [startDateStr, endDateStr]);

    if (vatPaidResult.isNotEmpty) {
      _vatPaid = (vatPaidResult.first['vat_paid'] as num).toDouble();
    }

    // Calculate expenses
    final expensesResult = await db.rawQuery('''
      SELECT 
        category,
        COALESCE(SUM(amount), 0) as total_amount
      FROM expenses 
      WHERE DATE(expense_date) BETWEEN ? AND ?
      GROUP BY category
    ''', [startDateStr, endDateStr]);

    for (final row in expensesResult) {
      final category = row['category'] as String;
      final amount = (row['total_amount'] as num).toDouble();
      _expensesByCategory[category] = amount;
      _totalExpenses += amount;
    }
  }
}