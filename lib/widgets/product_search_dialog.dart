import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../models/product.dart';

class ProductSearchDialog extends StatefulWidget {
  const ProductSearchDialog({super.key});

  @override
  State<ProductSearchDialog> createState() => _ProductSearchDialogState();
}

class _ProductSearchDialogState extends State<ProductSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<Product> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _searchResults = context.read<InventoryProvider>().products;
  }

  void _performSearch(String query) {
    final inventory = context.read<InventoryProvider>();
    setState(() {
      _searchResults = inventory.searchProducts(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Search Products',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Search Field
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search by name or barcode...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _performSearch,
              autofocus: true,
            ),
            
            const SizedBox(height: 16),
            
            // Search Results
            Expanded(
              child: _searchResults.isEmpty
                  ? const Center(
                      child: Text('No products found'),
                    )
                  : ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final product = _searchResults[index];
                        return Card(
                          child: ListTile(
                            title: Text(product.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Rs. ${product.sellingPrice.toStringAsFixed(2)}'),
                                Text(
                                  'Stock: ${product.stockQuantity}',
                                  style: TextStyle(
                                    color: product.stockQuantity > 0
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            trailing: product.stockQuantity > 0
                                ? const Icon(Icons.add_shopping_cart)
                                : const Icon(Icons.block, color: Colors.red),
                            onTap: product.stockQuantity > 0
                                ? () => Navigator.pop(context, product)
                                : null,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}