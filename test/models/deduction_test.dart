import 'package:flutter_test/flutter_test.dart';
import 'package:time_price/models/deduction.dart';
import 'package:time_price/models/pay_frequency.dart';

void main() {
  group('Deduction', () {
    test('fromJson parses valid deduction JSON correctly', () {
      final json = {
        'id': 'd1',
        'name': '401k',
        'amount': 5.0,
        'type': 'preTax',
        'amountType': 'percentage',
        'frequency': 'biWeekly',
      };

      final deduction = Deduction.fromJson(json);
      expect(deduction.id, equals('d1'));
      expect(deduction.name, equals('401k'));
      expect(deduction.amount, equals(5.0));
      expect(deduction.type, equals(DeductionType.preTax));
      expect(deduction.amountType, equals(DeductionAmountType.percentage));
      expect(deduction.frequency, equals(PayFrequency.biWeekly));
    });

    test('fromJson uses fallbacks for unknown type, amountType, and frequency', () {
      final json = {
        'id': 'd2',
        'name': 'Invalid',
        'amount': 100.0,
        'type': 'unknown_type',
        'amountType': 'unknown_amount_type',
        'frequency': 'unknown_frequency',
      };

      final deduction = Deduction.fromJson(json);
      expect(deduction.type, equals(DeductionType.preTax));
      expect(deduction.amountType, equals(DeductionAmountType.flat));
      expect(deduction.frequency, equals(PayFrequency.hourly));
    });

    test('calculateAnnualAmount returns 0.0 when amount is 0 or negative', () {
      const zeroDeduction = Deduction(
        id: '1',
        name: 'Zero',
        amount: 0.0,
        type: DeductionType.preTax,
        amountType: DeductionAmountType.flat,
        frequency: PayFrequency.monthly,
      );
      const negativeDeduction = Deduction(
        id: '2',
        name: 'Negative',
        amount: -50.0,
        type: DeductionType.postTax,
        amountType: DeductionAmountType.percentage,
        frequency: PayFrequency.salary,
      );

      expect(zeroDeduction.calculateAnnualAmount(100000.0), equals(0.0));
      expect(negativeDeduction.calculateAnnualAmount(100000.0), equals(0.0));
    });

    test('calculateAnnualAmount calculates flat deductions correctly for all frequencies', () {
      const hourlyFlat = Deduction(
        id: '1',
        name: 'Hourly Flat',
        amount: 10.0,
        type: DeductionType.preTax,
        amountType: DeductionAmountType.flat,
        frequency: PayFrequency.hourly,
      );
      const weeklyFlat = Deduction(
        id: '2',
        name: 'Weekly Flat',
        amount: 100.0,
        type: DeductionType.preTax,
        amountType: DeductionAmountType.flat,
        frequency: PayFrequency.weekly,
      );
      const biWeeklyFlat = Deduction(
        id: '3',
        name: 'BiWeekly Flat',
        amount: 200.0,
        type: DeductionType.preTax,
        amountType: DeductionAmountType.flat,
        frequency: PayFrequency.biWeekly,
      );
      const monthlyFlat = Deduction(
        id: '4',
        name: 'Monthly Flat',
        amount: 500.0,
        type: DeductionType.preTax,
        amountType: DeductionAmountType.flat,
        frequency: PayFrequency.monthly,
      );
      const salaryFlat = Deduction(
        id: '5',
        name: 'Salary Flat',
        amount: 5000.0,
        type: DeductionType.preTax,
        amountType: DeductionAmountType.flat,
        frequency: PayFrequency.salary,
      );

      expect(hourlyFlat.calculateAnnualAmount(100000.0), equals(20800.0)); // 10 * 2080
      expect(weeklyFlat.calculateAnnualAmount(100000.0), equals(5200.0)); // 100 * 52
      expect(biWeeklyFlat.calculateAnnualAmount(100000.0), equals(5200.0)); // 200 * 26
      expect(monthlyFlat.calculateAnnualAmount(100000.0), equals(6000.0)); // 500 * 12
      expect(salaryFlat.calculateAnnualAmount(100000.0), equals(5000.0)); // 5000 * 1
    });

    test('calculateAnnualAmount calculates percentage deductions correctly', () {
      const percentageDeduction = Deduction(
        id: '1',
        name: '401k',
        amount: 10.0, // 10%
        type: DeductionType.preTax,
        amountType: DeductionAmountType.percentage,
        frequency: PayFrequency.monthly,
      );

      expect(percentageDeduction.calculateAnnualAmount(100000.0), equals(10000.0)); // 10% of 100k
    });

    test('toJson serializes deduction fields correctly', () {
      const deduction = Deduction(
        id: 'd1',
        name: 'Health Insurance',
        amount: 150.0,
        type: DeductionType.preTax,
        amountType: DeductionAmountType.flat,
        frequency: PayFrequency.biWeekly,
      );

      expect(deduction.toJson(), equals({
        'id': 'd1',
        'name': 'Health Insurance',
        'amount': 150.0,
        'type': 'preTax',
        'amountType': 'flat',
        'frequency': 'biWeekly',
      }));
    });
  });
}
