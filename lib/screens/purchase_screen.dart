import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/purchase_provider.dart';
import '../providers/supplier_provider.dart';
import '../models/purchase.dart';
import '../widgets/add_purchase_dialog.dart';

class PurchaseScreen extends StatefulWidget {
  const PurchaseScreen({super.key});

  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PurchaseProvider>().loadPurchases();
      context.read<SupplierProvider>().loadSuppliers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddPurchaseDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary Cards
          Container(
            height: 100,
            padding: const EdgeInsets.all(8),
            child: Consumer<PurchaseProvider>(
              builder: (context, provider, child) {
                return Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        'Today Purchases',
                        'Rs. ${provider.todayPurchases.toStringAsFixed(0)}',
                        Icons.shopping_cart,
                        Colors.blue,
                      ),
                    ),
                    Expanded(
                      child: _buildSummaryCard(
                        'Pending Payments',
                        'Rs. ${provider.pendingPayments.toStringAsFixed(0)}',
                        Icons.payment,
                        Colors.orange,
                      ),
                    ),
                    Expanded(
                      child: _buildSummaryCard(
                        'This Month',
                        'Rs. ${provider.monthlyPurchases.toStringAsFixed(0)}',
                        Icons.calendar_month,
                        Colors.green,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Purchase List
          Expanded(
            child: Consumer<PurchaseProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.purchases.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No purchases yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: provider.purchases.length,
                  itemBuilder: (context, index) {
                    final purchase = provider.purchases[index];
                    return _buildPurchaseCard(purchase);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String amount, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 2),
            Text(
              title, 
              style: const TextStyle(fontSize: 9), 
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            const SizedBox(height: 2),
            Text(
              amount,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseCard(Purchase purchase) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: purchase.paymentStatus == 'paid' ? Colors.green : Colors.orange,
          child: Icon(
            purchase.paymentStatus == 'paid' ? Icons.check : Icons.pending,
            color: Colors.white,
          ),
        ),
        title: Text(
          'Bill: ${purchase.billNumber}',
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Date: ${purchase.purchaseDate.day}/${purchase.purchaseDate.month}/${purchase.purchaseDate.year}'),
            Text('Status: ${purchase.paymentStatus.toUpperCase()}'),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Rs. ${purchase.grandTotal.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'VAT: Rs. ${purchase.vatAmount.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        onTap: () => _showPurchaseDetails(purchase),
      ),
    );
  }

  void _showAddPurchaseDialog() {
    showDialog(
      context: context,
      builder: (context) => AddPurchaseDialog(),
    );
  }

  void _showPurchaseDetails(Purchase purchase) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Purchase Details - ${purchase.billNumber}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Date: ${purchase.purchaseDate.day}/${purchase.purchaseDate.month}/${purchase.purchaseDate.year}'),
            Text('Total: Rs. ${purchase.totalAmount.toStringAsFixed(2)}'),
            Text('VAT: Rs. ${purchase.vatAmount.toStringAsFixed(2)}'),
            Text('Grand Total: Rs. ${purchase.grandTotal.toStringAsFixed(2)}'),
            Text('Status: ${purchase.paymentStatus}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (purchase.paymentStatus == 'pending')
            ElevatedButton(
              onPressed: () => _markAsPaid(purchase),
              child: const Text('Mark as Paid'),
            ),
        ],
      ),
    );
  }

  void _markAsPaid(Purchase purchase) {
    context.read<PurchaseProvider>().markAsPaid(purchase.id!);
    Navigator.pop(context);
  }
}