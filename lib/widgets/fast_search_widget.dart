import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/search_provider.dart';

class FastSearchWidget extends StatefulWidget {
  final Function(Map<String, dynamic>) onProductSelected;

  const FastSearchWidget({super.key, required this.onProductSelected});

  @override
  State<FastSearchWidget> createState() => _FastSearchWidgetState();
}

class _FastSearchWidgetState extends State<FastSearchWidget> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    context.read<SearchProvider>().initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SearchProvider>(
      builder: (context, search, child) {
        final products = _controller.text.isEmpty 
            ? [...search.favorites, ...search.recent]
            : search.results;

        return Column(
          children: [
            // Search input with keyboard shortcuts
            RawKeyboardListener(
              focusNode: FocusNode(),
              onKey: (event) => _handleKeyPress(event, products),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                decoration: const InputDecoration(
                  hintText: 'Search products or scan barcode...',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (query) {
                  search.search(query);
                  _selectedIndex = 0;
                },
                onSubmitted: (_) => _selectProduct(products),
              ),
            ),
            
            // Quick access buttons
            if (_controller.text.isEmpty)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showFavorites(),
                      icon: const Icon(Icons.star),
                      label: const Text('Favorites'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showRecent(),
                      icon: const Icon(Icons.history),
                      label: const Text('Recent'),
                    ),
                  ),
                ],
              ),
            
            // Product list
            Expanded(
              child: ListView.builder(
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  final isSelected = index == _selectedIndex;
                  
                  return Container(
                    color: isSelected ? Colors.blue.withOpacity(0.1) : null,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: product['stock'] > 5 ? Colors.green : Colors.red,
                        child: Text('${product['stock']}'),
                      ),
                      title: Text(product['name']),
                      subtitle: Text('Rs. ${product['price']}'),
                      trailing: IconButton(
                        icon: Icon(
                          product['is_favorite'] == 1 ? Icons.star : Icons.star_border,
                          color: Colors.orange,
                        ),
                        onPressed: () => search.toggleFavorite(product['id']),
                      ),
                      onTap: () => widget.onProductSelected(product),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _handleKeyPress(RawKeyEvent event, List<Map<String, dynamic>> products) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        setState(() => _selectedIndex = (_selectedIndex + 1) % products.length);
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        setState(() => _selectedIndex = (_selectedIndex - 1 + products.length) % products.length);
      } else if (event.logicalKey == LogicalKeyboardKey.enter) {
        _selectProduct(products);
      }
    }
  }

  void _selectProduct(List<Map<String, dynamic>> products) {
    if (products.isNotEmpty && _selectedIndex < products.length) {
      widget.onProductSelected(products[_selectedIndex]);
    }
  }

  void _showFavorites() {
    _controller.clear();
    context.read<SearchProvider>().search('');
  }

  void _showRecent() {
    _controller.clear();
    context.read<SearchProvider>().search('');
  }
}