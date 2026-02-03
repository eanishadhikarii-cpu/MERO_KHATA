import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../database/database_helper.dart';

class CustomerProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  List<Customer> _customers = [];
  bool _isLoading = false;

  List<Customer> get customers => _customers;
  bool get isLoading => _isLoading;

  List<Customer> get debtorCustomers => 
      _customers.where((c) => c.balance > 0).toList();

  Future<void> loadCustomers() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _customers = await _db.getCustomers();
    } catch (e) {
      debugPrint('Error loading customers: $e');
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addCustomer(Customer customer) async {
    try {
      final id = await _db.insertCustomer(customer);
      if (id > 0) {
        await loadCustomers();
        return true;
      }
    } catch (e) {
      debugPrint('Error adding customer: $e');
    }
    return false;
  }

  Future<bool> updateCustomer(Customer customer) async {
    try {
      final result = await _db.updateCustomer(customer);
      if (result > 0) {
        await loadCustomers();
        return true;
      }
    } catch (e) {
      debugPrint('Error updating customer: $e');
    }
    return false;
  }

  Future<Customer?> getCustomerByPhone(String phone) async {
    try {
      return await _db.getCustomerByPhone(phone);
    } catch (e) {
      debugPrint('Error getting customer by phone: $e');
      return null;
    }
  }

  List<Customer> searchCustomers(String query) {
    if (query.isEmpty) return _customers;
    
    return _customers.where((customer) =>
        customer.name.toLowerCase().contains(query.toLowerCase()) ||
        (customer.phone?.contains(query) ?? false)
    ).toList();
  }
}