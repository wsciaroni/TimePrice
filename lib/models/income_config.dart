import 'package:time_price/models/pay_frequency.dart';

class IncomeConfig {
  const IncomeConfig({required this.amount, required this.frequency});

  factory IncomeConfig.fromJson(Map<String, dynamic> json) {
    return IncomeConfig(
      amount: (json['amount'] as num).toDouble(),
      frequency: PayFrequency.values.firstWhere(
        (e) => e.name == json['frequency'],
        orElse: () => PayFrequency.hourly,
      ),
    );
  }

  final double amount;
  final PayFrequency frequency;

  double get annualIncome {
    if (amount <= 0) return 0.0;
    switch (frequency) {
      case PayFrequency.hourly:
        return amount * 2080.0;
      case PayFrequency.weekly:
        return amount * 52.0;
      case PayFrequency.biWeekly:
        return amount * 26.0;
      case PayFrequency.monthly:
        return amount * 12.0;
      case PayFrequency.salary:
        return amount;
    }
  }

  double get grossHourlyPay => annualIncome / 2080.0;

  Map<String, dynamic> toJson() => {
    'amount': amount,
    'frequency': frequency.name,
  };
}
