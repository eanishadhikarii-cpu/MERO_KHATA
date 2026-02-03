import '../database/database_helper.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../models/customer.dart';

class SmartAnalyticsService {
  static final SmartAnalyticsService _instance = SmartAnalyticsService._internal();
  factory SmartAnalyticsService() => _instance;
  SmartAnalyticsService._internal();

  final DatabaseHelper _db = DatabaseHelper();

  // Calculate stock predictions
  Future<List<StockPrediction>> getStockPredictions() async {
    final products = await _db.getProducts();
    final sales = await _db.getSales(
      startDate: DateTime.now().subtract(const Duration(days: 90)),
      endDate: DateTime.now(),
    );

    List<StockPrediction> predictions = [];

    for (Product product in products) {
      final consumption = _calculateConsumption(product, sales);
      final prediction = StockPrediction(
        product: product,
        dailyConsumption: consumption,
        daysRemaining: consumption > 0 ? (product.stockQuantity / consumption).round() : 999,
        suggestedOrder: _calculateSuggestedOrder(consumption),
        status: _getStockStatus(product.stockQuantity, consumption),
      );
      predictions.add(prediction);
    }

    predictions.sort((a, b) => a.daysRemaining.compareTo(b.daysRemaining));
    return predictions;
  }

  double _calculateConsumption(Product product, List<Sale> sales) {
    int totalSold = 0;
    int daysWithSales = 0;
    
    final last30Days = DateTime.now().subtract(const Duration(days: 30));
    
    for (Sale sale in sales) {
      if (sale.saleDate.isAfter(last30Days)) {
        for (var item in sale.items) {
          if (item.productId == product.id) {
            totalSold += item.quantity;
            daysWithSales++;
          }
        }
      }
    }
    
    return daysWithSales > 0 ? totalSold / 30.0 : 0.0;
  }

  int _calculateSuggestedOrder(double dailyConsumption) {
    if (dailyConsumption <= 0) return 0;
    return (dailyConsumption * 15).ceil(); // 15 days stock
  }

  StockStatus _getStockStatus(int currentStock, double dailyConsumption) {
    if (dailyConsumption <= 0) return StockStatus.safe;
    
    final daysRemaining = currentStock / dailyConsumption;
    if (daysRemaining <= 3) return StockStatus.critical;
    if (daysRemaining <= 7) return StockStatus.warning;
    return StockStatus.safe;
  }

  // Business health score
  Future<BusinessHealth> getBusinessHealth() async {
    final sales = await _db.getSales(
      startDate: DateTime.now().subtract(const Duration(days: 30)),
      endDate: DateTime.now(),
    );
    
    final customers = await _db.getCustomers();
    final products = await _db.getProducts();

    double salesTrend = _calculateSalesTrend(sales);
    double profitMargin = _calculateProfitMargin(sales);
    double creditRisk = _calculateCreditRisk(customers);
    double stockRisk = _calculateStockRisk(products);

    int score = ((salesTrend + profitMargin + creditRisk + stockRisk) / 4 * 5).round();
    
    return BusinessHealth(
      score: score.clamp(1, 5),
      salesTrend: salesTrend,
      profitMargin: profitMargin,
      creditRisk: creditRisk,
      stockRisk: stockRisk,
    );
  }

  double _calculateSalesTrend(List<Sale> sales) {
    if (sales.length < 7) return 0.5;
    
    final last7Days = sales.where((s) => 
      s.saleDate.isAfter(DateTime.now().subtract(const Duration(days: 7)))
    ).fold(0.0, (sum, sale) => sum + sale.grandTotal);
    
    final prev7Days = sales.where((s) => 
      s.saleDate.isAfter(DateTime.now().subtract(const Duration(days: 14))) &&
      s.saleDate.isBefore(DateTime.now().subtract(const Duration(days: 7)))
    ).fold(0.0, (sum, sale) => sum + sale.grandTotal);
    
    if (prev7Days == 0) return 0.5;
    return (last7Days / prev7Days).clamp(0.0, 1.0);
  }

  double _calculateProfitMargin(List<Sale> sales) {
    if (sales.isEmpty) return 0.0;
    
    double totalRevenue = 0;
    double totalCost = 0;
    
    for (Sale sale in sales) {
      totalRevenue += sale.grandTotal;
      for (var item in sale.items) {
        totalCost += item.quantity * (item.originalPrice * 0.8); // Estimate cost
      }
    }
    
    if (totalRevenue == 0) return 0.0;
    return ((totalRevenue - totalCost) / totalRevenue).clamp(0.0, 1.0);
  }

  double _calculateCreditRisk(List<Customer> customers) {
    double totalCredit = customers.fold(0.0, (sum, c) => sum + c.balance);
    double totalSales = customers.fold(0.0, (sum, c) => sum + c.totalCredit);
    
    if (totalSales == 0) return 1.0;
    return (1 - (totalCredit / totalSales)).clamp(0.0, 1.0);
  }

  double _calculateStockRisk(List<Product> products) {
    int lowStockCount = products.where((p) => p.stockQuantity < 5).length;
    if (products.isEmpty) return 1.0;
    return (1 - (lowStockCount / products.length)).clamp(0.0, 1.0);
  }
}

class StockPrediction {
  final Product product;
  final double dailyConsumption;
  final int daysRemaining;
  final int suggestedOrder;
  final StockStatus status;

  StockPrediction({
    required this.product,
    required this.dailyConsumption,
    required this.daysRemaining,
    required this.suggestedOrder,
    required this.status,
  });
}

enum StockStatus { critical, warning, safe }

class BusinessHealth {
  final int score;
  final double salesTrend;
  final double profitMargin;
  final double creditRisk;
  final double stockRisk;

  BusinessHealth({
    required this.score,
    required this.salesTrend,
    required this.profitMargin,
    required this.creditRisk,
    required this.stockRisk,
  });

  String get description {
    switch (score) {
      case 5: return 'Excellent business performance';
      case 4: return 'Good business health';
      case 3: return 'Average performance';
      case 2: return 'Needs attention';
      case 1: return 'Critical issues';
      default: return 'Unknown status';
    }
  }
}