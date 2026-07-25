import 'package:flutter_test/flutter_test.dart';
import 'package:time_price/models/income_config.dart';
import 'package:time_price/models/pay_frequency.dart';

void main() {
  group('IncomeConfig', () {
    test('fromJson parses valid JSON with all pay frequency values', () {
      final jsonHourly = {'amount': 25.0, 'frequency': 'hourly'};
      final jsonWeekly = {'amount': 1000.0, 'frequency': 'weekly'};
      final jsonBiWeekly = {'amount': 2000.0, 'frequency': 'biWeekly'};
      final jsonMonthly = {'amount': 4000.0, 'frequency': 'monthly'};
      final jsonSalary = {'amount': 52000.0, 'frequency': 'salary'};

      expect(IncomeConfig.fromJson(jsonHourly).frequency, equals(PayFrequency.hourly));
      expect(IncomeConfig.fromJson(jsonWeekly).frequency, equals(PayFrequency.weekly));
      expect(IncomeConfig.fromJson(jsonBiWeekly).frequency, equals(PayFrequency.biWeekly));
      expect(IncomeConfig.fromJson(jsonMonthly).frequency, equals(PayFrequency.monthly));
      expect(IncomeConfig.fromJson(jsonSalary).frequency, equals(PayFrequency.salary));
      expect(IncomeConfig.fromJson(jsonHourly).amount, equals(25.0));
    });

    test('fromJson defaults to PayFrequency.hourly when frequency string is unknown or missing', () {
      final jsonUnknown = {'amount': 50000.0, 'frequency': 'unknown_freq'};
      final jsonEmpty = {'amount': 50000.0, 'frequency': ''};

      expect(IncomeConfig.fromJson(jsonUnknown).frequency, equals(PayFrequency.hourly));
      expect(IncomeConfig.fromJson(jsonEmpty).frequency, equals(PayFrequency.hourly));
    });

    test('annualIncome returns 0.0 when amount is 0 or negative', () {
      const zeroIncome = IncomeConfig(amount: 0.0, frequency: PayFrequency.salary);
      const negativeIncome = IncomeConfig(amount: -100.0, frequency: PayFrequency.hourly);

      expect(zeroIncome.annualIncome, equals(0.0));
      expect(negativeIncome.annualIncome, equals(0.0));
    });

    test('annualIncome calculates correct annual amount across all pay frequencies', () {
      const hourlyConfig = IncomeConfig(amount: 25.0, frequency: PayFrequency.hourly);
      const weeklyConfig = IncomeConfig(amount: 1000.0, frequency: PayFrequency.weekly);
      const biWeeklyConfig = IncomeConfig(amount: 2000.0, frequency: PayFrequency.biWeekly);
      const monthlyConfig = IncomeConfig(amount: 4000.0, frequency: PayFrequency.monthly);
      const salaryConfig = IncomeConfig(amount: 52000.0, frequency: PayFrequency.salary);

      expect(hourlyConfig.annualIncome, equals(52000.0)); // 25 * 2080
      expect(weeklyConfig.annualIncome, equals(52000.0)); // 1000 * 52
      expect(biWeeklyConfig.annualIncome, equals(52000.0)); // 2000 * 26
      expect(monthlyConfig.annualIncome, equals(48000.0)); // 4000 * 12
      expect(salaryConfig.annualIncome, equals(52000.0)); // 52000 * 1
    });

    test('grossHourlyPay divides annual income by 2080.0', () {
      const salaryConfig = IncomeConfig(amount: 104000.0, frequency: PayFrequency.salary);
      const zeroConfig = IncomeConfig(amount: 0.0, frequency: PayFrequency.hourly);

      expect(salaryConfig.grossHourlyPay, equals(50.0)); // 104000 / 2080
      expect(zeroConfig.grossHourlyPay, equals(0.0));
    });

    test('toJson serializes properties correctly', () {
      const config = IncomeConfig(amount: 40.0, frequency: PayFrequency.biWeekly);
      final json = config.toJson();

      expect(json, equals({'amount': 40.0, 'frequency': 'biWeekly'}));
    });
  });
}
