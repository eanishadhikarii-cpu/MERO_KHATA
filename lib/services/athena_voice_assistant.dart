import 'package:flutter_tts/flutter_tts.dart';
import '../database/database_helper.dart';
import '../models/voice_ledger_entry.dart';
import 'intent_classifier.dart';
import 'entity_extractor.dart';

class AthenaVoiceAssistant {
  static final AthenaVoiceAssistant _instance = AthenaVoiceAssistant._internal();
  factory AthenaVoiceAssistant() => _instance;
  AthenaVoiceAssistant._internal();

  final FlutterTts _tts = FlutterTts();
  final DatabaseHelper _db = DatabaseHelper();
  
  bool _isInitialized = false;
  String? _currentContext;
  final Map<String, dynamic> _sessionData = {};

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    await _tts.setLanguage('ne-NP');
    await _tts.setSpeechRate(0.7);
    await _tts.setVolume(0.8);
    _isInitialized = true;
  }

  Future<AthenaResponse> processVoice(String input) async {
    if (!_isInitialized) await initialize();

    try {
      // Classify intent
      final intent = IntentClassifier.classify(input);
      
      // Extract entities
      final entity = EntityExtractor.extract(input);
      
      // Process based on intent
      switch (intent) {
        case VoiceIntent.creditLedger:
          return await _handleCredit(entity, input);
        case VoiceIntent.debitLedger:
          return await _handleDebit(entity, input);
        case VoiceIntent.saleQuery:
          return await _handleSaleQuery();
        case VoiceIntent.profitQuery:
          return await _handleProfitQuery();
        case VoiceIntent.stockQuery:
          return await _handleStockQuery();
        case VoiceIntent.customerBalanceQuery:
          return await _handleBalanceQuery(entity);
        default:
          return AthenaResponse.error('माफ गर्नुहोस्, मैले बुझिन।');
      }
    } catch (e) {
      return AthenaResponse.error('त्रुटि भयो: $e');
    }
  }

  Future<AthenaResponse> _handleCredit(VoiceEntity entity, String input) async {
    if (entity.customerName == null) {
      _currentContext = 'credit_customer';
      _sessionData['amount'] = entity.amount;
      return AthenaResponse.question('कुन ग्राहकको नाम?');
    }
    
    if (entity.amount == null) {
      _currentContext = 'credit_amount';
      _sessionData['customer'] = entity.customerName;
      return AthenaResponse.question('कति रकम?');
    }

    // Complete transaction
    final entry = VoiceLedgerEntry(
      ledgerName: entity.customerName!,
      transactionType: 'credit',
      amount: entity.amount!,
      language: 'mixed',
      timestamp: DateTime.now(),
    );

    await _db.insertVoiceLedgerEntry(entry.toMap());
    _clearContext();
    
    return AthenaResponse.success(
      '${entity.customerName}को खातामा ${entity.amount} रुपैयाँ जम्मा गरियो।',
      data: entry,
    );
  }

  Future<AthenaResponse> _handleDebit(VoiceEntity entity, String input) async {
    if (entity.customerName == null) {
      _currentContext = 'debit_customer';
      _sessionData['amount'] = entity.amount;
      return AthenaResponse.question('कुन ग्राहकको नाम?');
    }
    
    if (entity.amount == null) {
      _currentContext = 'debit_amount';
      _sessionData['customer'] = entity.customerName;
      return AthenaResponse.question('कति रकम?');
    }

    final entry = VoiceLedgerEntry(
      ledgerName: entity.customerName!,
      transactionType: 'debit',
      amount: entity.amount!,
      language: 'mixed',
      timestamp: DateTime.now(),
    );

    await _db.insertVoiceLedgerEntry(entry.toMap());
    _clearContext();
    
    return AthenaResponse.success(
      '${entity.customerName}बाट ${entity.amount} रुपैयाँ भुक्तानी भयो।',
      data: entry,
    );
  }

  Future<AthenaResponse> _handleSaleQuery() async {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    
    final sales = await _db.getSales(startDate: todayStart, endDate: todayEnd);
    final totalSales = sales.fold(0.0, (sum, sale) => sum + sale.grandTotal);
    
    return AthenaResponse.success('आजको कुल बिक्री ${totalSales.toStringAsFixed(0)} रुपैयाँ भयो।');
  }

  Future<AthenaResponse> _handleProfitQuery() async {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    
    final sales = await _db.getSales(startDate: todayStart, endDate: todayEnd);
    final totalProfit = sales.fold(0.0, (sum, sale) {
      return sum + sale.items.fold(0.0, (itemSum, item) {
        return itemSum + (item.unitPrice - item.originalPrice * 0.8) * item.quantity;
      });
    });
    
    return AthenaResponse.success('आजको अनुमानित नाफा ${totalProfit.toStringAsFixed(0)} रुपैयाँ छ।');
  }

  Future<AthenaResponse> _handleStockQuery() async {
    final products = await _db.getProducts();
    final lowStockProducts = products.where((p) => p.stockQuantity < 5).toList();
    
    if (lowStockProducts.isEmpty) {
      return AthenaResponse.success('सबै सामानको पर्याप्त स्टक छ।');
    }
    
    final productNames = lowStockProducts.take(3).map((p) => p.name).join(', ');
    return AthenaResponse.success('${lowStockProducts.length} वटा सामानको स्टक कम छ: $productNames');
  }

  Future<AthenaResponse> _handleBalanceQuery(VoiceEntity entity) async {
    if (entity.customerName == null) {
      _currentContext = 'balance_customer';
      return AthenaResponse.question('कुन ग्राहकको बाँकी हेर्ने?');
    }

    final customers = await _db.getCustomers();
    final customer = customers.where((c) => 
      c.name.toLowerCase().contains(entity.customerName!.toLowerCase())
    ).firstOrNull;
    
    if (customer == null) {
      return AthenaResponse.error('${entity.customerName} नामको ग्राहक फेला परेन।');
    }
    
    if (customer.balance <= 0) {
      return AthenaResponse.success('${customer.name}को कुनै बाँकी रकम छैन।');
    }
    
    return AthenaResponse.success('${customer.name}को ${customer.balance.toStringAsFixed(0)} रुपैयाँ बाँकी छ।');
  }

  Future<AthenaResponse> handleFollowUp(String input) async {
    if (_currentContext == null) {
      return processVoice(input);
    }

    final entity = EntityExtractor.extract(input);
    
    switch (_currentContext!) {
      case 'credit_customer':
        if (entity.customerName != null) {
          final amount = _sessionData['amount'] as double?;
          if (amount != null) {
            return await _handleCredit(VoiceEntity(customerName: entity.customerName, amount: amount), input);
          }
        }
        return AthenaResponse.question('ग्राहकको नाम स्पष्ट भएन। फेरि भन्नुहोस्।');
        
      case 'credit_amount':
        if (entity.amount != null) {
          final customer = _sessionData['customer'] as String?;
          if (customer != null) {
            return await _handleCredit(VoiceEntity(customerName: customer, amount: entity.amount), input);
          }
        }
        return AthenaResponse.question('रकम स्पष्ट भएन। फेरि भन्नुहोस्।');
        
      case 'debit_customer':
        if (entity.customerName != null) {
          final amount = _sessionData['amount'] as double?;
          if (amount != null) {
            return await _handleDebit(VoiceEntity(customerName: entity.customerName, amount: amount), input);
          }
        }
        return AthenaResponse.question('ग्राहकको नाम स्पष्ट भएन। फेरि भन्नुहोस्।');
        
      case 'debit_amount':
        if (entity.amount != null) {
          final customer = _sessionData['customer'] as String?;
          if (customer != null) {
            return await _handleDebit(VoiceEntity(customerName: customer, amount: entity.amount), input);
          }
        }
        return AthenaResponse.question('रकम स्पष्ट भएन। फेरि भन्नुहोस्।');
        
      case 'balance_customer':
        if (entity.customerName != null) {
          return await _handleBalanceQuery(entity);
        }
        return AthenaResponse.question('ग्राहकको नाम स्पष्ट भएन। फेरि भन्नुहोस्।');
        
      default:
        return processVoice(input);
    }
  }

  Future<void> speak(String text) async {
    await _tts.speak(text);
  }

  void _clearContext() {
    _currentContext = null;
    _sessionData.clear();
  }

  void cancelSession() {
    _clearContext();
  }

  bool get hasActiveSession => _currentContext != null;
}

class AthenaResponse {
  final bool success;
  final String message;
  final AthenaResponseType type;
  final dynamic data;

  AthenaResponse.success(this.message, {this.data}) 
    : success = true, type = AthenaResponseType.success;
  
  AthenaResponse.question(this.message) 
    : success = true, type = AthenaResponseType.question, data = null;
  
  AthenaResponse.error(this.message) 
    : success = false, type = AthenaResponseType.error, data = null;
}

enum AthenaResponseType { success, question, error }