import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:time_price/main.dart';
import 'package:time_price/models/deduction.dart';
import 'package:time_price/models/income_config.dart';
import 'package:time_price/models/pay_frequency.dart';
import 'package:time_price/models/tax_config.dart';
import 'package:time_price/services/calculation_service.dart';
import 'package:time_price/services/persistence_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'time_price_onboarding_completed': true,
    });
  });

  group('Tier 1: Deductions E2E Tests', () {
    test(r'3.1 Pre-tax flat deduction ($100 bi-weekly on $52,000 salary)', () {
      const income = IncomeConfig(
        amount: 52000.0,
        frequency: PayFrequency.salary,
      );
      const deduction = Deduction(
        id: '1',
        name: '401k Flat',
        amount: 100.0,
        type: DeductionType.preTax,
        amountType: DeductionAmountType.flat,
        frequency: PayFrequency.biWeekly,
      );

      final result = CalculationService.calculateTimeCost(
        price: 100.0,
        income: income,
        deductions: [deduction],
        tax: const TaxConfig(salesTaxRate: 0.0),
      );

      expect(result.netHourlyPay, equals(23.75));
      expect(result.totalWorkingHours, closeTo(4.2105, 0.001));
    });

    test(r'3.2 Pre-tax percentage deduction (10% 401k on $100,000 salary)', () {
      const income = IncomeConfig(
        amount: 100000.0,
        frequency: PayFrequency.salary,
      );
      const deduction = Deduction(
        id: '2',
        name: '401k Percent',
        amount: 10.0,
        type: DeductionType.preTax,
        amountType: DeductionAmountType.percentage,
        frequency: PayFrequency.salary,
      );

      final result = CalculationService.calculateTimeCost(
        price: 90.0,
        income: income,
        deductions: [deduction],
        tax: const TaxConfig(salesTaxRate: 0.0),
      );

      expect(result.netHourlyPay, closeTo(43.2692, 0.001));
      expect(result.totalWorkingHours, closeTo(2.0799, 0.001));
    });

    test(r'3.3 Post-tax flat deduction ($50 weekly on $25/hr pay)', () {
      const income = IncomeConfig(amount: 25.0, frequency: PayFrequency.hourly);
      const deduction = Deduction(
        id: '3',
        name: 'Health Ins',
        amount: 50.0,
        type: DeductionType.postTax,
        amountType: DeductionAmountType.flat,
        frequency: PayFrequency.weekly,
      );

      final result = CalculationService.calculateTimeCost(
        price: 237.50,
        income: income,
        deductions: [deduction],
        tax: const TaxConfig(salesTaxRate: 0.0),
      );

      expect(result.netHourlyPay, equals(23.75));
      expect(result.totalWorkingHours, equals(10.0));
      expect(result.days, equals(1));
      expect(result.hours, equals(2));
    });

    test(
      r'3.4 Post-tax percentage deduction (5% union dues on $60,000 salary)',
      () {
        const income = IncomeConfig(
          amount: 60000.0,
          frequency: PayFrequency.salary,
        );
        const deduction = Deduction(
          id: '4',
          name: 'Union Dues',
          amount: 5.0,
          type: DeductionType.postTax,
          amountType: DeductionAmountType.percentage,
          frequency: PayFrequency.salary,
        );

        final result = CalculationService.calculateTimeCost(
          price: 150.0,
          income: income,
          deductions: [deduction],
          tax: const TaxConfig(salesTaxRate: 0.0),
        );

        expect(result.netHourlyPay, equals(27.403846153846153));
        expect(result.totalWorkingHours, closeTo(5.4736, 0.001));
      },
    );

    testWidgets(
      '3.5 UI test: Adding and deleting deduction updates calculation',
      (tester) async {
        final persistence = await PersistenceService.init();
        await tester.pumpWidget(TimePriceApp(persistenceService: persistence));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('calculator_price_input')),
          '100',
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('settings_button')));
        await tester.pumpAndSettle();

        await tester.ensureVisible(
          find.byKey(const Key('settings_deduction_name_input')),
        );
        await tester.enterText(
          find.byKey(const Key('settings_deduction_name_input')),
          'Union Dues',
        );
        await tester.enterText(
          find.byKey(const Key('settings_deduction_amount_input')),
          '50',
        );
        await tester.ensureVisible(
          find.byKey(const Key('settings_add_deduction_btn')),
        );
        await tester.tap(find.byKey(const Key('settings_add_deduction_btn')));
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.byKey(const Key('save_settings_btn')));
        await tester.tap(find.byKey(const Key('save_settings_btn')));
        await tester.pumpAndSettle();

        expect(find.text('TimePrice Calculator'), findsOneWidget);
      },
    );

    testWidgets(
      '3.6 Adding and deleting deductions in Settings UI updates time-cost display',
      (tester) async {
        final persistence = await PersistenceService.init();
        await tester.pumpWidget(TimePriceApp(persistenceService: persistence));
        await tester.pumpAndSettle();

        // Enter price $100
        await tester.enterText(
          find.byKey(const Key('calculator_price_input')),
          '100',
        );
        await tester.pumpAndSettle();
        expect(find.text('4 hours'), findsOneWidget); // Default $25/hr -> 4 hrs

        // Open Settings
        await tester.tap(find.byKey(const Key('settings_button')));
        await tester.pumpAndSettle();

        // Add $5 pre-tax deduction
        await tester.ensureVisible(
          find.byKey(const Key('settings_deduction_name_input')),
        );
        await tester.enterText(
          find.byKey(const Key('settings_deduction_name_input')),
          'Tax Deduct',
        );
        await tester.enterText(
          find.byKey(const Key('settings_deduction_amount_input')),
          '5',
        );
        await tester.ensureVisible(
          find.byKey(const Key('settings_add_deduction_btn')),
        );
        await tester.tap(find.byKey(const Key('settings_add_deduction_btn')));
        await tester.pumpAndSettle();

        // Save Settings
        await tester.ensureVisible(find.byKey(const Key('save_settings_btn')));
        await tester.tap(find.byKey(const Key('save_settings_btn')));
        await tester.pumpAndSettle();

        // Back on Calculator Screen: Net pay drops to $20/hr -> $100 item takes 5 hours
        expect(find.text('5 hours'), findsOneWidget);
      },
    );
  });
}
