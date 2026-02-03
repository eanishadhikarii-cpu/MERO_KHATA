import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/purchase_provider.dart';
import '../models/purchase.dart';

class AddPurchaseDialog extends StatefulWidget {
  const AddPurchaseDialog({super.key});

  @override
  State<AddPurchaseDialog> createState() => _AddPurchaseDialogState();
}

class _AddPurchaseDialogState extends State<AddPurchaseDialog> {
  final _amountController = TextEditingController();
  final _billController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Purchase'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _billController,
            decoration: const InputDecoration(labelText: 'Bill Number'),
          ),
          TextField(
            controller: _amountController,
            decoration: const InputDecoration(labelText: 'Amount'),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _savePurchase,
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _savePurchase() async {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount > 0) {
      final purchase = Purchase(
        billNumber: _billController.text,
        purchaseDate: DateTime.now(),
        totalAmount: amount,
        vatAmount: amount * 0.13,
        grandTotal: amount * 1.13,
        createdAt: DateTime.now(),
      );
      
      final success = await context.read<PurchaseProvider>().addPurchase(purchase);
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? 'Purchase added' : 'Failed to add purchase')),
      );
    }
  }
}