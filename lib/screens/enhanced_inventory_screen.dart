import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../services/smart_analytics_service.dart';
import '../models/product.dart';
import '../widgets/add_product_dialog.dart';

class EnhancedInventoryScreen extends StatefulWidget {
  final bool showLowStockOnly;

  const EnhancedInventoryScreen({
    super.key,
    this.showLowStockOnly = false,
  });

  @override
  State<EnhancedInventoryScreen> createState() => _EnhancedInventoryScreenState();
}

class _EnhancedInventoryScreenState extends State<EnhancedInventoryScreen> {
  final SmartAnalyticsService _analytics = SmartAnalyticsService();
  List<StockPrediction> _predictions = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _sortBy = 'name'; // name, stock, prediction

  @override
  void initState() {
    super.initState();
    _loadPredictions();
  }

  Future<void> _loadPredictions() async {
    setState(() => _isLoading = true);
    
    try {
      final predictions = await _analytics.getStockPredictions();
      setState(() {
        _predictions = predictions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<StockPrediction> get _filteredPredictions {
    var filtered = _predictions.where((p) {
      if (widget.showLowStockOnly) {
        return p.status == StockStatus.critical || p.status == StockStatus.warning;
      }
      if (_searchQuery.isNotEmpty) {
        return p.product.name.toLowerCase().contains(_searchQuery.toLowerCase());
      }
      return true;
    }).toList();

    // Sort predictions
    switch (_sortBy) {
      case 'stock':
        filtered.sort((a, b) => a.product.stockQuantity.compareTo(b.product.stockQuantity));
        break;
      case 'prediction':
        filtered.sort((a, b) => a.daysRemaining.compareTo(b.daysRemaining));
        break;
      default:
        filtered.sort((a, b) => a.product.name.compareTo(b.product.name));
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.showLowStockOnly ? 'Low Stock Items' : 'Smart Inventory'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() => _sortBy = value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'name', child: Text('Sort by Name')),
              const PopupMenuItem(value: 'stock', child: Text('Sort by Stock')),
              const PopupMenuItem(value: 'prediction', child: Text('Sort by Days Left')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Stats
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search bar
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
                const SizedBox(height: 12),
                
                // Stock status summary
                if (!_isLoading) _buildStockSummary(),
              ],
            ),
          ),

          // Product list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredPredictions.isEmpty
                    ? const Center(
                        child: Text(
                          'No products found',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadPredictions,
                        child: ListView.builder(
                          itemCount: _filteredPredictions.length,
                          itemBuilder: (context, index) {
                            final prediction = _filteredPredictions[index];
                            return _buildProductCard(prediction);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddProductDialog,
        backgroundColor: Colors.blue[600],
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildStockSummary() {
    final critical = _predictions.where((p) => p.status == StockStatus.critical).length;
    final warning = _predictions.where((p) => p.status == StockStatus.warning).length;
    final safe = _predictions.where((p) => p.status == StockStatus.safe).length;

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard('Critical', critical, Colors.red),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSummaryCard('Warning', warning, Colors.orange),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSummaryCard('Safe', safe, Colors.green),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(StockPrediction prediction) {
    final product = prediction.product;
    final statusColor = _getStatusColor(prediction.status);
    final profitMargin = product.sellingPrice - product.costPrice;
    final marginPercent = product.costPrice > 0 
        ? (profitMargin / product.costPrice * 100) 
        : 0.0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Container(
          width: 12,
          height: 60,
          decoration: BoxDecoration(
            color: statusColor,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                product.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            _buildProfitIndicator(marginPercent),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Text('Stock: ${product.stockQuantity}'),
                const SizedBox(width: 16),
                Text(
                  prediction.daysRemaining < 999 
                      ? '${prediction.daysRemaining} days left'
                      : 'No sales data',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (prediction.suggestedOrder > 0)
              Text(
                'Suggested order: ${prediction.suggestedOrder} units',
                style: TextStyle(
                  color: Colors.blue[600],
                  fontSize: 12,
                ),
              ),
            Row(
              children: [
                Text('Cost: Rs. ${product.costPrice}'),
                const SizedBox(width: 16),
                Text('Sell: Rs. ${product.sellingPrice}'),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleProductAction(value, product),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
        onTap: () => _showProductDetails(prediction),
      ),
    );
  }

  Widget _buildProfitIndicator(double marginPercent) {
    Color color;
    IconData icon;
    
    if (marginPercent >= 30) {
      color = Colors.green;
      icon = Icons.trending_up;
    } else if (marginPercent >= 15) {
      color = Colors.orange;
      icon = Icons.trending_flat;
    } else {
      color = Colors.red;
      icon = Icons.trending_down;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 2),
          Text(
            '${marginPercent.toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(StockStatus status) {
    switch (status) {
      case StockStatus.critical:
        return Colors.red;
      case StockStatus.warning:
        return Colors.orange;
      case StockStatus.safe:
        return Colors.green;
    }
  }

  void _showProductDetails(StockPrediction prediction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(prediction.product.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current Stock: ${prediction.product.stockQuantity}'),
            Text('Daily Consumption: ${prediction.dailyConsumption.toStringAsFixed(1)}'),
            Text('Days Remaining: ${prediction.daysRemaining}'),
            if (prediction.suggestedOrder > 0)
              Text('Suggested Order: ${prediction.suggestedOrder} units'),
            const SizedBox(height: 8),
            Text('Cost Price: Rs. ${prediction.product.costPrice}'),
            Text('Selling Price: Rs. ${prediction.product.sellingPrice}'),
            Text('VAT: ${prediction.product.vatPercent}%'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _handleProductAction(String action, Product product) {
    switch (action) {
      case 'edit':
        _showEditProductDialog(product);
        break;
      case 'delete':
        _confirmDeleteProduct(product);
        break;
    }
  }

  void _showAddProductDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddProductDialog(),
    ).then((_) => _loadPredictions());
  }

  void _showEditProductDialog(Product product) {
    showDialog(
      context: context,
      builder: (context) => AddProductDialog(product: product),
    ).then((_) => _loadPredictions());
  }

  void _confirmDeleteProduct(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete ${product.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await context.read<InventoryProvider>().deleteProduct(product.id!);
              _loadPredictions();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}