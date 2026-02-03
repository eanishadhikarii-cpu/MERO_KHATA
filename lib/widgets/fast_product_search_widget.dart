import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/fast_search_provider.dart';
import '../models/product.dart';

class FastProductSearchWidget extends StatefulWidget {
  final Function(Product) onProductSelected;
  final bool autofocus;

  const FastProductSearchWidget({
    super.key,
    required this.onProductSelected,
    this.autofocus = true,
  });

  @override
  State<FastProductSearchWidget> createState() => _FastProductSearchWidgetState();
}

class _FastProductSearchWidgetState extends State<FastProductSearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FastSearchProvider>().initialize();
      if (widget.autofocus) {
        _searchFocusNode.requestFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FastSearchProvider>(
      builder: (context, searchProvider, child) {
        return Column(
          children: [
            // Search Input with keyboard shortcuts
            Container(
              padding: const EdgeInsets.all(16),
              child: RawKeyboardListener(
                focusNode: FocusNode(),
                onKey: _handleKeyPress,
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  decoration: InputDecoration(
                    hintText: 'Search products, scan barcode...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: _clearSearch,
                          )
                        : null,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (query) {
                    searchProvider.searchProducts(query);
                    setState(() {
                      _selectedIndex = 0;
                    });
                  },
                  onSubmitted: (_) => _selectCurrentProduct(searchProvider),
                ),
              ),
            ),

            // Quick Access Buttons
            if (_searchController.text.isEmpty) ...[
              Container(
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showFavorites(searchProvider),
                        icon: const Icon(Icons.star, size: 20),
                        label: const Text('Favorites'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showRecent(searchProvider),
                        icon: const Icon(Icons.history, size: 20),
                        label: const Text('Recent'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Search Results
            Expanded(
              child: _buildSearchResults(searchProvider),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchResults(FastSearchProvider searchProvider) {
    final results = _searchController.text.isEmpty
        ? [...searchProvider.favoriteProducts, ...searchProvider.recentProducts]
        : searchProvider.searchResults;

    if (searchProvider.isSearching) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchController.text.isEmpty ? Icons.inventory : Icons.search_off,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty 
                  ? 'No products available' 
                  : 'No products found',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final product = results[index];
        final isSelected = index == _selectedIndex;
        
        return Container(
          color: isSelected ? Colors.blue.withOpacity(0.1) : null,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: product.stockQuantity <= 5 ? Colors.red : Colors.green,
              child: Text(
                product.stockQuantity.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    product.name,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                if (searchProvider.favoriteProducts.any((p) => p.id == product.id))
                  const Icon(Icons.star, color: Colors.orange, size: 16),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Rs. ${product.sellingPrice.toStringAsFixed(2)}',
                  overflow: TextOverflow.ellipsis,
                ),
                if (product.barcode != null)
                  Text(
                    'Barcode: ${product.barcode}', 
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Stock: ${product.stockQuantity}',
                  style: TextStyle(
                    color: product.stockQuantity <= 5 ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                IconButton(
                  icon: Icon(
                    searchProvider.favoriteProducts.any((p) => p.id == product.id)
                        ? Icons.star
                        : Icons.star_border,
                    color: Colors.orange,
                    size: 20,
                  ),
                  onPressed: () => searchProvider.toggleFavorite(product.id!),
                ),
              ],
            ),
            onTap: () => widget.onProductSelected(product),
          ),
        );
      },
    );
  }

  void _handleKeyPress(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      final searchProvider = context.read<FastSearchProvider>();
      final results = _searchController.text.isEmpty
          ? [...searchProvider.favoriteProducts, ...searchProvider.recentProducts]
          : searchProvider.searchResults;

      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        setState(() {
          _selectedIndex = (_selectedIndex + 1) % results.length;
        });
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        setState(() {
          _selectedIndex = (_selectedIndex - 1 + results.length) % results.length;
        });
      } else if (event.logicalKey == LogicalKeyboardKey.enter) {
        _selectCurrentProduct(searchProvider);
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        _clearSearch();
      }
    }
  }

  void _selectCurrentProduct(FastSearchProvider searchProvider) {
    final results = _searchController.text.isEmpty
        ? [...searchProvider.favoriteProducts, ...searchProvider.recentProducts]
        : searchProvider.searchResults;

    if (results.isNotEmpty && _selectedIndex < results.length) {
      widget.onProductSelected(results[_selectedIndex]);
    }
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<FastSearchProvider>().clearSearch();
    setState(() {
      _selectedIndex = 0;
    });
    _searchFocusNode.requestFocus();
  }

  void _showFavorites(FastSearchProvider searchProvider) {
    _searchController.clear();
    searchProvider.clearSearch();
    // Favorites are already shown when search is empty
  }

  void _showRecent(FastSearchProvider searchProvider) {
    _searchController.clear();
    searchProvider.clearSearch();
    // Recent items are already shown when search is empty
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }
}

// Barcode Scanner Integration Widget
class BarcodeSearchWidget extends StatelessWidget {
  final Function(Product) onProductFound;

  const BarcodeSearchWidget({
    super.key,
    required this.onProductFound,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<FastSearchProvider>(
      builder: (context, searchProvider, child) {
        return ElevatedButton.icon(
          onPressed: () => _scanBarcode(context, searchProvider),
          icon: const Icon(Icons.qr_code_scanner),
          label: const Text('SCAN'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.all(16),
          ),
        );
      },
    );
  }

  Future<void> _scanBarcode(BuildContext context, FastSearchProvider searchProvider) async {
    try {
      // This would integrate with your existing barcode scanner
      // For now, showing a mock implementation
      final barcode = await _mockBarcodeScanner(context);
      
      if (barcode != null) {
        final product = await searchProvider.searchByBarcode(barcode);
        if (product != null) {
          onProductFound(product);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product not found')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Scan error: $e')),
      );
    }
  }

  Future<String?> _mockBarcodeScanner(BuildContext context) async {
    // Replace with actual barcode scanner implementation
    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mock Barcode Scanner'),
        content: const TextField(
          decoration: InputDecoration(hintText: 'Enter barcode'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, '1234567890'),
            child: const Text('Scan'),
          ),
        ],
      ),
    );
  }
}