import 'package:flutter_test/flutter_test.dart';
import 'package:time_price/models/deduction.dart';
import 'package:time_price/models/income_config.dart';
import 'package:time_price/models/pay_frequency.dart';
import 'package:time_price/models/tax_config.dart';
import 'package:time_price/services/calculation_service.dart';

void main() {
  group('Empirical Challenger M2 Verification Suite', () {
    test('1. Time Unit Conversions & Exact Seconds Decomposition', () {
      const netPayPerHr = 3600.0; // $3600/hr -> $1 per second
      final income = IncomeConfig(
        amount: netPayPerHr * 2080.0,
        frequency: PayFrequency.salary,
      );
      const tax = TaxConfig(salesTaxRate: 0.0);
      const deductions = <Deduction>[];

      // 1 second
      var res = CalculationService.calculateTimeCost(
        price: 1.0,
        income: income,
        deductions: deductions,
        tax: tax,
      );
      expect(res.months, equals(0));
      expect(res.weeks, equals(0));
      expect(res.days, equals(0));
      expect(res.hours, equals(0));
      expect(res.minutes, equals(0));
      expect(res.seconds, equals(1));
      expect(res.formattedNaturalString, equals('1 second'));

      // 60 seconds = 1 minute
      res = CalculationService.calculateTimeCost(
        price: 60.0,
        income: income,
        deductions: deductions,
        tax: tax,
      );
      expect(res.months, equals(0));
      expect(res.weeks, equals(0));
      expect(res.days, equals(0));
      expect(res.hours, equals(0));
      expect(res.minutes, equals(1));
      expect(res.seconds, equals(0));
      expect(res.formattedNaturalString, equals('1 minute'));

      // 3600 seconds = 1 hour
      res = CalculationService.calculateTimeCost(
        price: 3600.0,
        income: income,
        deductions: deductions,
        tax: tax,
      );
      expect(res.hours, equals(1));
      expect(res.minutes, equals(0));
      expect(res.seconds, equals(0));
      expect(res.formattedNaturalString, equals('1 hour'));

      // 28800 seconds = 1 day (8 hours)
      res = CalculationService.calculateTimeCost(
        price: 28800.0,
        income: income,
        deductions: deductions,
        tax: tax,
      );
      expect(res.days, equals(1));
      expect(res.hours, equals(0));
      expect(res.minutes, equals(0));
      expect(res.seconds, equals(0));
      expect(res.formattedNaturalString, equals('1 day'));

      // 144000 seconds = 1 week (40 hours = 5 days)
      res = CalculationService.calculateTimeCost(
        price: 144000.0,
        income: income,
        deductions: deductions,
        tax: tax,
      );
      expect(res.weeks, equals(1));
      expect(res.days, equals(0));
      expect(res.hours, equals(0));
      expect(res.minutes, equals(0));
      expect(res.seconds, equals(0));
      expect(res.formattedNaturalString, equals('1 week'));

      // 624000 seconds = 1 month (173.33333333333334 hours)
      res = CalculationService.calculateTimeCost(
        price: 624000.0,
        income: income,
        deductions: deductions,
        tax: tax,
      );
      expect(res.months, equals(1));
      expect(res.weeks, equals(0));
      expect(res.days, equals(0));
      expect(res.hours, equals(0));
      expect(res.minutes, equals(0));
      expect(res.seconds, equals(0));
      expect(res.formattedNaturalString, equals('1 month'));

      // All singulars combined: 624000 + 144000 + 28800 + 3600 + 60 + 1 = 796461
      res = CalculationService.calculateTimeCost(
        price: 796461.0,
        income: income,
        deductions: deductions,
        tax: tax,
      );
      expect(res.months, equals(1));
      expect(res.weeks, equals(1));
      expect(res.days, equals(1));
      expect(res.hours, equals(1));
      expect(res.minutes, equals(1));
      expect(res.seconds, equals(1));
      expect(
        res.formattedNaturalString,
        equals('1 month 1 week 1 day 1 hour 1 minute 1 second'),
      );

      // All plurals combined: 2*624000 + 3*144000 + 4*28800 + 5*3600 + 6*60 + 7 = 1797607
      res = CalculationService.calculateTimeCost(
        price: 1797607.0,
        income: income,
        deductions: deductions,
        tax: tax,
      );
      expect(res.months, equals(2));
      expect(res.weeks, equals(3));
      expect(res.days, equals(4));
      expect(res.hours, equals(5));
      expect(res.minutes, equals(6));
      expect(res.seconds, equals(7));
      expect(
        res.formattedNaturalString,
        equals('2 months 3 weeks 4 days 5 hours 6 minutes 7 seconds'),
      );
    });

    test('2. Monthly Pay Frequency & Deductions Accuracy', () {
      const income = IncomeConfig(
        amount: 5000.0, // $5,000/month -> $60,000/yr -> gross hourly = $28.846153846153847
        frequency: PayFrequency.monthly,
      );
      expect(income.annualIncome, equals(60000.0));
      expect(income.grossHourlyPay, closeTo(28.84615, 0.0001));

      // Monthly flat pre-tax deduction ($500/month -> $6,000/yr)
      const deductionPre = Deduction(
        id: '1',
        name: '401k',
        amount: 500.0,
        type: DeductionType.preTax,
        amountType: DeductionAmountType.flat,
        frequency: PayFrequency.monthly,
      );
      expect(deductionPre.calculateAnnualAmount(income.annualIncome), equals(60000.0 * 0.10));

      // Monthly percentage post-tax deduction (5% -> $3,000/yr)
      const deductionPost = Deduction(
        id: '2',
        name: 'Roth IRA',
        amount: 5.0,
        type: DeductionType.postTax,
        amountType: DeductionAmountType.percentage,
        frequency: PayFrequency.monthly,
      );
      expect(deductionPost.calculateAnnualAmount(income.annualIncome), equals(3000.0));

      final res = CalculationService.calculateTimeCost(
        price: 5100.0,
        income: income,
        deductions: [deductionPre, deductionPost],
        tax: const TaxConfig(salesTaxRate: 0.0),
      );

      // Gross: 60,000. PreTax: 6,000 -> Taxable: 54,000. PostTax: 3,000 -> Net: 51,000.
      // Net hourly pay: 51,000 / 2080 = 24.51923076923077
      expect(res.netHourlyPay, closeTo(24.51923, 0.0001));
      // Hours needed: 5100 / 24.51923076923077 = 208.0 hours.
      expect(res.totalWorkingHours, closeTo(208.0, 0.0001));
      // 208 hours = 1 month (173.333333 hrs = 624,000s) + 34.666666 hrs
      // Remainder: 34.666666 hrs = 124,800s.
      // 124,800s: 0 weeks.
      // Days: 124800 / 28800 = 4 days (115,200s), rem = 9,600s.
      // Hours: 9600 / 3600 = 2 hours (7,200s), rem = 2,400s.
      // Minutes: 2400 / 60 = 40 minutes, rem = 0s.
      expect(res.months, equals(1));
      expect(res.weeks, equals(0));
      expect(res.days, equals(4));
      expect(res.hours, equals(2));
      expect(res.minutes, equals(40));
      expect(res.seconds, equals(0));
      expect(res.formattedNaturalString, equals('1 month 4 days 2 hours 40 minutes'));
    });

    test('3. Zero Pay Rate & Unaffordable State Handling', () {
      const tax = TaxConfig(salesTaxRate: 10.0);

      // Case A: Zero income amount
      const zeroIncome = IncomeConfig(amount: 0.0, frequency: PayFrequency.hourly);
      var res = CalculationService.calculateTimeCost(
        price: 100.0,
        income: zeroIncome,
        deductions: [],
        tax: tax,
      );
      expect(res.netHourlyPay, equals(0.0));
      expect(res.totalWorkingHours, equals(double.infinity));
      expect(res.formattedNaturalString, equals('Infinity (Unaffordable)'));
      expect(res.totalPriceWithTax, equals(110.0));

      // Case B: Pre-tax deductions exceed gross income ($50k income, $60k pre-tax deduction)
      const income50k = IncomeConfig(amount: 50000.0, frequency: PayFrequency.salary);
      const excessivePreTax = Deduction(
        id: '1',
        name: 'Excessive PreTax',
        amount: 60000.0,
        type: DeductionType.preTax,
        amountType: DeductionAmountType.flat,
        frequency: PayFrequency.salary,
      );
      res = CalculationService.calculateTimeCost(
        price: 100.0,
        income: income50k,
        deductions: [excessivePreTax],
        tax: tax,
      );
      expect(res.netHourlyPay, equals(0.0));
      expect(res.totalWorkingHours, equals(double.infinity));
      expect(res.formattedNaturalString, equals('Infinity (Unaffordable)'));

      // Case C: Post-tax deductions exceed taxable income ($50k gross, $20k pre-tax -> $30k taxable, $40k post-tax)
      const preTax20k = Deduction(
        id: '1',
        name: 'PreTax 20k',
        amount: 20000.0,
        type: DeductionType.preTax,
        amountType: DeductionAmountType.flat,
        frequency: PayFrequency.salary,
      );
      const postTax40k = Deduction(
        id: '2',
        name: 'PostTax 40k',
        amount: 40000.0,
        type: DeductionType.postTax,
        amountType: DeductionAmountType.flat,
        frequency: PayFrequency.salary,
      );
      res = CalculationService.calculateTimeCost(
        price: 100.0,
        income: income50k,
        deductions: [preTax20k, postTax40k],
        tax: tax,
      );
      expect(res.netHourlyPay, equals(0.0));
      expect(res.totalWorkingHours, equals(double.infinity));
      expect(res.formattedNaturalString, equals('Infinity (Unaffordable)'));
    });

    test('4. Negative Sales Tax Rate Clamping', () {
      const income = IncomeConfig(amount: 52000.0, frequency: PayFrequency.salary); // $25/hr
      const negativeTax = TaxConfig(salesTaxRate: -15.0);

      final res = CalculationService.calculateTimeCost(
        price: 100.0,
        income: income,
        deductions: [],
        tax: negativeTax,
      );

      expect(res.totalPriceWithTax, equals(100.0)); // Clamped to 0% tax
      expect(res.netHourlyPay, equals(25.0));
      expect(res.totalWorkingHours, equals(4.0));
      expect(res.formattedNaturalString, equals('4 hours'));
    });

    test('5. Pre-tax vs Post-tax Deduction Order and Interaction', () {
      // Gross income: $100,000
      const income = IncomeConfig(amount: 100000.0, frequency: PayFrequency.salary);

      // Pre-tax percentage: 10% of gross = $10,000 -> Taxable income = $90,000
      const preTax10pct = Deduction(
        id: '1',
        name: 'PreTax 10%',
        amount: 10.0,
        type: DeductionType.preTax,
        amountType: DeductionAmountType.percentage,
        frequency: PayFrequency.salary,
      );

      // Post-tax flat: $5,000 -> Net income = $90,000 - $5,000 = $85,000
      const postTax5k = Deduction(
        id: '2',
        name: 'PostTax 5k',
        amount: 5000.0,
        type: DeductionType.postTax,
        amountType: DeductionAmountType.flat,
        frequency: PayFrequency.salary,
      );

      final res = CalculationService.calculateTimeCost(
        price: 850.0,
        income: income,
        deductions: [preTax10pct, postTax5k],
        tax: const TaxConfig(salesTaxRate: 0.0),
      );

      expect(res.netHourlyPay, equals(85000.0 / 2080.0));
      expect(res.totalWorkingHours, equals(850.0 / (85000.0 / 2080.0))); // = 20.8 hours
      // 20.8 hours = 2 days (16 hrs) + 4 hours + 48 minutes
      expect(res.days, equals(2));
      expect(res.hours, equals(4));
      expect(res.minutes, equals(48));
      expect(res.seconds, equals(0));
      expect(res.formattedNaturalString, equals('2 days 4 hours 48 minutes'));
    });

    test('6. Micro-prices, Zero Price, and Boundary Rounding', () {
      const income = IncomeConfig(amount: 25.0, frequency: PayFrequency.hourly);
      const tax = TaxConfig(salesTaxRate: 0.0);

      // Price = 0.0 -> returns '0 seconds'
      var res = CalculationService.calculateTimeCost(
        price: 0.0,
        income: income,
        deductions: [],
        tax: tax,
      );
      expect(res.totalPriceWithTax, equals(0.0));
      expect(res.totalWorkingHours, equals(0.0));
      expect(res.formattedNaturalString, equals('0 seconds'));

      // Micro price resulting in < 0.5s -> rounds to 0 seconds
      res = CalculationService.calculateTimeCost(
        price: 0.001, // $0.001 / $25 = 0.00004 hours = 0.144 seconds
        income: income,
        deductions: [],
        tax: tax,
      );
      expect(res.seconds, equals(0));
      expect(res.formattedNaturalString, equals('0 seconds'));

      // Price resulting in exactly 0.5s -> rounds to 1 second
      // 0.5 seconds / 3600 = 0.0001388888888888889 hours * $25/hr = $0.0034722222222222225
      res = CalculationService.calculateTimeCost(
        price: 0.0034722222222222225,
        income: income,
        deductions: [],
        tax: tax,
      );
      expect(res.seconds, equals(1));
      expect(res.formattedNaturalString, equals('1 second'));
    });

    test('7. Extreme Scale Stress Test', () {
      // Mega income: $10,000,000/yr ($4807.69/hr) & Mega price: $1,000,000,000 (1 Billion)
      const megaIncome = IncomeConfig(amount: 10000000.0, frequency: PayFrequency.salary);
      const tax = TaxConfig(salesTaxRate: 10.0);

      final res = CalculationService.calculateTimeCost(
        price: 1000000000.0,
        income: megaIncome,
        deductions: [],
        tax: tax,
      );

      // Price with tax = 1.1 Billion
      expect(res.totalPriceWithTax, equals(1100000000.0));
      expect(res.netHourlyPay, equals(10000000.0 / 2080.0));
      expect(res.totalWorkingHours, equals(1100000000.0 / (10000000.0 / 2080.0))); // 228,800 hours
      // 228,800 hours / 173.333333 = 1320 months exactly!
      expect(res.months, equals(1320));
      expect(res.weeks, equals(0));
      expect(res.days, equals(0));
      expect(res.hours, equals(0));
      expect(res.minutes, equals(0));
      expect(res.seconds, equals(0));
      expect(res.formattedNaturalString, equals('1320 months'));
    });
  });
}
