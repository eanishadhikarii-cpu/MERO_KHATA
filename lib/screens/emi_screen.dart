import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/emi_provider.dart';
import '../models/emi.dart';

class EMIScreen extends StatefulWidget {
  const EMIScreen({super.key});

  @override
  State<EMIScreen> createState() => _EMIScreenState();
}

class _EMIScreenState extends State<EMIScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EMIProvider>().loadEMIs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EMI Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calculate),
            onPressed: _showEMICalculator,
          ),
        ],
      ),
      body: Consumer<EMIProvider>(
        builder: (context, emiProvider, child) {
          if (emiProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Summary Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        'Outstanding',
                        'Rs. ${NumberFormat('#,##,###').format(emiProvider.totalOutstanding)}',
                        Icons.account_balance,
                        Colors.red,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSummaryCard(
                        'Monthly EMI',
                        'Rs. ${NumberFormat('#,##,###').format(emiProvider.monthlyEMITotal)}',
                        Icons.calendar_month,
                        Colors.blue,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),

                // Due Payments Alert
                if (emiProvider.duePayments.isNotEmpty)
                  Card(
                    color: Colors.orange[50],
                    child: ListTile(
                      leading: const Icon(Icons.warning, color: Colors.orange),
                      title: Text('${emiProvider.duePayments.length} EMIs Due'),
                      subtitle: const Text('Tap to pay'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: _showDuePayments,
                    ),
                  ),

                const SizedBox(height: 24),

                // Active EMIs
                const Text(
                  'Active EMIs',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                
                const SizedBox(height: 16),

                if (emiProvider.activeEMIs.isEmpty)
                  Center(
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        Icon(Icons.account_balance_wallet, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No active EMIs',
                          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                else
                  ...emiProvider.activeEMIs.map((emi) => _buildEMICard(emi)),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddEMI,
        icon: const Icon(Icons.add),
        label: const Text('Add EMI'),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String amount, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(
              amount,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEMICard(EMI emi) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue[100],
          child: Text(emi.lenderName[0].toUpperCase()),
        ),
        title: Text(emi.lenderName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('EMI: Rs. ${NumberFormat('#,##,###').format(emi.emiAmount)}'),
            Text('Remaining: Rs. ${NumberFormat('#,##,###').format(emi.remainingBalance)}'),
          ],
        ),
        trailing: Text('${emi.interestRate}%\n${emi.interestType}', textAlign: TextAlign.center),
      ),
    );
  }

  void _showAddEMI() {
    showDialog(
      context: context,
      builder: (context) => const AddEMIDialog(),
    );
  }

  void _showEMICalculator() {
    showDialog(
      context: context,
      builder: (context) => const EMICalculatorDialog(),
    );
  }

  void _showDuePayments() {
    final emiProvider = context.read<EMIProvider>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Due Payments'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: emiProvider.duePayments.length,
            itemBuilder: (context, index) {
              final payment = emiProvider.duePayments[index];
              return ListTile(
                title: Text('Rs. ${NumberFormat('#,##,###').format(payment.amount)}'),
                subtitle: Text('Due: ${DateFormat('dd MMM').format(payment.dueDate)}'),
                trailing: ElevatedButton(
                  onPressed: () => _markPaymentAsPaid(payment),
                  child: const Text('Pay'),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _markPaymentAsPaid(EMIPayment payment) async {
    try {
      await context.read<EMIProvider>().markPaymentAsPaid(payment.id!, payment.amount);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment marked as paid!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}

class AddEMIDialog extends StatefulWidget {
  const AddEMIDialog({super.key});

  @override
  State<AddEMIDialog> createState() => _AddEMIDialogState();
}

class _AddEMIDialogState extends State<AddEMIDialog> {
  final _lenderController = TextEditingController();
  final _amountController = TextEditingController();
  final _rateController = TextEditingController();
  final _durationController = TextEditingController();
  String _interestType = 'reducing';
  double _calculatedEMI = 0.0;

  void _calculateEMI() {
    if (_amountController.text.isNotEmpty && 
        _rateController.text.isNotEmpty && 
        _durationController.text.isNotEmpty) {
      
      double amount = double.tryParse(_amountController.text) ?? 0;
      double rate = double.tryParse(_rateController.text) ?? 0;
      int months = int.tryParse(_durationController.text) ?? 0;
      
      if (amount > 0 && rate > 0 && months > 0) {
        setState(() {
          _calculatedEMI = EMI.calculateEMI(amount, rate, months, _interestType);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add EMI'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _lenderController,
              decoration: const InputDecoration(labelText: 'Lender Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Loan Amount'),
              keyboardType: TextInputType.number,
              onChanged: (_) => _calculateEMI(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: const Text('Reducing'),
                    leading: Radio<String>(
                      value: 'reducing',
                      groupValue: _interestType,
                      onChanged: (value) {
                        setState(() => _interestType = value!);
                        _calculateEMI();
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: ListTile(
                    title: const Text('Flat'),
                    leading: Radio<String>(
                      value: 'flat',
                      groupValue: _interestType,
                      onChanged: (value) {
                        setState(() => _interestType = value!);
                        _calculateEMI();
                      },
                    ),
                  ),
                ),
              ],
            ),
            TextField(
              controller: _rateController,
              decoration: const InputDecoration(labelText: 'Interest Rate (%)'),
              keyboardType: TextInputType.number,
              onChanged: (_) => _calculateEMI(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _durationController,
              decoration: const InputDecoration(labelText: 'Duration (months)'),
              keyboardType: TextInputType.number,
              onChanged: (_) => _calculateEMI(),
            ),
            if (_calculatedEMI > 0) ...[
              const SizedBox(height: 16),
              Text('Monthly EMI: Rs. ${_calculatedEMI.toStringAsFixed(0)}',
                   style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _calculatedEMI > 0 ? _saveEMI : null,
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _saveEMI() async {
    if (_lenderController.text.isNotEmpty && _calculatedEMI > 0) {
      try {
        double amount = double.parse(_amountController.text);
        double rate = double.parse(_rateController.text);
        int months = int.parse(_durationController.text);
        double totalPayable = EMI.calculateTotalPayable(_calculatedEMI, months);

        final emi = EMI(
          lenderName: _lenderController.text,
          loanAmount: amount,
          interestType: _interestType,
          interestRate: rate,
          emiAmount: _calculatedEMI,
          startDate: DateTime.now(),
          durationMonths: months,
          totalPayable: totalPayable,
          totalInterest: totalPayable - amount,
          remainingBalance: totalPayable,
          createdAt: DateTime.now(),
        );

        await context.read<EMIProvider>().addEMI(emi);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('EMI added successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

class EMICalculatorDialog extends StatefulWidget {
  const EMICalculatorDialog({super.key});

  @override
  State<EMICalculatorDialog> createState() => _EMICalculatorDialogState();
}

class _EMICalculatorDialogState extends State<EMICalculatorDialog> {
  final _amountController = TextEditingController();
  final _rateController = TextEditingController();
  final _durationController = TextEditingController();
  String _interestType = 'reducing';
  double _calculatedEMI = 0.0;
  double _totalPayable = 0.0;

  void _calculateEMI() {
    if (_amountController.text.isNotEmpty && 
        _rateController.text.isNotEmpty && 
        _durationController.text.isNotEmpty) {
      
      double amount = double.tryParse(_amountController.text) ?? 0;
      double rate = double.tryParse(_rateController.text) ?? 0;
      int months = int.tryParse(_durationController.text) ?? 0;
      
      if (amount > 0 && rate > 0 && months > 0) {
        setState(() {
          _calculatedEMI = EMI.calculateEMI(amount, rate, months, _interestType);
          _totalPayable = EMI.calculateTotalPayable(_calculatedEMI, months);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('EMI Calculator'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Loan Amount'),
              keyboardType: TextInputType.number,
              onChanged: (_) => _calculateEMI(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: const Text('Reducing'),
                    leading: Radio<String>(
                      value: 'reducing',
                      groupValue: _interestType,
                      onChanged: (value) {
                        setState(() => _interestType = value!);
                        _calculateEMI();
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: ListTile(
                    title: const Text('Flat'),
                    leading: Radio<String>(
                      value: 'flat',
                      groupValue: _interestType,
                      onChanged: (value) {
                        setState(() => _interestType = value!);
                        _calculateEMI();
                      },
                    ),
                  ),
                ),
              ],
            ),
            TextField(
              controller: _rateController,
              decoration: const InputDecoration(labelText: 'Interest Rate (%)'),
              keyboardType: TextInputType.number,
              onChanged: (_) => _calculateEMI(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _durationController,
              decoration: const InputDecoration(labelText: 'Duration (months)'),
              keyboardType: TextInputType.number,
              onChanged: (_) => _calculateEMI(),
            ),
            if (_calculatedEMI > 0) ...[
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text('Monthly EMI: Rs. ${_calculatedEMI.toStringAsFixed(0)}',
                           style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Total Payable: Rs. ${_totalPayable.toStringAsFixed(0)}'),
                      Text('Total Interest: Rs. ${(_totalPayable - (double.tryParse(_amountController.text) ?? 0)).toStringAsFixed(0)}'),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}