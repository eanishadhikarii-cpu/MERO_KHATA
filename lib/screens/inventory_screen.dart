import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../models/product.dart';
import '../widgets/add_product_dialog.dart';

class InventoryScreen extends StatefulWidget {
  final bool showLowStockOnly;
  
  const InventoryScreen({
    super.key,
    this.showLowStockOnly = false,
  });

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Product> _filteredProducts = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateFilteredProducts();
    });
  }

  void _updateFilteredProducts() {
    final inventory = context.read<InventoryProvider>();
    List<Product> products = widget.showLowStockOnly 
        ? inventory.lowStockProducts 
        : inventory.products;
    
    if (_searchController.text.isNotEmpty) {
      products = products.where((product) =>
          product.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          (product.barcode?.contains(_searchController.text) ?? false)
      ).toList();
    }
    
    setState(() {
      _filteredProducts = products;
    });
  }

  Future<void> _showAddProductDialog([Product? product]) async {
    final result = await showDialog<Product>(
      context: context,
      builder: (context) => AddProductDialog(product: product),
    );

    if (result != null) {
      final inventory = context.read<InventoryProvider>();
      bool success;
      
      if (product == null) {
        success = await inventory.addProduct(result);
      } else {
        success = await inventory.updateProduct(result);
      }

      if (success) {
        _showMessage(product == null ? 'Product added' : 'Product updated');
        _updateFilteredProducts();
      } else {
        _showMessage('Error saving product');
      }
    }
  }

  Future<void> _deleteProduct(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await context.read<InventoryProvider>().deleteProduct(product.id!);
      if (success) {
        _showMessage('Product deleted');
        _updateFilteredProducts();
      } else {
        _showMessage('Error deleting product');
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
        title: Text(widget.showLowStockOnly ? 'Low Stock Items' : 'Inventory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddProductDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search products...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => _updateFilteredProducts(),
            ),
          ),

          // Products List
          Expanded(
            child: Consumer<InventoryProvider>(
              builder: (context, inventory, child) {
                if (inventory.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (_filteredProducts.isEmpty) {
                  return const Center(
                    child: Text('No products found'),
                  );
                }

                return ListView.builder(
                  itemCount: _filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = _filteredProducts[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        title: Text(product.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Price: Rs. ${product.sellingPrice.toStringAsFixed(2)}'),
                            Text(
                              'Stock: ${product.stockQuantity}',
                              style: TextStyle(
                                color: product.stockQuantity <= 5
                                    ? Colors.red
                                    : Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (product.barcode != null)
                              Text('Barcode: ${product.barcode}'),
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
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete'),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showAddProductDialog(product);
                            } else if (value == 'delete') {
                              _deleteProduct(product);
                            }
                          },
                        ),
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}