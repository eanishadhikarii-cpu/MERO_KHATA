class Purchase {
  final int? id;
  final String billNumber;
  final int? supplierId;
  final DateTime purchaseDate;
  final double totalAmount;
  final double vatAmount;
  final double grandTotal;
  final String paymentStatus;
  final List<PurchaseItem> items;
  final DateTime createdAt;

  Purchase({
    this.id,
    required this.billNumber,
    this.supplierId,
    required this.purchaseDate,
    required this.totalAmount,
    required this.vatAmount,
    required this.grandTotal,
    this.paymentStatus = 'pending',
    this.items = const [],
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bill_number': billNumber,
      'supplier_id': supplierId,
      'purchase_date': purchaseDate.toIso8601String(),
      'total_amount': totalAmount,
      'vat_amount': vatAmount,
      'grand_total': grandTotal,
      'payment_status': paymentStatus,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Purchase.fromMap(Map<String, dynamic> map) {
    return Purchase(
      id: map['id'],
      billNumber: map['bill_number'],
      supplierId: map['supplier_id'],
      purchaseDate: DateTime.parse(map['purchase_date']),
      totalAmount: map['total_amount'].toDouble(),
      vatAmount: map['vat_amount'].toDouble(),
      grandTotal: map['grand_total'].toDouble(),
      paymentStatus: map['payment_status'] ?? 'pending',
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}

class PurchaseItem {
  final int? id;
  final int purchaseId;
  final int productId;
  final String productName;
  final int quantity;
  final double costPrice;
  final double vatPercent;
  final double totalAmount;

  PurchaseItem({
    this.id,
    required this.purchaseId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.costPrice,
    required this.vatPercent,
    required this.totalAmount,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'purchase_id': purchaseId,
      'product_id': productId,
      'quantity': quantity,
      'cost_price': costPrice,
      'vat_percent': vatPercent,
      'total_amount': totalAmount,
    };
  }

  factory PurchaseItem.fromMap(Map<String, dynamic> map) {
    return PurchaseItem(
      id: map['id'],
      purchaseId: map['purchase_id'],
      productId: map['product_id'],
      productName: '', // Will be loaded separately
      quantity: map['quantity'],
      costPrice: map['cost_price'].toDouble(),
      vatPercent: map['vat_percent'].toDouble(),
      totalAmount: map['total_amount'].toDouble(),
    );
  }
}