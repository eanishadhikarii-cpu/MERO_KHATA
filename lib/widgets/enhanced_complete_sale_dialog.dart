import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/customer.dart';

import '../providers/customer_provider.dart';
import '../providers/sales_provider.dart';


class EnhancedCompleteSaleDialog extends StatefulWidget {
  const EnhancedCompleteSaleDialog({super.key});

  @override
  State<EnhancedCompleteSaleDialog> createState() => _EnhancedCompleteSaleDialogState();
}

class _EnhancedCompleteSaleDialogState extends State<EnhancedCompleteSaleDialog> {
  String saleType = 'cash';
  String paymentMethod = 'Cash';
  Customer? selectedCustomer;
  String customerPhone = '';
  String customerName = '';
  double billDiscount = 0.0;
  double roundingAdjustment = 0.0;
  String notes = '';
  bool roundingEnabled = true;
  double roundingAmount = 1.0;
  Map<String, double> itemDiscounts = {};
  Map<String, double> overriddenPrices = {};
  
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController billDiscountController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    roundingEnabled = false;
    roundingAmount = 1.0;
  }

  double get itemTotal {
    final salesProvider = Provider.of<SalesProvider>(context, listen: false);
    return salesProvider.currentSaleTotal;
  }

  double get vatAmount => itemTotal * 0.13;
  
  double get discountedTotal => itemTotal + vatAmount - billDiscount;
  
  double get finalTotal {
    double total = discountedTotal;
    if (roundingEnabled) {
      double remainder = total % roundingAmount;
      if (remainder >= roundingAmount / 2) {
        roundingAdjustment = roundingAmount - remainder;
        total += roundingAdjustment;
      } else {
        roundingAdjustment = -remainder;
        total -= remainder;
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Complete Sale', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sale Type
                    Text('Sale Type:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: Text('Cash'),
                            value: 'cash',
                            groupValue: saleType,
                            onChanged: (value) => setState(() => saleType = value!),
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: Text('Credit'),
                            value: 'credit',
                            groupValue: saleType,
                            onChanged: (value) => setState(() => saleType = value!),
                          ),
                        ),
                      ],
                    ),
                    
                    // Customer Selection (for credit sales)
                    if (saleType == 'credit') ...[
                      SizedBox(height: 16),
                      Text('Customer:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: phoneController,
                              decoration: InputDecoration(
                                labelText: 'Phone Number',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: _searchCustomerByPhone,
                            ),
                          ),
                          SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _showCustomerSearch,
                            child: Text('Search'),
                          ),
                        ],
                      ),
                      if (selectedCustomer != null)
                        Card(
                          child: ListTile(
                            title: Text(selectedCustomer!.name),
                            subtitle: Text('Balance: Rs. ${selectedCustomer!.balance.toStringAsFixed(2)}'),
                            trailing: IconButton(
                              icon: Icon(Icons.clear),
                              onPressed: () => setState(() => selectedCustomer = null),
                            ),
                          ),
                        ),
                      if (selectedCustomer == null)
                        TextField(
                          controller: nameController,
                          decoration: InputDecoration(
                            labelText: 'Customer Name',
                            border: OutlineInputBorder(),
                          ),
                        ),
                    ],
                    
                    SizedBox(height: 16),
                    
                    // Payment Method
                    Text('Payment Method:', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButton<String>(
                      value: paymentMethod,
                      isExpanded: true,
                      items: ['Cash', 'eSewa', 'Khalti', 'FonePay']
                          .map((method) => DropdownMenuItem(value: method, child: Text(method)))
                          .toList(),
                      onChanged: (value) => setState(() => paymentMethod = value!),
                    ),
                    
                    SizedBox(height: 16),
                    
                    // Items display
                    Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Consumer<SalesProvider>(
                      builder: (context, salesProvider, child) {
                        return Column(
                          children: salesProvider.currentSaleItems.map((item) => 
                            Card(
                              child: ListTile(
                                title: Text(item.productName),
                                subtitle: Text('Qty: ${item.quantity}'),
                                trailing: Text('Rs. ${item.totalAmount.toStringAsFixed(2)}'),
                              ),
                            )
                          ).toList(),
                        );
                      },
                    ),
                    
                    SizedBox(height: 16),
                    
                    // Bill Discount
                    TextField(
                      controller: billDiscountController,
                      decoration: InputDecoration(
                        labelText: 'Bill Discount (Rs.)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {
                          billDiscount = double.tryParse(value) ?? 0.0;
                        });
                      },
                    ),
                    
                    SizedBox(height: 16),
                    
                    // Notes
                    TextField(
                      controller: notesController,
                      decoration: InputDecoration(
                        labelText: 'Notes/Remarks',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                      onChanged: (value) => notes = value,
                    ),
                    
                    SizedBox(height: 16),
                    
                    // Total Summary
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Subtotal:'),
                                Text('Rs. ${itemTotal.toStringAsFixed(2)}'),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('VAT (13%):'),
                                Text('Rs. ${vatAmount.toStringAsFixed(2)}'),
                              ],
                            ),
                            if (billDiscount > 0)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Bill Discount:'),
                                  Text('- Rs. ${billDiscount.toStringAsFixed(2)}'),
                                ],
                              ),
                            if (roundingAdjustment != 0)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Rounding:'),
                                  Text('${roundingAdjustment >= 0 ? '+' : ''} Rs. ${roundingAdjustment.toStringAsFixed(2)}'),
                                ],
                              ),
                            Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                Text('Rs. ${finalTotal.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _completeSale,
                    child: Text('Complete Sale'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _searchCustomerByPhone(String phone) async {
    if (phone.length >= 3) {
      final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
      final customers = customerProvider.customers.where((c) => 
        c.phone?.contains(phone) == true || c.name.toLowerCase().contains(phone.toLowerCase())
      ).toList();
      
      if (customers.isNotEmpty) {
        setState(() {
          selectedCustomer = customers.first;
          phoneController.text = selectedCustomer!.phone ?? '';
        });
      }
    }
  }

  void _showCustomerSearch() {
    // Implementation for customer search dialog
  }

  void _completeSale() async {
    try {
      final salesProvider = Provider.of<SalesProvider>(context, listen: false);
      
      final success = await salesProvider.completeSale(
        saleType: saleType,
        paymentMethod: paymentMethod,
        customerId: selectedCustomer?.id,
        customerName: selectedCustomer?.name ?? nameController.text,
        customerPhone: selectedCustomer?.phone ?? phoneController.text,
      );
      
      if (success) {
        Navigator.pop(context, {
          'saleType': saleType,
          'paymentMethod': paymentMethod,
          'customerId': selectedCustomer?.id,
          'customerName': selectedCustomer?.name ?? nameController.text,
          'customerPhone': selectedCustomer?.phone ?? phoneController.text,
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error completing sale: $e')),
      );
    }
  }
}