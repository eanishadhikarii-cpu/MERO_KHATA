import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/emi.dart';

class EMIProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  List<EMI> _emis = [];
  List<EMIPayment> _duePayments = [];
  bool _isLoading = false;

  List<EMI> get emis => _emis;
  List<EMI> get activeEMIs => _emis.where((emi) => !emi.isCompleted).toList();
  List<EMIPayment> get duePayments => _duePayments;
  bool get isLoading => _isLoading;

  double get totalOutstanding {
    return activeEMIs.fold(0.0, (sum, emi) => sum + emi.remainingBalance);
  }

  double get monthlyEMITotal {
    return activeEMIs.fold(0.0, (sum, emi) => sum + emi.emiAmount);
  }

  Future<void> loadEMIs() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _emis = await _db.getEMIs();
      _duePayments = await _db.getDueEMIPayments();
    } catch (e) {
      debugPrint('Error loading EMIs: $e');
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addEMI(EMI emi) async {
    try {
      await _db.insertEMI(emi);
      await loadEMIs();
    } catch (e) {
      debugPrint('Error adding EMI: $e');
      throw e;
    }
  }

  Future<void> markPaymentAsPaid(int paymentId, double amount) async {
    try {
      await _db.markEMIPaymentAsPaid(paymentId, amount);
      await loadEMIs();
    } catch (e) {
      debugPrint('Error marking payment as paid: $e');
      throw e;
    }
  }
}