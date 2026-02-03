class Payment {
  final int? id;
  final int customerId;
  final double amount;
  final String paymentMethod;
  final DateTime paymentDate;
  final String? notes;
  final String? billNumber;
  final DateTime createdAt;

  Payment({
    this.id,
    required this.customerId,
    required this.amount,
    required this.paymentMethod,
    required this.paymentDate,
    this.notes,
    this.billNumber,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'amount': amount,
      'payment_method': paymentMethod,
      'payment_date': paymentDate.toIso8601String(),
      'notes': notes,
      'bill_number': billNumber,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'],
      customerId: map['customer_id'],
      amount: map['amount'].toDouble(),
      paymentMethod: map['payment_method'],
      paymentDate: DateTime.parse(map['payment_date']),
      notes: map['notes'],
      billNumber: map['bill_number'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}