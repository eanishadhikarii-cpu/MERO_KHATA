class Sale {
  final int? id;
  final String billNumber;
  final DateTime saleDate;
  final double totalAmount;
  final double vatAmount;
  final double grandTotal;
  final double billDiscount;
  final double roundingAdjustment;
  final String saleType; // 'cash', 'debit', 'credit'
  final String paymentMethod; // 'cash', 'esewa', 'khalti', 'fonepay'
  final int? customerId;
  final String? customerName;
  final String? customerPhone;
  final List<SaleItem> items;
  final String? notes;
  final bool isCancelled;
  final DateTime? cancelledAt;
  final DateTime createdAt;

  Sale({
    this.id,
    required this.billNumber,
    required this.saleDate,
    required this.totalAmount,
    required this.vatAmount,
    required this.grandTotal,
    this.billDiscount = 0.0,
    this.roundingAdjustment = 0.0,
    required this.saleType,
    required this.paymentMethod,
    this.customerId,
    this.customerName,
    this.customerPhone,
    required this.items,
    this.notes,
    this.isCancelled = false,
    this.cancelledAt,
    required this.createdAt,
  });

  bool get isCredit => saleType == 'credit';
  bool get isDebit => saleType == 'debit';
  bool get isCash => saleType == 'cash';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bill_number': billNumber,
      'sale_date': saleDate.toIso8601String(),
      'total_amount': totalAmount,
      'vat_amount': vatAmount,
      'grand_total': grandTotal,
      'bill_discount': billDiscount,
      'rounding_adjustment': roundingAdjustment,
      'sale_type': saleType,
      'payment_method': paymentMethod,
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'notes': notes,
      'is_cancelled': isCancelled ? 1 : 0,
      'cancelled_at': cancelledAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'],
      billNumber: map['bill_number'],
      saleDate: DateTime.parse(map['sale_date']),
      totalAmount: map['total_amount'].toDouble(),
      vatAmount: map['vat_amount'].toDouble(),
      grandTotal: map['grand_total'].toDouble(),
      billDiscount: map['bill_discount']?.toDouble() ?? 0.0,
      roundingAdjustment: map['rounding_adjustment']?.toDouble() ?? 0.0,
      saleType: map['sale_type'],
      paymentMethod: map['payment_method'],
      customerId: map['customer_id'],
      customerName: map['customer_name'],
      customerPhone: map['customer_phone'],
      items: [],
      notes: map['notes'],
      isCancelled: (map['is_cancelled'] ?? 0) == 1,
      cancelledAt: map['cancelled_at'] != null ? DateTime.parse(map['cancelled_at']) : null,
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}

class SaleItem {
  final int? id;
  final int saleId;
  final int productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double originalPrice;
  final double itemDiscount;
  final double vatPercent;
  final double totalAmount;
  final bool priceOverridden;

  SaleItem({
    this.id,
    required this.saleId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.originalPrice,
    this.itemDiscount = 0.0,
    required this.vatPercent,
    required this.totalAmount,
    this.priceOverridden = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sale_id': saleId,
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'unit_price': unitPrice,
      'original_price': originalPrice,
      'item_discount': itemDiscount,
      'vat_percent': vatPercent,
      'total_amount': totalAmount,
      'price_overridden': priceOverridden ? 1 : 0,
    };
  }

  factory SaleItem.fromMap(Map<String, dynamic> map) {
    return SaleItem(
      id: map['id'],
      saleId: map['sale_id'],
      productId: map['product_id'],
      productName: map['product_name'],
      quantity: map['quantity'],
      unitPrice: map['unit_price'].toDouble(),
      originalPrice: map['original_price']?.toDouble() ?? map['unit_price'].toDouble(),
      itemDiscount: map['item_discount']?.toDouble() ?? 0.0,
      vatPercent: map['vat_percent'].toDouble(),
      totalAmount: map['total_amount'].toDouble(),
      priceOverridden: (map['price_overridden'] ?? 0) == 1,
    );
  }
}