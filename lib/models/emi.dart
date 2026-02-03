import 'dart:math';

class EMI {
  final int? id;
  final String lenderName;
  final double loanAmount;
  final String interestType; // 'flat' or 'reducing'
  final double interestRate;
  final double emiAmount;
  final DateTime startDate;
  final int durationMonths;
  final double totalPayable;
  final double totalInterest;
  final double remainingBalance;
  final bool isCompleted;
  final DateTime createdAt;

  EMI({
    this.id,
    required this.lenderName,
    required this.loanAmount,
    required this.interestType,
    required this.interestRate,
    required this.emiAmount,
    required this.startDate,
    required this.durationMonths,
    required this.totalPayable,
    required this.totalInterest,
    required this.remainingBalance,
    this.isCompleted = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'lender_name': lenderName,
      'loan_amount': loanAmount,
      'interest_type': interestType,
      'interest_rate': interestRate,
      'emi_amount': emiAmount,
      'start_date': startDate.toIso8601String(),
      'duration_months': durationMonths,
      'total_payable': totalPayable,
      'total_interest': totalInterest,
      'remaining_balance': remainingBalance,
      'is_completed': isCompleted ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory EMI.fromMap(Map<String, dynamic> map) {
    return EMI(
      id: map['id'],
      lenderName: map['lender_name'],
      loanAmount: map['loan_amount'].toDouble(),
      interestType: map['interest_type'],
      interestRate: map['interest_rate'].toDouble(),
      emiAmount: map['emi_amount'].toDouble(),
      startDate: DateTime.parse(map['start_date']),
      durationMonths: map['duration_months'],
      totalPayable: map['total_payable'].toDouble(),
      totalInterest: map['total_interest'].toDouble(),
      remainingBalance: map['remaining_balance'].toDouble(),
      isCompleted: map['is_completed'] == 1,
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  static double calculateEMI(double principal, double rate, int months, String type) {
    if (type == 'flat') {
      double interest = (principal * rate * months) / (12 * 100);
      return (principal + interest) / months;
    } else {
      double monthlyRate = rate / (12 * 100);
      return (principal * monthlyRate * pow(1 + monthlyRate, months)) / 
             (pow(1 + monthlyRate, months) - 1);
    }
  }

  static double calculateTotalPayable(double emi, int months) {
    return emi * months;
  }
}

class EMIPayment {
  final int? id;
  final int emiId;
  final DateTime dueDate;
  final double amount;
  final double paidAmount;
  final String status; // 'pending', 'paid', 'partial', 'overdue'
  final DateTime? paidDate;
  final DateTime createdAt;

  EMIPayment({
    this.id,
    required this.emiId,
    required this.dueDate,
    required this.amount,
    this.paidAmount = 0.0,
    this.status = 'pending',
    this.paidDate,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'emi_id': emiId,
      'due_date': dueDate.toIso8601String(),
      'amount': amount,
      'paid_amount': paidAmount,
      'status': status,
      'paid_date': paidDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory EMIPayment.fromMap(Map<String, dynamic> map) {
    return EMIPayment(
      id: map['id'],
      emiId: map['emi_id'],
      dueDate: DateTime.parse(map['due_date']),
      amount: map['amount'].toDouble(),
      paidAmount: map['paid_amount']?.toDouble() ?? 0.0,
      status: map['status'],
      paidDate: map['paid_date'] != null ? DateTime.parse(map['paid_date']) : null,
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}