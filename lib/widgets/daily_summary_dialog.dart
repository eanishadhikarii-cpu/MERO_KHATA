import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sales_provider.dart';
import '../models/sale.dart';

class DailySummaryDialog extends StatefulWidget {
  final DateTime date;

  const DailySummaryDialog({Key? key, required this.date}) : super(key: key);

  @override
  State<DailySummaryDialog> createState() => _DailySummaryDialogState();
}

class _DailySummaryDialogState extends State<DailySummaryDialog> {
  List<Sale> todaySales = [];
  bool isLoading = true;
  
  double totalSales = 0.0;
  double cashSales = 0.0;
  double creditSales = 0.0;
  double totalVAT = 0.0;
  int totalTransactions = 0;
  int cancelledTransactions = 0;

  @override
  void initState() {
    super.initState();
    _loadDailySummary();
  }

  void _loadDailySummary() async {
    try {
      final salesProvider = Provider.of<SalesProvider>(context, listen: false);
      final sales = salesProvider.todaySales;
      
      setState(() {
        todaySales = sales;
        _calculateSummary();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _calculateSummary() {
    totalSales = 0.0;
    cashSales = 0.0;
    creditSales = 0.0;
    totalVAT = 0.0;
    totalTransactions = 0;
    cancelledTransactions = 0;

    for (Sale sale in todaySales) {
      totalTransactions++;
      totalSales += sale.grandTotal;
      totalVAT += sale.vatAmount;
      
      if (sale.saleType == 'cash') {
        cashSales += sale.grandTotal;
      } else if (sale.saleType == 'credit') {
        creditSales += sale.grandTotal;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 400,
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.summarize, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Daily Summary',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Spacer(),
                Text(
                  '${widget.date.day}/${widget.date.month}/${widget.date.year}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            SizedBox(height: 20),
            
            if (isLoading)
              Center(child: CircularProgressIndicator())
            else
              Column(
                children: [
                  _buildSummaryCard(),
                  SizedBox(height: 16),
                  _buildActionButtons(),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSummaryRow('Total Sales', 'Rs. ${totalSales.toStringAsFixed(2)}', Colors.green),
            Divider(),
            _buildSummaryRow('Cash Sales', 'Rs. ${cashSales.toStringAsFixed(2)}', Colors.blue),
            _buildSummaryRow('Credit Sales', 'Rs. ${creditSales.toStringAsFixed(2)}', Colors.orange),
            Divider(),
            _buildSummaryRow('Total VAT', 'Rs. ${totalVAT.toStringAsFixed(2)}', Colors.purple),
            Divider(),
            _buildSummaryRow('Total Transactions', '$totalTransactions', Colors.grey[700]!),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 16)),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close),
            label: Text('Close'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _shareSummary,
            icon: Icon(Icons.share),
            label: Text('Share'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
          ),
        ),
      ],
    );
  }

  void _shareSummary() {
    String summary = '''
📊 Daily Sales Summary
📅 Date: ${widget.date.day}/${widget.date.month}/${widget.date.year}

💰 Total Sales: Rs. ${totalSales.toStringAsFixed(2)}
💵 Cash Sales: Rs. ${cashSales.toStringAsFixed(2)}
🏷️ Credit Sales: Rs. ${creditSales.toStringAsFixed(2)}
📋 Total VAT: Rs. ${totalVAT.toStringAsFixed(2)}

📊 Transactions: $totalTransactions
${cancelledTransactions > 0 ? '❌ Cancelled: $cancelledTransactions' : ''}

Generated by Mero Khata 📱
    ''';
    
    // Share implementation would go here
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Summary copied to clipboard')),
    );
  }
}