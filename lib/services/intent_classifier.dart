enum VoiceIntent {
  creditLedger,
  debitLedger,
  saleQuery,
  profitQuery,
  stockQuery,
  customerBalanceQuery,
  expenseAdd,
  emiQuery,
  reportQuery,
  generalHelp,
  unknown
}

class IntentClassifier {
  static final Map<VoiceIntent, List<String>> _intentKeywords = {
    VoiceIntent.creditLedger: [
      'हालियो', 'थप', 'जम्मा', 'credit', 'add', 'deposit', 'खातामा', 'दियो',
      'पैसा दियो', 'रकम दियो', 'amount add', 'money add'
    ],
    VoiceIntent.debitLedger: [
      'तिर्यो', 'भुक्तानी', 'घटायो', 'paid', 'payment', 'debit', 'minus',
      'लियो', 'फिर्ता', 'return', 'निकाल', 'withdraw'
    ],
    VoiceIntent.saleQuery: [
      'बिक्री', 'sales', 'sell', 'बेच', 'कमाई', 'earning', 'revenue',
      'आजको बिक्री', 'today sales', 'total sales'
    ],
    VoiceIntent.profitQuery: [
      'नाफा', 'मुनाफा', 'profit', 'फाइदा', 'benefit', 'gain',
      'आजको नाफा', 'today profit'
    ],
    VoiceIntent.stockQuery: [
      'स्टक', 'stock', 'सामान', 'item', 'product', 'माल',
      'सकियो', 'finished', 'कम', 'low', 'खत्म', 'empty'
    ],
    VoiceIntent.customerBalanceQuery: [
      'बाँकी', 'balance', 'due', 'उधार', 'credit balance', 'remaining',
      'कति बाँकी', 'how much due', 'बकाया'
    ],
    VoiceIntent.expenseAdd: [
      'खर्च', 'expense', 'cost', 'लागत', 'spend', 'खर्चा',
      'पैसा खर्च', 'money spent'
    ],
    VoiceIntent.emiQuery: [
      'emi', 'किस्ता', 'loan', 'ऋण', 'कर्जा', 'installment',
      'monthly payment'
    ],
    VoiceIntent.reportQuery: [
      'रिपोर्ट', 'report', 'हिसाब', 'account', 'summary', 'विवरण',
      'details', 'statement'
    ]
  };

  static VoiceIntent classify(String text) {
    text = text.toLowerCase();
    
    Map<VoiceIntent, int> scores = {};
    
    for (var intent in _intentKeywords.keys) {
      int score = 0;
      for (var keyword in _intentKeywords[intent]!) {
        if (text.contains(keyword.toLowerCase())) {
          score += keyword.length; // Longer matches get higher scores
        }
      }
      if (score > 0) scores[intent] = score;
    }
    
    if (scores.isEmpty) return VoiceIntent.unknown;
    
    // Return intent with highest score
    return scores.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }
}