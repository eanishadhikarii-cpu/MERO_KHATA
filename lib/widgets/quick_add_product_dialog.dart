import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/inventory_provider.dart';

class QuickAddProductDialog extends StatefulWidget {
  const QuickAddProductDialog({super.key});

  @override
  State<QuickAddProductDialog> createState() => _QuickAddProductDialogState();
}

class _QuickAddProductDialogState extends State<QuickAddProductDialog> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController stockController = TextEditingController();
  final TextEditingController barcodeController = TextEditingController();
  
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 400,
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Quick Add Product',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Product Name *',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            SizedBox(height: 12),
            
            TextField(
              controller: priceController,
              decoration: InputDecoration(
                labelText: 'Selling Price *',
                border: OutlineInputBorder(),
                prefixText: 'Rs. ',
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 12),
            
            TextField(
              controller: stockController,
              decoration: InputDecoration(
                labelText: 'Stock Quantity',
                border: OutlineInputBorder(),
                hintText: '1',
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 12),
            
            TextField(
              controller: barcodeController,
              decoration: InputDecoration(
                labelText: 'Barcode (Optional)',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                    child: Text('Cancel'),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _addProduct,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: isLoading 
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text('Add Product'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _addProduct() async {
    if (nameController.text.trim().isEmpty || priceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill required fields')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final product = Product(
        name: nameController.text.trim(),
        barcode: barcodeController.text.trim().isEmpty ? null : barcodeController.text.trim(),
        costPrice: double.parse(priceController.text) * 0.8, // Assume 20% margin
        sellingPrice: double.parse(priceController.text),
        vatPercent: 13.0,
        stockQuantity: int.tryParse(stockController.text) ?? 1,
        category: 'General',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await Provider.of<InventoryProvider>(context, listen: false).addProduct(product);
      
      Navigator.pop(context, product);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Product added successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding product: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }
}