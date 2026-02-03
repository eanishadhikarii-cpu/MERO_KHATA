import 'package:flutter_tts/flutter_tts.dart';
import '../database/database_helper.dart';

class VoiceSummaryService {
  static final VoiceSummaryService _instance = VoiceSummaryService._internal();
  factory VoiceSummaryService() => _instance;
  VoiceSummaryService._internal();

  final FlutterTts _tts = FlutterTts();
  final DatabaseHelper _db = DatabaseHelper();

  Future<void> initialize() async {
    await _tts.setLanguage('ne-NP');
    await _tts.setSpeechRate(0.7);
  }

  // Morning summary
  Future<void> playMorningSummary() async {
    final summary = await _generateMorningSummary();
    await _speak(summary.nepali, 'ne-NP');
  }

  // Night summary
  Future<void> playNightSummary() async {
    final summary = await _generateNightSummary();
    await _speak(summary.nepali, 'ne-NP');
  }

  Future<DailySummary> _generateMorningSummary() async {
    final today = DateTime.now();
    
    // Low stock count
    final products = await _db.getProducts();
    final lowStockCount = products.where((p) => p.stockQuantity < 5).length;
    
    // EMI due today
    final emiPayments = await _db.getDueEMIPayments();
    final todayEMI = emiPayments.where((e) => 
      e.dueDate.year == today.year && 
      e.dueDate.month == today.month && 
      e.dueDate.day == today.day
    ).length;
    
    // Customers with due balance
    final customers = await _db.getCustomers();
    final dueCustomers = customers.where((c) => c.balance > 0).length;
    
    String nepali = 'शुभ प्रभात! ';
    if (lowStockCount > 0) {
      nepali += '$lowStockCount वटा सामान सकिन लाग्यो। ';
    }
    if (todayEMI > 0) {
      nepali += 'आज $todayEMI वटा EMI तिर्नुपर्छ। ';
    }
    if (dueCustomers > 0) {
      nepali += '$dueCustomers जना ग्राहकको पैसा बाँकी छ।';
    }
    if (lowStockCount == 0 && todayEMI == 0 && dueCustomers == 0) {
      nepali += 'आजको लागि सबै ठीक छ!';
    }

    return DailySummary(
      nepali: nepali,
      english: 'Good morning! Business status updated.',
      lowStockCount: lowStockCount,
      emiDueCount: todayEMI,
      dueCustomersCount: dueCustomers,
    );
  }

  Future<DailySummary> _generateNightSummary() async {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    
    // Today's sales
    final sales = await _db.getSales(startDate: todayStart, endDate: todayEnd);
    final totalSales = sales.fold(0.0, (sum, sale) => sum + sale.grandTotal);
    
    // Today's profit (estimated)
    final totalProfit = sales.fold(0.0, (sum, sale) {
      return sum + sale.items.fold(0.0, (itemSum, item) {
        return itemSum + (item.unitPrice - item.originalPrice * 0.8) * item.quantity;
      });
    });
    
    // New credit added
    final creditSales = sales.where((s) => s.saleType == 'credit');
    final newCredit = creditSales.fold(0.0, (sum, sale) => sum + sale.grandTotal);
    
    String nepali = 'आजको सारांश: ';
    nepali += 'बिक्री ${totalSales.toStringAsFixed(0)} रुपैयाँ, ';
    nepali += 'नाफा ${totalProfit.toStringAsFixed(0)} रुपैयाँ। ';
    if (newCredit > 0) {
      nepali += 'नयाँ उधारो ${newCredit.toStringAsFixed(0)} रुपैयाँ।';
    }

    return DailySummary(
      nepali: nepali,
      english: 'Today summary: Sales Rs. ${totalSales.toStringAsFixed(0)}',
      totalSales: totalSales,
      totalProfit: totalProfit,
      newCredit: newCredit,
    );
  }

  Future<void> _speak(String text, String language) async {
    await _tts.setLanguage(language);
    await _tts.speak(text);
  }

  // Voice query responses
  Future<void> handleVoiceQuery(String query) async {
    final lowerQuery = query.toLowerCase();
    
    if (lowerQuery.contains('आजको बिक्री') || lowerQuery.contains('today sales')) {
      final summary = await _generateNightSummary();
      await _speak('आजको बिक्री ${summary.totalSales?.toStringAsFixed(0)} रुपैयाँ भयो।', 'ne-NP');
    } else if (lowerQuery.contains('बाँकी रकम') || lowerQuery.contains('due amount')) {
      final customers = await _db.getCustomers();
      final totalDue = customers.fold(0.0, (sum, c) => sum + c.balance);
      await _speak('कुल बाँकी रकम ${totalDue.toStringAsFixed(0)} रुपैयाँ छ।', 'ne-NP');
    } else if (lowerQuery.contains('नाफा') || lowerQuery.contains('profit')) {
      final summary = await _generateNightSummary();
      await _speak('आजको नाफा ${summary.totalProfit?.toStringAsFixed(0)} रुपैयाँ भयो।', 'ne-NP');
    } else {
      await _speak('माफ गर्नुहोस्, मैले बुझिन।', 'ne-NP');
    }
  }
}

class DailySummary {
  final String nepali;
  final String english;
  final int? lowStockCount;
  final int? emiDueCount;
  final int? dueCustomersCount;
  final double? totalSales;
  final double? totalProfit;
  final double? newCredit;

  DailySummary({
    required this.nepali,
    required this.english,
    this.lowStockCount,
    this.emiDueCount,
    this.dueCustomersCount,
    this.totalSales,
    this.totalProfit,
    this.newCredit,
  });
}