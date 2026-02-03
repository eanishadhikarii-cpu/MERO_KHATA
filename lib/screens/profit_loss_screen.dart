import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/profit_provider.dart';

class ProfitLossScreen extends StatefulWidget {
  const ProfitLossScreen({super.key});

  @override
  State<ProfitLossScreen> createState() => _ProfitLossScreenState();
}

class _ProfitLossScreenState extends State<ProfitLossScreen> {
  DateTime selectedDate = DateTime.now();
  String viewMode = 'daily'; // 'daily' or 'monthly'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfitData();
    });
  }

  void _loadProfitData() {
    final provider = context.read<ProfitProvider>();
    if (viewMode == 'daily') {
      provider.loadDailyProfit(selectedDate);
    } else {
      provider.loadMonthlyProfit(selectedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profit & Loss'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _selectDate,
          ),
        ],
      ),
      body: Column(
        children: [
          // View Mode Toggle
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _changeViewMode('daily'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: viewMode == 'daily' ? Colors.blue : Colors.grey[300],
                    ),
                    child: const Text('Daily'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _changeViewMode('monthly'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: viewMode == 'monthly' ? Colors.blue : Colors.grey[300],
                    ),
                    child: const Text('Monthly'),
                  ),
                ),
              ],
            ),
          ),

          // Date Display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              viewMode == 'daily'
                  ? 'Date: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'
                  : 'Month: ${selectedDate.month}/${selectedDate.year}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),

          const SizedBox(height: 16),

          // Profit Summary
          Expanded(
            child: Consumer<ProfitProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Main Profit Card
                      _buildMainProfitCard(provider),
                      
                      const SizedBox(height: 16),
                      
                      // Revenue Breakdown
                      _buildRevenueCard(provider),
                      
                      const SizedBox(height: 16),
                      
                      // Expense Breakdown
                      _buildExpenseCard(provider),
                      
                      const SizedBox(height: 16),
                      
                      // VAT Summary
                      _buildVATCard(provider),
                      
                      const SizedBox(height: 16),
                      
                      // Quick Stats
                      _buildQuickStats(provider),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainProfitCard(ProfitProvider provider) {
    final netProfit = provider.netProfit;
    final isProfit = netProfit >= 0;
    
    return Card(
      color: isProfit ? Colors.green[50] : Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              isProfit ? Icons.trending_up : Icons.trending_down,
              size: 48,
              color: isProfit ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 8),
            Text(
              isProfit ? 'Net Profit' : 'Net Loss',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Rs. ${netProfit.abs().toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: isProfit ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              viewMode == 'daily' ? 'आज कति नाफा भयो?' : 'यो महिना कति नाफा भयो?',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueCard(ProfitProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Revenue Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildStatRow('Total Sales', provider.totalSales, Colors.blue),
            _buildStatRow('Cash Sales', provider.cashSales, Colors.green),
            _buildStatRow('Credit Sales', provider.creditSales, Colors.orange),
            const Divider(),
            _buildStatRow('Gross Profit', provider.grossProfit, Colors.purple, isBold: true),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseCard(ProfitProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Expense Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildStatRow('Total Expenses', provider.totalExpenses, Colors.red),
            ...provider.expensesByCategory.entries.map(
              (entry) => _buildStatRow(entry.key, entry.value, Colors.red[300]!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVATCard(ProfitProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('VAT Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildStatRow('VAT Collected', provider.vatCollected, Colors.blue),
            _buildStatRow('VAT Paid', provider.vatPaid, Colors.orange),
            const Divider(),
            _buildStatRow('VAT Payable', provider.vatPayable, Colors.purple, isBold: true),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(ProfitProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Quick Stats', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildQuickStatItem('Transactions', provider.totalTransactions.toString(), Icons.receipt)),
                Expanded(child: _buildQuickStatItem('Avg Sale', 'Rs. ${provider.averageSale.toStringAsFixed(0)}', Icons.trending_up)),
                Expanded(child: _buildQuickStatItem('Profit %', '${provider.profitMargin.toStringAsFixed(1)}%', Icons.percent)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, double value, Color color, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            'Rs. ${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Colors.blue),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  void _changeViewMode(String mode) {
    setState(() {
      viewMode = mode;
    });
    _loadProfitData();
  }

  void _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
      _loadProfitData();
    }
  }
}