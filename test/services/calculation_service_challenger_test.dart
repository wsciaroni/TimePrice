import 'package:flutter_test/flutter_test.dart';
import 'package:time_price/models/deduction.dart';
import 'package:time_price/models/income_config.dart';
import 'package:time_price/models/pay_frequency.dart';
import 'package:time_price/models/tax_config.dart';
import 'package:time_price/services/calculation_service.dart';

void main() {
  group('CalculationService Adversarial & Edge Case Challenger Suite', () {
    const zeroTax = TaxConfig(salesTaxRate: 0.0);

    group('1. Income Frequency Mathematical Precision (2080h, 52w, 26w, 12m, 1yr)', () {
      test(r'Hourly income: $25.00/hr = $52,000 annual', () {
        const income = IncomeConfig(amount: 25.0, frequency: PayFrequency.hourly);
        expect(income.annualIncome, equals(52000.0));
        expect(income.grossHourlyPay, equals(25.0));

        final result = CalculationService.calculateTimeCost(
          price: 50.0,
          income: income,
          deductions: [],
          tax: zeroTax,
        );
        expect(result.netHourlyPay, equals(25.0));
        expect(result.totalWorkingHours, equals(2.0));
        expect(result.formattedNaturalString, equals('2 hours'));
      });

      test(r'Weekly income: $1,000.00/wk = $52,000 annual ($25.00/hr)', () {
        const income = IncomeConfig(amount: 1000.0, frequency: PayFrequency.weekly);
        expect(income.annualIncome, equals(52000.0));
        expect(income.grossHourlyPay, equals(25.0));

        final result = CalculationService.calculateTimeCost(
          price: 50.0,
          income: income,
          deductions: [],
          tax: zeroTax,
        );
        expect(result.netHourlyPay, equals(25.0));
        expect(result.totalWorkingHours, equals(2.0));
        expect(result.formattedNaturalString, equals('2 hours'));
      });

      test(r'BiWeekly income: $2,000.00/biwk = $52,000 annual ($25.00/hr)', () {
        const income = IncomeConfig(amount: 2000.0, frequency: PayFrequency.biWeekly);
        expect(income.annualIncome, equals(52000.0));
        expect(income.grossHourlyPay, equals(25.0));

        final result = CalculationService.calculateTimeCost(
          price: 50.0,
          income: income,
          deductions: [],
          tax: zeroTax,
        );
        expect(result.netHourlyPay, equals(25.0));
        expect(result.totalWorkingHours, equals(2.0));
        expect(result.formattedNaturalString, equals('2 hours'));
      });

      test(r'Monthly income: $5,000.00/mo = $60,000 annual ($28.846153846153847/hr)', () {
        const income = IncomeConfig(amount: 5000.0, frequency: PayFrequency.monthly);
        expect(income.annualIncome, equals(60000.0));
        expect(income.grossHourlyPay, closeTo(28.8461538, 0.0001));

        final result = CalculationService.calculateTimeCost(
          price: 60000.0 / 2080.0 * 2.0,
          income: income,
          deductions: [],
          tax: zeroTax,
        );
        expect(result.netHourlyPay, closeTo(28.8461538, 0.0001));
        expect(result.totalWorkingHours, closeTo(2.0, 0.0001));
        expect(result.formattedNaturalString, equals('2 hours'));
      });

      test(r'Salary income: $104,000.00/yr = $104,000 annual ($50.00/hr)', () {
        const income = IncomeConfig(amount: 104000.0, frequency: PayFrequency.salary);
        expect(income.annualIncome, equals(104000.0));
        expect(income.grossHourlyPay, equals(50.0));

        final result = CalculationService.calculateTimeCost(
          price: 100.0,
          income: income,
          deductions: [],
          tax: zeroTax,
        );
        expect(result.netHourlyPay, equals(50.0));
        expect(result.totalWorkingHours, equals(2.0));
        expect(result.formattedNaturalString, equals('2 hours'));
      });
    });

    group('2. Deduction Frequency Mismatches with Income Pay Frequency', () {
      const salaryIncome = IncomeConfig(amount: 104000.0, frequency: PayFrequency.salary); // $50/hr gross

      test(r'Salary pay ($104,000/yr) with Hourly flat deduction ($5/hr = $10,400/yr)', () {
        const hourlyDed = Deduction(
          id: 'd_hr',
          name: 'Hourly Union Dues',
          amount: 5.0,
          type: DeductionType.preTax,
          amountType: DeductionAmountType.flat,
          frequency: PayFrequency.hourly,
        );
        final result = CalculationService.calculateTimeCost(
          price: 90.0,
          income: salaryIncome,
          deductions: [hourlyDed],
          tax: zeroTax,
        );
        expect(result.netHourlyPay, equals(45.0));
        expect(result.totalWorkingHours, equals(2.0));
        expect(result.formattedNaturalString, equals('2 hours'));
      });

      test(r'Salary pay ($104,000/yr) with Weekly flat deduction ($100/wk = $5,200/yr)', () {
        const weeklyDed = Deduction(
          id: 'd_wk',
          name: 'Weekly Benefit',
          amount: 100.0,
          type: DeductionType.preTax,
          amountType: DeductionAmountType.flat,
          frequency: PayFrequency.weekly,
        );
        final result = CalculationService.calculateTimeCost(
          price: 95.0,
          income: salaryIncome,
          deductions: [weeklyDed],
          tax: zeroTax,
        );
        expect(result.netHourlyPay, equals(47.5));
        expect(result.totalWorkingHours, equals(2.0));
        expect(result.formattedNaturalString, equals('2 hours'));
      });

      test(r'Salary pay ($104,000/yr) with BiWeekly flat deduction ($200/biwk = $5,200/yr)', () {
        const biwkDed = Deduction(
          id: 'd_biwk',
          name: 'BiWeekly Transit',
          amount: 200.0,
          type: DeductionType.preTax,
          amountType: DeductionAmountType.flat,
          frequency: PayFrequency.biWeekly,
        );
        final result = CalculationService.calculateTimeCost(
          price: 95.0,
          income: salaryIncome,
          deductions: [biwkDed],
          tax: zeroTax,
        );
        expect(result.netHourlyPay, equals(47.5));
        expect(result.totalWorkingHours, equals(2.0));
      });

      test(r'Salary pay ($104,000/yr) with Monthly flat deduction ($500/mo = $6,000/yr)', () {
        const monthlyDed = Deduction(
          id: 'd_mo',
          name: 'Monthly Health',
          amount: 500.0,
          type: DeductionType.preTax,
          amountType: DeductionAmountType.flat,
          frequency: PayFrequency.monthly,
        );
        final result = CalculationService.calculateTimeCost(
          price: 94.23076923076923,
          income: salaryIncome,
          deductions: [monthlyDed],
          tax: zeroTax,
        );
        expect(result.netHourlyPay, closeTo(47.11538, 0.0001));
        expect(result.totalWorkingHours, closeTo(2.0, 0.0001));
      });

      test(r'Monthly pay ($5,000/mo = $60,000/yr) with Weekly deduction ($50/wk = $2,600/yr)', () {
        const monthlyIncome = IncomeConfig(amount: 5000.0, frequency: PayFrequency.monthly);
        const weeklyDed = Deduction(
          id: 'd_wk2',
          name: 'Weekly Parking',
          amount: 50.0,
          type: DeductionType.postTax,
          amountType: DeductionAmountType.flat,
          frequency: PayFrequency.weekly,
        );
        final result = CalculationService.calculateTimeCost(
          price: 55.192307692307694,
          income: monthlyIncome,
          deductions: [weeklyDed],
          tax: zeroTax,
        );
        expect(result.netHourlyPay, closeTo(27.59615, 0.0001));
        expect(result.totalWorkingHours, closeTo(2.0, 0.0001));
      });
    });

    group('3. Pre-Tax vs Post-Tax Order and Deduction Interaction', () {
      const grossIncome = IncomeConfig(amount: 104000.0, frequency: PayFrequency.salary); // $50/hr

      test(r'Pre-tax flat + Post-tax percentage interaction', () {
        const d1 = Deduction(
          id: 'd1',
          name: '401k',
          amount: 100.0,
          type: DeductionType.preTax,
          amountType: DeductionAmountType.flat,
          frequency: PayFrequency.biWeekly,
        );
        const d2 = Deduction(
          id: 'd2',
          name: 'Roth IRA',
          amount: 10.0,
          type: DeductionType.postTax,
          amountType: DeductionAmountType.percentage,
          frequency: PayFrequency.monthly,
        );

        final result = CalculationService.calculateTimeCost(
          price: 87.50,
          income: grossIncome,
          deductions: [d1, d2],
          tax: zeroTax,
        );

        expect(result.netHourlyPay, equals(43.75));
        expect(result.totalWorkingHours, equals(2.0));
      });

      test(r'Pre-tax percentage + Post-tax flat interaction', () {
        const income = IncomeConfig(amount: 100000.0, frequency: PayFrequency.salary);
        const d1 = Deduction(
          id: 'd1',
          name: 'PreTax 5%',
          amount: 5.0,
          type: DeductionType.preTax,
          amountType: DeductionAmountType.percentage,
          frequency: PayFrequency.salary,
        );
        const d2 = Deduction(
          id: 'd2',
          name: r'PostTax Flat $100/mo',
          amount: 100.0,
          type: DeductionType.postTax,
          amountType: DeductionAmountType.flat,
          frequency: PayFrequency.monthly,
        );

        final result = CalculationService.calculateTimeCost(
          price: 90.1923076923077,
          income: income,
          deductions: [d1, d2],
          tax: zeroTax,
        );

        expect(result.netHourlyPay, closeTo(45.09615, 0.0001));
        expect(result.totalWorkingHours, closeTo(2.0, 0.0001));
      });

      test(r'Pre-tax percentage + Post-tax percentage interaction', () {
        const income = IncomeConfig(amount: 100000.0, frequency: PayFrequency.salary);
        const d1 = Deduction(
          id: 'd1',
          name: 'PreTax 10%',
          amount: 10.0,
          type: DeductionType.preTax,
          amountType: DeductionAmountType.percentage,
          frequency: PayFrequency.salary,
        );
        const d2 = Deduction(
          id: 'd2',
          name: 'PostTax 20%',
          amount: 20.0,
          type: DeductionType.postTax,
          amountType: DeductionAmountType.percentage,
          frequency: PayFrequency.salary,
        );

        final result = CalculationService.calculateTimeCost(
          price: 67.3076923076923,
          income: income,
          deductions: [d1, d2],
          tax: zeroTax,
        );

        expect(result.netHourlyPay, closeTo(33.65384, 0.0001));
        expect(result.totalWorkingHours, closeTo(2.0, 0.0001));
      });

      test(r'Pre-tax deductions equal to 100% of income', () {
        const income = IncomeConfig(amount: 50000.0, frequency: PayFrequency.salary);
        const d1 = Deduction(
          id: 'd1',
          name: '100% PreTax',
          amount: 100.0,
          type: DeductionType.preTax,
          amountType: DeductionAmountType.percentage,
          frequency: PayFrequency.salary,
        );

        final result = CalculationService.calculateTimeCost(
          price: 100.0,
          income: income,
          deductions: [d1],
          tax: zeroTax,
        );

        expect(result.netHourlyPay, equals(0.0));
        expect(result.totalWorkingHours, equals(double.infinity));
        expect(result.formattedNaturalString, equals('Infinity (Unaffordable)'));
      });
    });

    group('4. Extreme Sales Tax Rates and Border Conditions', () {
      const defaultIncome = IncomeConfig(amount: 50.0, frequency: PayFrequency.hourly); // $50/hr net

      test(r'Sales tax = 0%: Price $100 => Total price $100', () {
        final result = CalculationService.calculateTimeCost(
          price: 100.0,
          income: defaultIncome,
          deductions: [],
          tax: const TaxConfig(salesTaxRate: 0.0),
        );
        expect(result.totalPriceWithTax, equals(100.0));
        expect(result.totalWorkingHours, equals(2.0));
      });

      test(r'Sales tax = 100%: Price $100 => Total price $200', () {
        final result = CalculationService.calculateTimeCost(
          price: 100.0,
          income: defaultIncome,
          deductions: [],
          tax: const TaxConfig(salesTaxRate: 100.0),
        );
        expect(result.totalPriceWithTax, equals(200.0));
        expect(result.totalWorkingHours, equals(4.0));
      });

      test(r'Sales tax = 500%: Price $100 => Total price $600', () {
        final result = CalculationService.calculateTimeCost(
          price: 100.0,
          income: defaultIncome,
          deductions: [],
          tax: const TaxConfig(salesTaxRate: 500.0),
        );
        expect(result.totalPriceWithTax, equals(600.0));
        expect(result.totalWorkingHours, equals(12.0));
      });

      test(r'Sales tax = 10,000%: Price $10 => Total price $1,010', () {
        final result = CalculationService.calculateTimeCost(
          price: 10.0,
          income: defaultIncome,
          deductions: [],
          tax: const TaxConfig(salesTaxRate: 10000.0),
        );
        expect(result.totalPriceWithTax, equals(1010.0));
        expect(result.totalWorkingHours, equals(20.2));
      });

      test(r'Negative sales tax (-25.0%) is clamped to 0.0%', () {
        final result = CalculationService.calculateTimeCost(
          price: 100.0,
          income: defaultIncome,
          deductions: [],
          tax: const TaxConfig(salesTaxRate: -25.0),
        );
        expect(result.totalPriceWithTax, equals(100.0));
      });
    });

    group('5. Edge Case Inputs (Zero, Negative, Extreme Numbers)', () {
      const defaultIncome = IncomeConfig(amount: 50.0, frequency: PayFrequency.hourly);

      test(r'Price = 0.0 returns 0 seconds and zero values', () {
        final result = CalculationService.calculateTimeCost(
          price: 0.0,
          income: defaultIncome,
          deductions: [],
          tax: zeroTax,
        );
        expect(result.totalPriceWithTax, equals(0.0));
        expect(result.netHourlyPay, equals(0.0));
        expect(result.totalWorkingHours, equals(0.0));
        expect(result.formattedNaturalString, equals('0 seconds'));
      });

      test(r'Negative price (-$500.0) returns 0 seconds and zero values', () {
        final result = CalculationService.calculateTimeCost(
          price: -500.0,
          income: defaultIncome,
          deductions: [],
          tax: zeroTax,
        );
        expect(result.totalPriceWithTax, equals(0.0));
        expect(result.netHourlyPay, equals(0.0));
        expect(result.totalWorkingHours, equals(0.0));
        expect(result.formattedNaturalString, equals('0 seconds'));
      });

      test(r'Negative income amount (-$20/hr) results in Infinity (Unaffordable)', () {
        const negativeIncome = IncomeConfig(amount: -20.0, frequency: PayFrequency.hourly);
        final result = CalculationService.calculateTimeCost(
          price: 100.0,
          income: negativeIncome,
          deductions: [],
          tax: zeroTax,
        );
        expect(result.netHourlyPay, equals(0.0));
        expect(result.totalWorkingHours, equals(double.infinity));
        expect(result.formattedNaturalString, equals('Infinity (Unaffordable)'));
      });

      test(r'Negative deduction amount (-$50) returns 0 annual deduction amount', () {
        const negDed = Deduction(
          id: 'neg',
          name: 'Negative Deduction',
          amount: -50.0,
          type: DeductionType.preTax,
          amountType: DeductionAmountType.flat,
          frequency: PayFrequency.monthly,
        );
        expect(negDed.calculateAnnualAmount(100000.0), equals(0.0));

        final result = CalculationService.calculateTimeCost(
          price: 100.0,
          income: defaultIncome, // $50/hr
          deductions: [negDed],
          tax: zeroTax,
        );
        expect(result.netHourlyPay, equals(50.0));
        expect(result.totalWorkingHours, equals(2.0));
      });

      test(r'Extremely large price ($1,000,000,000) handles calculation cleanly', () {
        final result = CalculationService.calculateTimeCost(
          price: 1000000000.0, // $1 Billion
          income: defaultIncome, // $50/hr
          deductions: [],
          tax: zeroTax,
        );
        expect(result.totalWorkingHours, equals(20000000.0)); // 20M hours
        expect(result.months, equals(115384));
        expect(result.formattedNaturalString, contains('months'));
      });
    });

    group('6. Exact Time Breakdown & Formatting Precision', () {
      const income50 = IncomeConfig(amount: 50.0, frequency: PayFrequency.hourly);

      test('Exact 1 Month (173.333333 hours / 624,000 seconds)', () {
        final result = CalculationService.calculateTimeCost(
          price: (624000.0 / 3600.0) * 50.0,
          income: income50,
          deductions: [],
          tax: zeroTax,
        );
        expect(result.months, equals(1));
        expect(result.weeks, equals(0));
        expect(result.days, equals(0));
        expect(result.hours, equals(0));
        expect(result.minutes, equals(0));
        expect(result.seconds, equals(0));
        expect(result.formattedNaturalString, equals('1 month'));
      });

      test('Exact 1 Week (40 hours / 144,000 seconds)', () {
        final result = CalculationService.calculateTimeCost(
          price: 2000.0,
          income: income50,
          deductions: [],
          tax: zeroTax,
        );
        expect(result.months, equals(0));
        expect(result.weeks, equals(1));
        expect(result.days, equals(0));
        expect(result.hours, equals(0));
        expect(result.minutes, equals(0));
        expect(result.seconds, equals(0));
        expect(result.formattedNaturalString, equals('1 week'));
      });

      test('Exact 1 Day (8 hours / 28,800 seconds)', () {
        final result = CalculationService.calculateTimeCost(
          price: 400.0,
          income: income50,
          deductions: [],
          tax: zeroTax,
        );
        expect(result.days, equals(1));
        expect(result.formattedNaturalString, equals('1 day'));
      });

      test('Mixed breakdown: 1 month, 1 week, 1 day, 1 hour, 1 minute, 1 second', () {
        const totalSecs = 624000.0 + 144000.0 + 28800.0 + 3600.0 + 60.0 + 1.0;
        final result = CalculationService.calculateTimeCost(
          price: (totalSecs / 3600.0) * 50.0,
          income: income50,
          deductions: [],
          tax: zeroTax,
        );
        expect(result.months, equals(1));
        expect(result.weeks, equals(1));
        expect(result.days, equals(1));
        expect(result.hours, equals(1));
        expect(result.minutes, equals(1));
        expect(result.seconds, equals(1));
        expect(
          result.formattedNaturalString,
          equals('1 month 1 week 1 day 1 hour 1 minute 1 second'),
        );
      });
    });

    group('7. Model Serialization & Deserialization Safety', () {
      test('IncomeConfig json roundtrip & fallback', () {
        const ic = IncomeConfig(amount: 75.0, frequency: PayFrequency.biWeekly);
        final json = ic.toJson();
        expect(json['amount'], equals(75.0));
        expect(json['frequency'], equals('biWeekly'));

        final decoded = IncomeConfig.fromJson(json);
        expect(decoded.amount, equals(75.0));
        expect(decoded.frequency, equals(PayFrequency.biWeekly));

        final fallback = IncomeConfig.fromJson({'amount': 50, 'frequency': 'unknown_frequency'});
        expect(fallback.frequency, equals(PayFrequency.hourly));
      });

      test('TaxConfig json roundtrip', () {
        const tc = TaxConfig(salesTaxRate: 8.875);
        final json = tc.toJson();
        final decoded = TaxConfig.fromJson(json);
        expect(decoded.salesTaxRate, equals(8.875));
        expect(decoded.taxMultiplier, equals(1.08875));
      });

      test('Deduction json roundtrip & fallback', () {
        const d = Deduction(
          id: 'ded_1',
          name: 'Health Insurance',
          amount: 150.0,
          type: DeductionType.preTax,
          amountType: DeductionAmountType.flat,
          frequency: PayFrequency.monthly,
        );
        final json = d.toJson();
        final decoded = Deduction.fromJson(json);
        expect(decoded.id, equals('ded_1'));
        expect(decoded.name, equals('Health Insurance'));
        expect(decoded.amount, equals(150.0));
        expect(decoded.type, equals(DeductionType.preTax));
        expect(decoded.amountType, equals(DeductionAmountType.flat));
        expect(decoded.frequency, equals(PayFrequency.monthly));

        final fallback = Deduction.fromJson({
          'id': 'd_fallback',
          'name': 'Fallback',
          'amount': 20,
          'type': 'invalid_type',
          'amountType': 'invalid_amount_type',
          'frequency': 'invalid_frequency',
        });
        expect(fallback.type, equals(DeductionType.preTax));
        expect(fallback.amountType, equals(DeductionAmountType.flat));
        expect(fallback.frequency, equals(PayFrequency.hourly));
      });
    });
  });
}
