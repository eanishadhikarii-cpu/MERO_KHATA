import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../models/expense.dart';
import '../widgets/add_expense_dialog.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  String selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpenseProvider>().loadExpenses();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddExpenseDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary Cards
          Container(
            height: 100,
            padding: const EdgeInsets.all(4),
            child: Consumer<ExpenseProvider>(
              builder: (context, provider, child) {
                return Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        'Today',
                        'Rs. ${provider.todayExpenses.toStringAsFixed(0)}',
                        Icons.today,
                        Colors.red,
                      ),
                    ),
                    Expanded(
                      child: _buildSummaryCard(
                        'This Month',
                        'Rs. ${provider.monthlyExpenses.toStringAsFixed(0)}',
                        Icons.calendar_month,
                        Colors.orange,
                      ),
                    ),
                    Expanded(
                      child: _buildSummaryCard(
                        'Total',
                        'Rs. ${provider.totalExpenses.toStringAsFixed(0)}',
                        Icons.account_balance_wallet,
                        Colors.purple,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Category Filter
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildCategoryChip('All'),
                  ...ExpenseCategories.categories.map((category) => _buildCategoryChip(category)),
                ],
              ),
            ),
          ),

          // Expense List
          Expanded(
            child: Consumer<ExpenseProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final filteredExpenses = selectedCategory == 'All'
                    ? provider.expenses
                    : provider.expenses.where((e) => e.category == selectedCategory).toList();

                if (filteredExpenses.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No expenses yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredExpenses.length,
                  itemBuilder: (context, index) {
                    final expense = filteredExpenses[index];
                    return _buildExpenseCard(expense);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String amount, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 2),
            Text(
              title, 
              style: const TextStyle(fontSize: 10), 
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            const SizedBox(height: 2),
            Text(
              amount,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    final isSelected = selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(category),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            selectedCategory = category;
          });
        },
        selectedColor: Colors.blue.withOpacity(0.3),
      ),
    );
  }

  Widget _buildExpenseCard(Expense expense) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getCategoryColor(expense.category),
          child: Icon(_getCategoryIcon(expense.category), color: Colors.white),
        ),
        title: Text(expense.category),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (expense.description != null) 
                  Text(
                    expense.description!,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                Text('${expense.expenseDate.day}/${expense.expenseDate.month}/${expense.expenseDate.year}'),
              ],
            ),
        trailing: SizedBox(
          width: 80,
          child: Text(
            'Rs. ${expense.amount.toStringAsFixed(0)}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.red),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
          ),
        ),
        onLongPress: () => _showDeleteDialog(expense),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Rent': return Colors.brown;
      case 'Electricity': return Colors.yellow[700]!;
      case 'Salary': return Colors.green;
      case 'Transport': return Colors.blue;
      case 'Internet': return Colors.purple;
      default: return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Rent': return Icons.home;
      case 'Electricity': return Icons.electrical_services;
      case 'Salary': return Icons.people;
      case 'Transport': return Icons.directions_car;
      case 'Internet': return Icons.wifi;
      case 'Phone': return Icons.phone;
      default: return Icons.receipt;
    }
  }

  void _showAddExpenseDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddExpenseDialog(),
    );
  }

  void _showDeleteDialog(Expense expense) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        content: Text('Are you sure you want to delete this ${expense.category} expense?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<ExpenseProvider>().deleteExpense(expense.id!);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}