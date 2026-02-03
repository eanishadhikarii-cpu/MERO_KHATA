import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/inventory_provider.dart';
import '../providers/sales_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/customer_provider.dart';
import '../models/product.dart';
import 'admin_screen.dart';
import 'reports_screen.dart';
import 'customer_khata_screen.dart';
import 'barcode_scanner_screen.dart';
import 'emi_screen.dart';
import 'purchase_screen.dart';
import 'expense_screen.dart';
import 'profit_loss_screen.dart';
import '../widgets/sale_item_card.dart';
import '../widgets/product_search_dialog.dart';
import '../widgets/enhanced_complete_sale_dialog.dart';
import 'voice_ledger_screen.dart';
import 'smart_dashboard_screen.dart';

class WorkingHomeScreen extends StatefulWidget {
  const WorkingHomeScreen({super.key});

  @override
  State<WorkingHomeScreen> createState() => _WorkingHomeScreenState();
}

class _WorkingHomeScreenState extends State<WorkingHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryProvider>().loadProducts();
      context.read<SalesProvider>().loadSales();
      context.read<SettingsProvider>().loadSettings();
      context.read<CustomerProvider>().loadCustomers();
    });
  }

  Future<void> _scanBarcode() async {
    try {
      final result = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (context) => const BarcodeScannerScreen(),
        ),
      );
      
      if (result != null) {
        _handleScannedBarcode(result);
      }
    } catch (e) {
      _showMessage('Error scanning barcode: $e');
    }
  }

  Future<void> _handleScannedBarcode(String barcode) async {
    final product = await context.read<InventoryProvider>().getProductByBarcode(barcode);
    if (product != null) {
      _addProductToSale(product);
    } else {
      _showMessage('Product not found');
    }
  }

  void _addProductToSale(Product product) {
    if (product.stockQuantity > 0) {
      context.read<SalesProvider>().addItemToCurrentSale(product, 1);
    } else {
      _showMessage('Product out of stock');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _showProductSearch() async {
    final product = await showDialog<Product>(
      context: context,
      builder: (context) => const ProductSearchDialog(),
    );
    
    if (product != null) {
      _addProductToSale(product);
    }
  }

  Future<void> _completeSale() async {
    final salesProvider = context.read<SalesProvider>();
    if (salesProvider.currentSaleItems.isEmpty) {
      _showMessage('No items in cart');
      return;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const EnhancedCompleteSaleDialog(),
    );

    if (result != null) {
      final success = await salesProvider.completeSale(
        saleType: result['saleType'],
        paymentMethod: result['paymentMethod'],
        customerId: result['customerId'],
        customerName: result['customerName'],
        customerPhone: result['customerPhone'],
      );

      if (success) {
        _showMessage('Sale completed successfully');
      } else {
        _showMessage('Error completing sale');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Flexible(
              child: Text(
                'Mero Khata',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Offline',
                style: TextStyle(fontSize: 10, color: Colors.white),
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'customers':
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const CustomerKhataScreen()));
                  break;
                case 'purchases':
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const PurchaseScreen()));
                  break;
                case 'expenses':
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ExpenseScreen()));
                  break;
                case 'profit':
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfitLossScreen()));
                  break;
                case 'emi':
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const EMIScreen()));
                  break;
                case 'voice':
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const VoiceLedgerScreen()));
                  break;
                case 'dashboard':
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SmartDashboardScreen()));
                  break;
                case 'reports':
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ReportsScreen()));
                  break;
                case 'admin':
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminScreen()));
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'customers', child: Row(children: [Icon(Icons.people), SizedBox(width: 8), Expanded(child: Text('Customers', overflow: TextOverflow.ellipsis))])),
              PopupMenuItem(value: 'purchases', child: Row(children: [Icon(Icons.shopping_cart), SizedBox(width: 8), Expanded(child: Text('Purchases', overflow: TextOverflow.ellipsis))])),
              PopupMenuItem(value: 'expenses', child: Row(children: [Icon(Icons.receipt), SizedBox(width: 8), Expanded(child: Text('Expenses', overflow: TextOverflow.ellipsis))])),
              PopupMenuItem(value: 'profit', child: Row(children: [Icon(Icons.trending_up), SizedBox(width: 8), Expanded(child: Text('Profit & Loss', overflow: TextOverflow.ellipsis))])),
              PopupMenuItem(value: 'emi', child: Row(children: [Icon(Icons.account_balance), SizedBox(width: 8), Expanded(child: Text('EMI Tracker', overflow: TextOverflow.ellipsis))])),
              PopupMenuItem(value: 'voice', child: Row(children: [Icon(Icons.mic), SizedBox(width: 8), Expanded(child: Text('Voice Ledger', overflow: TextOverflow.ellipsis))])),
              PopupMenuItem(value: 'dashboard', child: Row(children: [Icon(Icons.dashboard), SizedBox(width: 8), Expanded(child: Text('Smart Dashboard', overflow: TextOverflow.ellipsis))])),
              PopupMenuItem(value: 'reports', child: Row(children: [Icon(Icons.analytics), SizedBox(width: 8), Expanded(child: Text('Reports', overflow: TextOverflow.ellipsis))])),
              PopupMenuItem(value: 'admin', child: Row(children: [Icon(Icons.admin_panel_settings), SizedBox(width: 8), Expanded(child: Text('Admin Panel', overflow: TextOverflow.ellipsis))])),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Daily Summary Cards
          Container(
            height: 120,
            padding: const EdgeInsets.all(8),
            child: Consumer<SalesProvider>(
              builder: (context, salesProvider, child) {
                return Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        'Today Sales',
                        'Rs. ${salesProvider.todaysTotalSales.toStringAsFixed(0)}',
                        Icons.trending_up,
                        Colors.green,
                      ),
                    ),
                    Expanded(
                      child: _buildSummaryCard(
                        'Cash Sales',
                        'Rs. ${salesProvider.cashSales.fold(0.0, (sum, sale) => sum + sale.grandTotal).toStringAsFixed(0)}',
                        Icons.account_balance_wallet,
                        Colors.blue,
                      ),
                    ),
                    Expanded(
                      child: _buildSummaryCard(
                        'Credit Due',
                        'Rs. ${salesProvider.totalCreditAmount.toStringAsFixed(0)}',
                        Icons.credit_card,
                        Colors.orange,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Quick Actions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _scanBarcode,
                    icon: const Icon(Icons.qr_code_scanner, size: 28),
                    label: const Text('SCAN', style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(20),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showProductSearch,
                    icon: const Icon(Icons.search, size: 28),
                    label: const Text('SEARCH', style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(20),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Current Sale Items
          Expanded(
            child: Consumer<SalesProvider>(
              builder: (context, salesProvider, child) {
                if (salesProvider.currentSaleItems.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No items in cart',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        Text(
                          'Scan or search products to add',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: salesProvider.currentSaleItems.length,
                  itemBuilder: (context, index) {
                    final item = salesProvider.currentSaleItems[index];
                    return SaleItemCard(
                      item: item,
                      onQuantityChanged: (quantity) {
                        salesProvider.updateItemQuantity(index, quantity);
                      },
                      onRemove: () {
                        salesProvider.removeItemFromCurrentSale(index);
                      },
                    );
                  },
                );
              },
            ),
          ),

          // Sale Summary & Complete Button
          Consumer<SalesProvider>(
            builder: (context, salesProvider, child) {
              if (salesProvider.currentSaleItems.isEmpty) {
                return const SizedBox.shrink();
              }

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal:', style: TextStyle(fontSize: 16)),
                        Text(
                          'Rs. ${salesProvider.currentSaleTotal.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 16),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('VAT:', style: TextStyle(fontSize: 16)),
                        Text(
                          'Rs. ${salesProvider.currentSaleVAT.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 16),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    const Divider(thickness: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'TOTAL:',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Rs. ${salesProvider.currentSaleGrandTotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _completeSale,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(20),
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text(
                          'COMPLETE SALE',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String amount, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            const SizedBox(height: 4),
            Text(
              amount,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}