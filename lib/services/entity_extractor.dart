import '../utils/nepali_number_parser.dart';
import '../utils/english_number_parser.dart';

class VoiceEntity {
  final String? customerName;
  final double? amount;
  final String? date;
  final String? actionType;
  final String? itemName;

  VoiceEntity({
    this.customerName,
    this.amount,
    this.date,
    this.actionType,
    this.itemName,
  });
}

class EntityExtractor {
  static final Map<String, double> _fractionWords = {
    'साढे': 0.5, 'डेढ': 1.5, 'सवा': 0.25, 'पाउना': -0.25,
    'half': 0.5, 'quarter': 0.25
  };

  static final Map<String, String> _dateWords = {
    'आज': 'today', 'हिजो': 'yesterday', 'परसि': 'day_before',
    'today': 'today', 'yesterday': 'yesterday'
  };

  static VoiceEntity extract(String text) {
    return VoiceEntity(
      customerName: _extractCustomerName(text),
      amount: _extractAmount(text),
      date: _extractDate(text),
      actionType: _extractActionType(text),
      itemName: _extractItemName(text),
    );
  }

  static String? _extractCustomerName(String text) {
    // Nepali patterns
    final nepaliPatterns = [
      RegExp(r'(\w+)को\s*खातामा', caseSensitive: false),
      RegExp(r'(\w+)ले\s*तिर्यो', caseSensitive: false),
      RegExp(r'(\w+)लाई\s*दियो', caseSensitive: false),
      RegExp(r'(\w+)को\s*बाँकी', caseSensitive: false),
    ];

    // English patterns
    final englishPatterns = [
      RegExp(r'customer\s+(\w+)', caseSensitive: false),
      RegExp(r'(\w+)\s+paid', caseSensitive: false),
      RegExp(r'credit\s+(\w+)', caseSensitive: false),
      RegExp(r'debit\s+(\w+)', caseSensitive: false),
      RegExp(r'(\w+)\s+account', caseSensitive: false),
    ];

    for (var pattern in [...nepaliPatterns, ...englishPatterns]) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(1)?.trim();
      }
    }

    return null;
  }

  static double? _extractAmount(String text) {
    // Try numeric first
    final numericPattern = RegExp(r'(\d+(?:\.\d+)?)');
    final numericMatch = numericPattern.firstMatch(text);
    if (numericMatch != null) {
      return double.tryParse(numericMatch.group(1)!);
    }

    // Handle fractions with numbers
    for (var fraction in _fractionWords.keys) {
      if (text.contains(fraction)) {
        final beforeFraction = text.split(fraction)[0].trim();
        final afterFraction = text.split(fraction)[1].trim();
        
        double? baseAmount;
        
        // Check for number before fraction
        final beforeMatch = RegExp(r'(\d+)').firstMatch(beforeFraction);
        if (beforeMatch != null) {
          baseAmount = double.tryParse(beforeMatch.group(1)!);
        }
        
        // Check for multiplier after fraction
        if (afterFraction.contains('हजार') || afterFraction.contains('thousand')) {
          baseAmount = (baseAmount ?? 0) + _fractionWords[fraction]!;
          return baseAmount * 1000;
        }
        
        if (afterFraction.contains('सय') || afterFraction.contains('hundred')) {
          baseAmount = (baseAmount ?? 0) + _fractionWords[fraction]!;
          return baseAmount * 100;
        }
        
        return (baseAmount ?? 0) + _fractionWords[fraction]!;
      }
    }

    // Use existing parsers for word numbers
    final nepaliAmount = NepaliNumberParser.parseAmount(text);
    if (nepaliAmount != null) return nepaliAmount;

    final englishAmount = EnglishNumberParser.parseAmount(text);
    if (englishAmount != null) return englishAmount;

    return null;
  }

  static String? _extractDate(String text) {
    for (var dateWord in _dateWords.keys) {
      if (text.contains(dateWord)) {
        return _dateWords[dateWord];
      }
    }

    // Try to extract explicit dates
    final datePattern = RegExp(r'(\d{1,2})[\/\-](\d{1,2})');
    final match = datePattern.firstMatch(text);
    if (match != null) {
      return '${match.group(1)}/${match.group(2)}';
    }

    return null;
  }

  static String? _extractActionType(String text) {
    final creditWords = ['हालियो', 'थप', 'जम्मा', 'credit', 'add', 'deposit'];
    final debitWords = ['तिर्यो', 'भुक्तानी', 'घटायो', 'paid', 'debit', 'minus'];

    for (var word in creditWords) {
      if (text.toLowerCase().contains(word.toLowerCase())) {
        return 'credit';
      }
    }

    for (var word in debitWords) {
      if (text.toLowerCase().contains(word.toLowerCase())) {
        return 'debit';
      }
    }

    return null;
  }

  static String? _extractItemName(String text) {
    // Simple item extraction - can be enhanced
    final itemPatterns = [
      RegExp(r'(\w+)\s*सामान', caseSensitive: false),
      RegExp(r'item\s+(\w+)', caseSensitive: false),
      RegExp(r'product\s+(\w+)', caseSensitive: false),
    ];

    for (var pattern in itemPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(1)?.trim();
      }
    }

    return null;
  }
}