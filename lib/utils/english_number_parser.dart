class EnglishNumberParser {
  static final Map<String, int> _englishNumbers = {
    'zero': 0, 'one': 1, 'two': 2, 'three': 3, 'four': 4, 'five': 5,
    'six': 6, 'seven': 7, 'eight': 8, 'nine': 9, 'ten': 10,
    'eleven': 11, 'twelve': 12, 'thirteen': 13, 'fourteen': 14, 'fifteen': 15,
    'sixteen': 16, 'seventeen': 17, 'eighteen': 18, 'nineteen': 19, 'twenty': 20,
    'thirty': 30, 'forty': 40, 'fifty': 50, 'sixty': 60, 'seventy': 70,
    'eighty': 80, 'ninety': 90,
  };

  static final Map<String, int> _englishMultipliers = {
    'hundred': 100,
    'thousand': 1000,
    'lakh': 100000,
    'crore': 10000000,
    'million': 1000000,
    'billion': 1000000000,
  };

  static double? parseAmount(String text) {
    try {
      // First try to find direct numeric values
      final numericPattern = RegExp(r'(\d+(?:\.\d+)?)');
      final numericMatch = numericPattern.firstMatch(text);
      if (numericMatch != null) {
        return double.tryParse(numericMatch.group(1)!);
      }

      // Parse English text numbers
      String cleanText = text.toLowerCase().trim();
      
      // Handle common amount patterns
      if (cleanText.contains('thousand')) {
        final beforeThousand = cleanText.split('thousand')[0].trim();
        final baseNumber = _parseEnglishNumber(beforeThousand) ?? 1;
        return baseNumber * 1000.0;
      }
      
      if (cleanText.contains('hundred')) {
        final beforeHundred = cleanText.split('hundred')[0].trim();
        final baseNumber = _parseEnglishNumber(beforeHundred) ?? 1;
        return baseNumber * 100.0;
      }
      
      if (cleanText.contains('lakh')) {
        final beforeLakh = cleanText.split('lakh')[0].trim();
        final baseNumber = _parseEnglishNumber(beforeLakh) ?? 1;
        return baseNumber * 100000.0;
      }

      if (cleanText.contains('crore')) {
        final beforeCrore = cleanText.split('crore')[0].trim();
        final baseNumber = _parseEnglishNumber(beforeCrore) ?? 1;
        return baseNumber * 10000000.0;
      }

      // Try to parse as simple English number
      return _parseEnglishNumber(cleanText)?.toDouble();
    } catch (e) {
      return null;
    }
  }

  static int? _parseEnglishNumber(String text) {
    text = text.trim();
    
    // Direct lookup for simple numbers
    if (_englishNumbers.containsKey(text)) {
      return _englishNumbers[text];
    }

    // Try to parse compound numbers
    int total = 0;
    List<String> words = text.split(' ');
    
    for (String word in words) {
      if (_englishNumbers.containsKey(word)) {
        total += _englishNumbers[word]!;
      } else if (_englishMultipliers.containsKey(word)) {
        if (total == 0) total = 1;
        total *= _englishMultipliers[word]!;
      }
    }
    
    return total > 0 ? total : null;
  }
}