import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:time_price/main.dart';
import 'package:time_price/services/persistence_service.dart';
import 'package:time_price/services/calculation_service.dart';
import 'package:time_price/models/income_config.dart';
import 'package:time_price/models/pay_frequency.dart';
import 'package:time_price/models/deduction.dart';
import 'package:time_price/models/tax_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'time_price_onboarding_completed': true,
    });
  });

  group('Tier 2: Boundary & Corner Cases E2E Tests', () {
    test(
      '2.1 Empty and invalid non-numeric price string inputs handle gracefully',
      () {
        final resEmpty = CalculationService.calculateTimeCost(
          price: 0.0,
          income: const IncomeConfig(
            amount: 25.0,
            frequency: PayFrequency.hourly,
          ),
          deductions: [],
          tax: const TaxConfig(salesTaxRate: 0.0),
        );

        expect(resEmpty.formattedNaturalString, equals('0 seconds'));
        expect(resEmpty.totalWorkingHours, equals(0.0));
      },
    );

    test('2.2 Zero pay input (\$0/hr) yields Infinity (Unaffordable)', () {
      final resZero = CalculationService.calculateTimeCost(
        price: 50.0,
        income: const IncomeConfig(amount: 0.0, frequency: PayFrequency.hourly),
        deductions: [],
        tax: const TaxConfig(salesTaxRate: 0.0),
      );

      expect(resZero.netHourlyPay, equals(0.0));
      expect(resZero.totalWorkingHours.isInfinite, isTrue);
      expect(resZero.formattedNaturalString, equals('Infinity (Unaffordable)'));
    });

    test(
      '2.3 Negative pay input is clamped and yields Infinity for non-zero prices',
      () {
        final resNeg = CalculationService.calculateTimeCost(
          price: 25.0,
          income: const IncomeConfig(
            amount: -100.0,
            frequency: PayFrequency.hourly,
          ),
          deductions: [],
          tax: const TaxConfig(salesTaxRate: 0.0),
        );

        expect(resNeg.netHourlyPay, equals(0.0));
        expect(resNeg.totalWorkingHours.isInfinite, isTrue);
        expect(
          resNeg.formattedNaturalString,
          equals('Infinity (Unaffordable)'),
        );
      },
    );

    test(
      '2.4 Deductions exceeding gross income (100% deduction) reduce net pay to 0.0',
      () {
        final resOverDeduct = CalculationService.calculateTimeCost(
          price: 100.0,
          income: const IncomeConfig(
            amount: 50000.0,
            frequency: PayFrequency.salary,
          ),
          deductions: [
            const Deduction(
              id: 'd1',
              name: 'Total Deduct',
              amount: 100.0, // 100% deduction
              type: DeductionType.preTax,
              amountType: DeductionAmountType.percentage,
              frequency: PayFrequency.salary,
            ),
          ],
          tax: const TaxConfig(salesTaxRate: 0.0),
        );

        expect(resOverDeduct.netHourlyPay, equals(0.0));
        expect(resOverDeduct.totalWorkingHours.isInfinite, isTrue);
        expect(
          resOverDeduct.formattedNaturalString,
          equals('Infinity (Unaffordable)'),
        );
      },
    );

    test(
      '2.5 Extreme price boundaries (\$0.01 micro price vs \$1,000,000,000 extreme price)',
      () {
        final resMicro = CalculationService.calculateTimeCost(
          price: 0.01,
          income: const IncomeConfig(
            amount: 100.0,
            frequency: PayFrequency.hourly,
          ),
          deductions: [],
          tax: const TaxConfig(salesTaxRate: 0.0),
        );
        // 0.01 / 100 hr = 0.0001 hrs = 0.36 seconds -> 0 seconds rounded
        expect(resMicro.totalWorkingHours, closeTo(0.0001, 0.00001));

        final resExtreme = CalculationService.calculateTimeCost(
          price: 1000000000.0, // $1 Billion
          income: const IncomeConfig(
            amount: 50.0,
            frequency: PayFrequency.hourly,
          ), // $104,000/yr = $50/hr
          deductions: [],
          tax: const TaxConfig(salesTaxRate: 0.0),
        );
        // 1,000,000,000 / 50 = 20,000,000 working hours -> ~115,384 months
        expect(resExtreme.months, greaterThan(100000));
      },
    );

    test('2.6 Extreme tax rate boundaries (0% tax vs 100% tax)', () {
      final resZeroTax = CalculationService.calculateTimeCost(
        price: 100.0,
        income: const IncomeConfig(
          amount: 25.0,
          frequency: PayFrequency.hourly,
        ),
        deductions: [],
        tax: const TaxConfig(salesTaxRate: 0.0),
      );
      expect(resZeroTax.totalPriceWithTax, equals(100.0));

      final resFullTax = CalculationService.calculateTimeCost(
        price: 100.0,
        income: const IncomeConfig(
          amount: 25.0,
          frequency: PayFrequency.hourly,
        ),
        deductions: [],
        tax: const TaxConfig(salesTaxRate: 100.0),
      );
      expect(resFullTax.totalPriceWithTax, equals(200.0));
    });

    testWidgets(
      '2.7 UI Corner Case: Non-numeric text typed in Calculator price field',
      (tester) async {
        final persistence = await PersistenceService.init();
        await tester.pumpWidget(TimePriceApp(persistenceService: persistence));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('calculator_price_input')),
          r'abc!@#$',
        );
        await tester.pumpAndSettle();

        expect(find.text('0 seconds'), findsOneWidget);
      },
    );
  });
}
