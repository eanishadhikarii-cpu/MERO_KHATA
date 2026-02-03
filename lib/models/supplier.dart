class Supplier {
  final int? id;
  final String name;
  final String? phone;
  final String? address;
  final String? panNumber;
  final double creditLimit;
  final double balance;
  final DateTime createdAt;

  Supplier({
    this.id,
    required this.name,
    this.phone,
    this.address,
    this.panNumber,
    this.creditLimit = 0.0,
    this.balance = 0.0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'address': address,
      'pan_number': panNumber,
      'credit_limit': creditLimit,
      'balance': balance,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Supplier.fromMap(Map<String, dynamic> map) {
    return Supplier(
      id: map['id'],
      name: map['name'],
      phone: map['phone'],
      address: map['address'],
      panNumber: map['pan_number'],
      creditLimit: map['credit_limit']?.toDouble() ?? 0.0,
      balance: map['balance']?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}