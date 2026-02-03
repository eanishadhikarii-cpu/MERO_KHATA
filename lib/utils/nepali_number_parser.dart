class NepaliNumberParser {
  static final Map<String, int> _nepaliNumbers = {
    'शून्य': 0, 'एक': 1, 'दुई': 2, 'तीन': 3, 'चार': 4, 'पाँच': 5,
    'छ': 6, 'सात': 7, 'आठ': 8, 'नौ': 9, 'दश': 10,
    'एघार': 11, 'बाह्र': 12, 'तेह्र': 13, 'चौध': 14, 'पन्ध्र': 15,
    'सोह्र': 16, 'सत्र': 17, 'अठार': 18, 'उन्नाइस': 19, 'बीस': 20,
    'तीस': 30, 'चालीस': 40, 'पचास': 50, 'साठी': 60, 'सत्तरी': 70,
    'असी': 80, 'नब्बे': 90, 'सय': 100,
  };

  static final Map<String, int> _nepaliMultipliers = {
    'सय': 100, 'हजार': 1000, 'लाख': 100000, 'करोड': 10000000,
  };

  static final Map<String, double> _fractions = {
    'साढे': 0.5, 'डेढ': 1.5, 'सवा': 0.25, 'पाउना': -0.25,
  };

  static double? parseAmount(String text) {
    try {
      // Handle fractions first
      for (var fraction in _fractions.keys) {
        if (text.contains(fraction)) {
          final parts = text.split(fraction);
          if (parts.length >= 2) {
            final beforePart = parts[0].trim();
            final afterPart = parts[1].trim();
            
            double baseAmount = 0;
            
            // Parse number before fraction
            if (beforePart.isNotEmpty) {
              final beforeNum = _parseNepaliNumber(beforePart);
              if (beforeNum != null) baseAmount = beforeNum.toDouble();
            }
            
            // Add fraction
            if (fraction == 'डेढ') {
              baseAmount = 1.5;
            } else {
              baseAmount += _fractions[fraction]!;
            }
            
            // Handle multipliers after fraction
            if (afterPart.contains('हजार')) return baseAmount * 1000;
            if (afterPart.contains('सय')) return baseAmount * 100;
            if (afterPart.contains('लाख')) return baseAmount * 100000;
            
            return baseAmount;
          }
        }
      }
      
      // Try numeric first
      final numericPattern = RegExp(r'(\d+(?:\.\d+)?)');
      final numericMatch = numericPattern.firstMatch(text);
      if (numericMatch != null) {
        return double.tryParse(numericMatch.group(1)!);
      }

      // Parse Nepali text numbers
      String cleanText = text.toLowerCase().trim();
      
      if (cleanText.contains('हजार')) {
        final beforeHazar = cleanText.split('हजार')[0].trim();
        final baseNumber = _parseNepaliNumber(beforeHazar) ?? 1;
        return baseNumber * 1000.0;
      }
      
      if (cleanText.contains('सय')) {
        final beforeSay = cleanText.split('सय')[0].trim();
        final baseNumber = _parseNepaliNumber(beforeSay) ?? 1;
        return baseNumber * 100.0;
      }
      
      if (cleanText.contains('लाख')) {
        final beforeLakh = cleanText.split('लाख')[0].trim();
        final baseNumber = _parseNepaliNumber(beforeLakh) ?? 1;
        return baseNumber * 100000.0;
      }

      return _parseNepaliNumber(cleanText)?.toDouble();
    } catch (e) {
      return null;
    }
  }

  static int? _parseNepaliNumber(String text) {
    text = text.trim();
    
    if (_nepaliNumbers.containsKey(text)) {
      return _nepaliNumbers[text];
    }

    int total = 0;
    List<String> words = text.split(' ');
    
    for (String word in words) {
      if (_nepaliNumbers.containsKey(word)) {
        total += _nepaliNumbers[word]!;
      } else if (_nepaliMultipliers.containsKey(word)) {
        if (total == 0) total = 1;
        total *= _nepaliMultipliers[word]!;
      }
    }
    
    return total > 0 ? total : null;
  }
}