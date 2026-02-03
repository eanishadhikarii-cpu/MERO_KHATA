class Expense {
  final int? id;
  final String category;
  final String? description;
  final double amount;
  final DateTime expenseDate;
  final DateTime createdAt;

  Expense({
    this.id,
    required this.category,
    this.description,
    required this.amount,
    required this.expenseDate,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'description': description,
      'amount': amount,
      'expense_date': expenseDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      category: map['category'],
      description: map['description'],
      amount: map['amount'].toDouble(),
      expenseDate: DateTime.parse(map['expense_date']),
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}

// Predefined expense categories for Nepali shops
class ExpenseCategories {
  static const List<String> categories = [
    'Rent', // भाडा
    'Electricity', // बिजुली
    'Salary', // तलब
    'Transport', // यातायात
    'Internet', // इन्टरनेट
    'Phone', // फोन
    'Stationery', // लेखन सामग्री
    'Maintenance', // मर्मत
    'Insurance', // बीमा
    'Tax', // कर
    'Misc', // अन्य
  ];
}