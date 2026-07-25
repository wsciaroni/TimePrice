import 'package:time_price/models/pay_frequency.dart';

enum DeductionType { preTax, postTax }

enum DeductionAmountType { flat, percentage }

class Deduction {
  const Deduction({
    required this.id,
    required this.name,
    required this.amount,
    required this.type,
    required this.amountType,
    required this.frequency,
  });

  factory Deduction.fromJson(Map<String, dynamic> json) {
    return Deduction(
      id: json['id'] as String,
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: DeductionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => DeductionType.preTax,
      ),
      amountType: DeductionAmountType.values.firstWhere(
        (e) => e.name == json['amountType'],
        orElse: () => DeductionAmountType.flat,
      ),
      frequency: PayFrequency.values.firstWhere(
        (e) => e.name == json['frequency'],
        orElse: () => PayFrequency.hourly,
      ),
    );
  }

  final String id;
  final String name;
  final double amount;
  final DeductionType type;
  final DeductionAmountType amountType;
  final PayFrequency frequency;

  double calculateAnnualAmount(double grossAnnualIncome) {
    if (amount <= 0) return 0.0;
    if (amountType == DeductionAmountType.flat) {
      return amount * frequency.payPeriodsPerYear;
    } else {
      return (amount / 100.0) * grossAnnualIncome;
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'amount': amount,
    'type': type.name,
    'amountType': amountType.name,
    'frequency': frequency.name,
  };
}
