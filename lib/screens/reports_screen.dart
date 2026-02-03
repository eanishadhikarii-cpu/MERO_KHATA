import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sales_provider.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SalesProvider>().loadSales();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
      ),
      body: Consumer<SalesProvider>(
        builder: (context, salesProvider, child) {
          if (salesProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Today's Summary
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Today\'s Summary',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSummaryRow(
                          'Total Sales',
                          'Rs. ${salesProvider.todaysTotalSales.toStringAsFixed(2)}',
                          Colors.green,
                        ),
                        _buildSummaryRow(
                          'Total Transactions',
                          '${salesProvider.todaySales.length}',
                          Colors.blue,
                        ),
                        _buildSummaryRow(
                          'Estimated Profit',
                          'Rs. ${salesProvider.todaysProfit.toStringAsFixed(2)}',
                          Colors.orange,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Credit Sales Summary
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Credit Sales',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSummaryRow(
                          'Total Credit Amount',
                          'Rs. ${salesProvider.totalCreditAmount.toStringAsFixed(2)}',
                          Colors.red,
                        ),
                        _buildSummaryRow(
                          'Credit Transactions',
                          '${salesProvider.creditSales.length}',
                          Colors.red,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Recent Sales
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Recent Sales',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (salesProvider.sales.isEmpty)
                          const Text('No sales recorded')
                        else
                          ...salesProvider.sales.take(10).map((sale) {
                            return ListTile(
                              title: Text('Bill: ${sale.billNumber}'),
                              subtitle: Text(
                                '${sale.saleDate.day}/${sale.saleDate.month}/${sale.saleDate.year} - '
                                '${sale.items.length} items',
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Rs. ${sale.grandTotal.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (sale.isCredit)
                                    const Text(
                                      'CREDIT',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }).toList(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}