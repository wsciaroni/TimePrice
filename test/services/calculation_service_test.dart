import 'package:flutter_test/flutter_test.dart';
import 'package:time_price/models/deduction.dart';
import 'package:time_price/models/income_config.dart';
import 'package:time_price/models/pay_frequency.dart';
import 'package:time_price/models/tax_config.dart';
import 'package:time_price/services/calculation_service.dart';

void main() {
  group('CalculationService', () {
    const defaultIncome = IncomeConfig(amount: 50.0, frequency: PayFrequency.hourly); // $104,000/yr ($50/hr)
    const zeroTax = TaxConfig(salesTaxRate: 0.0);

    test('returns zero TimeCostResult when price is zero or negative', () {
      final resultZero = CalculationService.calculateTimeCost(
        price: 0.0,
        income: defaultIncome,
        deductions: [],
        tax: zeroTax,
      );

      final resultNegative = CalculationService.calculateTimeCost(
        price: -15.0,
        income: defaultIncome,
        deductions: [],
        tax: zeroTax,
      );

      expect(resultZero.totalPriceWithTax, equals(0.0));
      expect(resultZero.netHourlyPay, equals(0.0));
      expect(resultZero.totalWorkingHours, equals(0.0));
      expect(resultZero.formattedNaturalString, equals('0 seconds'));

      expect(resultNegative.totalPriceWithTax, equals(0.0));
      expect(resultNegative.netHourlyPay, equals(0.0));
      expect(resultNegative.totalWorkingHours, equals(0.0));
      expect(resultNegative.formattedNaturalString, equals('0 seconds'));
    });

    test('correctly separates pre-tax and post-tax deductions', () {
      // Gross annual = $104,000 ($50/hr)
      // Pre-tax flat: $100 / bi-weekly = $2,600 / yr
      // Taxable annual = $101,400
      // Post-tax percentage: 10% of gross = $10,400 / yr
      // Net annual = $91,000
      // Net hourly pay = 91000 / 2080 = $43.75 / hr
      const preTaxDed = Deduction(
        id: 'd1',
        name: 'PreTax 401k',
        amount: 100.0,
        type: DeductionType.preTax,
        amountType: DeductionAmountType.flat,
        frequency: PayFrequency.biWeekly,
      );

      const postTaxDed = Deduction(
        id: 'd2',
        name: 'PostTax Savings',
        amount: 10.0,
        type: DeductionType.postTax,
        amountType: DeductionAmountType.percentage,
        frequency: PayFrequency.monthly,
      );

      final result = CalculationService.calculateTimeCost(
        price: 87.50, // Exactly 2 hours of net pay ($43.75 * 2)
        income: defaultIncome,
        deductions: [preTaxDed, postTaxDed],
        tax: zeroTax,
      );

      expect(result.netHourlyPay, equals(43.75));
      expect(result.totalWorkingHours, equals(2.0));
      expect(result.formattedNaturalString, equals('2 hours'));
    });

    test('clamps taxable income to 0 when pre-tax deductions exceed gross income', () {
      // Gross = $52,000 ($25/hr)
      // Pre-tax = $60,000
      const income = IncomeConfig(amount: 25.0, frequency: PayFrequency.hourly);
      const preTaxExcess = Deduction(
        id: 'd1',
        name: 'Huge PreTax',
        amount: 60000.0,
        type: DeductionType.preTax,
        amountType: DeductionAmountType.flat,
        frequency: PayFrequency.salary,
      );

      final result = CalculationService.calculateTimeCost(
        price: 100.0,
        income: income,
        deductions: [preTaxExcess],
        tax: zeroTax,
      );

      expect(result.netHourlyPay, equals(0.0));
      expect(result.totalWorkingHours, equals(double.infinity));
      expect(result.formattedNaturalString, equals('Infinity (Unaffordable)'));
    });

    test('clamps net income to 0 when post-tax deductions exceed taxable income', () {
      // Gross = $52,000 ($25/hr)
      // Pre-tax = $10,000 (Taxable = $42,000)
      // Post-tax = $50,000
      const income = IncomeConfig(amount: 25.0, frequency: PayFrequency.hourly);
      const preTax = Deduction(
        id: 'd1',
        name: 'PreTax',
        amount: 10000.0,
        type: DeductionType.preTax,
        amountType: DeductionAmountType.flat,
        frequency: PayFrequency.salary,
      );
      const postTaxExcess = Deduction(
        id: 'd2',
        name: 'Huge PostTax',
        amount: 50000.0,
        type: DeductionType.postTax,
        amountType: DeductionAmountType.flat,
        frequency: PayFrequency.salary,
      );

      final result = CalculationService.calculateTimeCost(
        price: 100.0,
        income: income,
        deductions: [preTax, postTaxExcess],
        tax: zeroTax,
      );

      expect(result.netHourlyPay, equals(0.0));
      expect(result.totalWorkingHours, equals(double.infinity));
      expect(result.formattedNaturalString, equals('Infinity (Unaffordable)'));
    });

    test('clamps negative sales tax rate to 0.0', () {
      const negativeTax = TaxConfig(salesTaxRate: -5.0);

      final result = CalculationService.calculateTimeCost(
        price: 100.0,
        income: defaultIncome,
        deductions: [],
        tax: negativeTax,
      );

      expect(result.totalPriceWithTax, equals(100.0));
    });

    test('applies positive sales tax rate correctly', () {
      const tax = TaxConfig(salesTaxRate: 10.0);

      final result = CalculationService.calculateTimeCost(
        price: 100.0,
        income: defaultIncome,
        deductions: [],
        tax: tax,
      );

      expect(result.totalPriceWithTax, closeTo(110.0, 0.001));
    });

    test('formats single time unit singulars correctly', () {
      // Net pay = $50/hr
      // 1 month = 173.33333333333334 hours -> price = 173.33333333333334 * 50 = 8666.666666666667
      final rMonth = CalculationService.calculateTimeCost(
        price: 624000.0 / 3600.0 * 50.0, // 8666.666666666667
        income: defaultIncome,
        deductions: [],
        tax: zeroTax,
      );
      expect(rMonth.months, equals(1));
      expect(rMonth.formattedNaturalString, equals('1 month'));

      // 1 week = 40 hours -> price = 40 * 50 = 2000
      final rWeek = CalculationService.calculateTimeCost(
        price: 2000.0,
        income: defaultIncome,
        deductions: [],
        tax: zeroTax,
      );
      expect(rWeek.weeks, equals(1));
      expect(rWeek.formattedNaturalString, equals('1 week'));

      // 1 day = 8 hours -> price = 8 * 50 = 400
      final rDay = CalculationService.calculateTimeCost(
        price: 400.0,
        income: defaultIncome,
        deductions: [],
        tax: zeroTax,
      );
      expect(rDay.days, equals(1));
      expect(rDay.formattedNaturalString, equals('1 day'));

      // 1 hour = 1 hour -> price = 50
      final rHour = CalculationService.calculateTimeCost(
        price: 50.0,
        income: defaultIncome,
        deductions: [],
        tax: zeroTax,
      );
      expect(rHour.hours, equals(1));
      expect(rHour.formattedNaturalString, equals('1 hour'));

      // 1 minute = 60 seconds -> price = (60/3600) * 50 = 50/60
      final rMin = CalculationService.calculateTimeCost(
        price: 50.0 / 60.0,
        income: defaultIncome,
        deductions: [],
        tax: zeroTax,
      );
      expect(rMin.minutes, equals(1));
      expect(rMin.formattedNaturalString, equals('1 minute'));

      // 1 second -> price = (1/3600) * 50 = 50/3600
      final rSec = CalculationService.calculateTimeCost(
        price: 50.0 / 3600.0,
        income: defaultIncome,
        deductions: [],
        tax: zeroTax,
      );
      expect(rSec.seconds, equals(1));
      expect(rSec.formattedNaturalString, equals('1 second'));
    });

    test('formats multi-unit plurals correctly', () {
      // 2 months, 2 weeks, 2 days, 2 hours, 2 minutes, 2 seconds
      // Total seconds = 2*624000 + 2*144000 + 2*28800 + 2*3600 + 2*60 + 2 = 1,600,922 seconds
      const totalSecs = 2 * 624000.0 + 2 * 144000.0 + 2 * 28800.0 + 2 * 3600.0 + 2 * 60.0 + 2.0;
      const price = (totalSecs / 3600.0) * 50.0;

      final result = CalculationService.calculateTimeCost(
        price: price,
        income: defaultIncome,
        deductions: [],
        tax: zeroTax,
      );

      expect(result.months, equals(2));
      expect(result.weeks, equals(2));
      expect(result.days, equals(2));
      expect(result.hours, equals(2));
      expect(result.minutes, equals(2));
      expect(result.seconds, equals(2));
      expect(
        result.formattedNaturalString,
        equals('2 months 2 weeks 2 days 2 hours 2 minutes 2 seconds'),
      );
    });

    test('handles tiny positive price resulting in sub-second rounding (0 seconds)', () {
      final result = CalculationService.calculateTimeCost(
        price: 0.000001,
        income: defaultIncome,
        deductions: [],
        tax: zeroTax,
      );

      expect(result.formattedNaturalString, equals('0 seconds'));
    });

    test('handles Monthly pay frequency income and monthly deductions accurately', () {
      // Monthly income $5,000 / month = $60,000 annual -> $28.846153846153847 / hr
      const monthlyIncome = IncomeConfig(amount: 5000.0, frequency: PayFrequency.monthly);
      const monthlyDeduction = Deduction(
        id: 'm1',
        name: 'Health',
        amount: 500.0,
        type: DeductionType.preTax,
        amountType: DeductionAmountType.flat,
        frequency: PayFrequency.monthly,
      ); // $6,000 annual pre-tax deduction -> Taxable annual = $54,000

      final result = CalculationService.calculateTimeCost(
        price: 519.2307692307693, // Exactly 20 hours at net wage of $25.96153846153846/hr ($54,000 / 2080)
        income: monthlyIncome,
        deductions: [monthlyDeduction],
        tax: zeroTax,
      );

      expect(result.netHourlyPay, closeTo(25.9615, 0.001));
      expect(result.totalWorkingHours, closeTo(20.0, 0.001));
      expect(result.days, equals(2));
      expect(result.hours, equals(4)); // 20 hours = 2 days (16 hrs) + 4 hours
      expect(result.formattedNaturalString, equals('2 days 4 hours'));
    });
  });
}
