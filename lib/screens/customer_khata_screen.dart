import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/customer_provider.dart';

import '../models/customer.dart';

class CustomerKhataScreen extends StatefulWidget {
  const CustomerKhataScreen({super.key});

  @override
  State<CustomerKhataScreen> createState() => _CustomerKhataScreenState();
}

class _CustomerKhataScreenState extends State<CustomerKhataScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Customer> _filteredCustomers = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProvider>().loadCustomers();
      _updateFilteredCustomers();
    });
  }

  void _updateFilteredCustomers() {
    final customerProvider = context.read<CustomerProvider>();
    setState(() {
      _filteredCustomers = customerProvider.searchCustomers(_searchController.text);
    });
  }

  Future<void> _showAddCustomerDialog([Customer? customer]) async {
    final result = await showDialog<Customer>(
      context: context,
      builder: (context) => _AddCustomerDialog(customer: customer),
    );

    if (result != null) {
      final customerProvider = context.read<CustomerProvider>();
      bool success;
      
      if (customer == null) {
        success = await customerProvider.addCustomer(result);
      } else {
        success = await customerProvider.updateCustomer(result);
      }

      if (success) {
        _showMessage(customer == null ? 'Customer added' : 'Customer updated');
        _updateFilteredCustomers();
      } else {
        _showMessage('Error saving customer');
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Khata'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => _showAddCustomerDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary Cards
          Container(
            padding: const EdgeInsets.all(16),
            child: Consumer<CustomerProvider>(
              builder: (context, customerProvider, child) {
                final debtorCustomers = customerProvider.debtorCustomers;
                final totalDue = debtorCustomers.fold(0.0, (sum, c) => sum + c.balance);
                
                return Row(
                  children: [
                    Expanded(
                      child: Card(
                        color: Colors.red.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Icon(Icons.people, color: Colors.red),
                              const SizedBox(height: 8),
                              Text(
                                '${debtorCustomers.length}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                              const Text('Customers with Due'),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Card(
                        color: Colors.orange.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Icon(Icons.account_balance_wallet, color: Colors.orange),
                              const SizedBox(height: 8),
                              Text(
                                'Rs. ${totalDue.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                              const Text('Total Amount Due'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search customers...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => _updateFilteredCustomers(),
            ),
          ),

          const SizedBox(height: 16),

          // Customer List
          Expanded(
            child: Consumer<CustomerProvider>(
              builder: (context, customerProvider, child) {
                if (customerProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (_filteredCustomers.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No customers found',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: _filteredCustomers.length,
                  itemBuilder: (context, index) {
                    final customer = _filteredCustomers[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: customer.balance > 0 ? Colors.red : Colors.green,
                          child: Text(
                            customer.name.substring(0, 1).toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          customer.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (customer.phone != null)
                              Text('Phone: ${customer.phone}'),
                            Text(
                              'Balance: Rs. ${customer.balance.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: customer.balance > 0 ? Colors.red : Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit),
                                  SizedBox(width: 8),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'history',
                              child: Row(
                                children: [
                                  Icon(Icons.history),
                                  SizedBox(width: 8),
                                  Text('Transaction History'),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showAddCustomerDialog(customer);
                            } else if (value == 'history') {
                              _showCustomerHistory(customer);
                            }
                          },
                        ),
                        onTap: () => _showCustomerDetails(customer),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showCustomerDetails(Customer customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(customer.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (customer.phone != null)
              Text('Phone: ${customer.phone}'),
            const SizedBox(height: 8),
            Text('Total Debit: Rs. ${customer.totalDebit.toStringAsFixed(2)}'),
            Text('Total Credit: Rs. ${customer.totalCredit.toStringAsFixed(2)}'),
            const Divider(),
            Text(
              'Balance: Rs. ${customer.balance.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: customer.balance > 0 ? Colors.red : Colors.green,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showCustomerHistory(Customer customer) {
    // Show transaction history for customer
    _showMessage('Transaction history feature coming soon');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class _AddCustomerDialog extends StatefulWidget {
  final Customer? customer;

  const _AddCustomerDialog({this.customer});

  @override
  State<_AddCustomerDialog> createState() => _AddCustomerDialogState();
}

class _AddCustomerDialogState extends State<_AddCustomerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.customer != null) {
      _nameController.text = widget.customer!.name;
      _phoneController.text = widget.customer!.phone ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.customer == null ? 'Add Customer' : 'Edit Customer'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Customer Name *',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Customer name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveCustomer,
          child: Text(widget.customer == null ? 'Add' : 'Update'),
        ),
      ],
    );
  }

  void _saveCustomer() {
    if (_formKey.currentState!.validate()) {
      final now = DateTime.now();
      final customer = Customer(
        id: widget.customer?.id,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty 
            ? null 
            : _phoneController.text.trim(),
        totalDebit: widget.customer?.totalDebit ?? 0.0,
        totalCredit: widget.customer?.totalCredit ?? 0.0,
        balance: widget.customer?.balance ?? 0.0,
        createdAt: widget.customer?.createdAt ?? now,
        updatedAt: now,
      );

      Navigator.pop(context, customer);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}