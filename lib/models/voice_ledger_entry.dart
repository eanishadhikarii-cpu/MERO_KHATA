class VoiceLedgerEntry {
  final String ledgerName;
  final String transactionType; // 'credit' or 'debit'
  final double amount;
  final String language; // 'nepali' or 'english'
  final DateTime timestamp;
  final String entryMode;

  VoiceLedgerEntry({
    required this.ledgerName,
    required this.transactionType,
    required this.amount,
    required this.language,
    required this.timestamp,
    this.entryMode = 'voice',
  });

  Map<String, dynamic> toMap() {
    return {
      'ledger_name': ledgerName,
      'transaction_type': transactionType,
      'amount': amount,
      'language': language,
      'entry_mode': entryMode,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory VoiceLedgerEntry.fromMap(Map<String, dynamic> map) {
    return VoiceLedgerEntry(
      ledgerName: map['ledger_name'],
      transactionType: map['transaction_type'],
      amount: map['amount'].toDouble(),
      language: map['language'],
      timestamp: DateTime.parse(map['timestamp']),
      entryMode: map['entry_mode'] ?? 'voice',
    );
  }
}