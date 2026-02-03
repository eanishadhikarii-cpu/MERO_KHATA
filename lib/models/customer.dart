class Customer {
  final int? id;
  final String name;
  final String? phone;
  final double totalDebit;
  final double totalCredit;
  final double balance;
  final DateTime createdAt;
  final DateTime updatedAt;

  Customer({
    this.id,
    required this.name,
    this.phone,
    required this.totalDebit,
    required this.totalCredit,
    required this.balance,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'total_debit': totalDebit,
      'total_credit': totalCredit,
      'balance': balance,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'],
      name: map['name'],
      phone: map['phone'],
      totalDebit: map['total_debit'].toDouble(),
      totalCredit: map['total_credit'].toDouble(),
      balance: map['balance'].toDouble(),
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Customer copyWith({
    int? id,
    String? name,
    String? phone,
    double? totalDebit,
    double? totalCredit,
    double? balance,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      totalDebit: totalDebit ?? this.totalDebit,
      totalCredit: totalCredit ?? this.totalCredit,
      balance: balance ?? this.balance,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}