class Product {
  final int? id;
  final String name;
  final String? barcode;
  final double costPrice;
  final double sellingPrice;
  final double vatPercent;
  final int stockQuantity;
  final String? category;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    this.id,
    required this.name,
    this.barcode,
    required this.costPrice,
    required this.sellingPrice,
    required this.vatPercent,
    required this.stockQuantity,
    this.category,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'barcode': barcode,
      'cost_price': costPrice,
      'selling_price': sellingPrice,
      'vat_percent': vatPercent,
      'stock_quantity': stockQuantity,
      'category': category,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      barcode: map['barcode'],
      costPrice: map['cost_price'].toDouble(),
      sellingPrice: map['selling_price'].toDouble(),
      vatPercent: map['vat_percent'].toDouble(),
      stockQuantity: map['stock_quantity'],
      category: map['category'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Product copyWith({
    int? id,
    String? name,
    String? barcode,
    double? costPrice,
    double? sellingPrice,
    double? vatPercent,
    int? stockQuantity,
    String? category,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      costPrice: costPrice ?? this.costPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      vatPercent: vatPercent ?? this.vatPercent,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}