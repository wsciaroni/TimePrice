import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:time_price/main.dart';
import 'package:time_price/services/persistence_service.dart';
import 'package:time_price/services/calculation_service.dart';
import 'package:time_price/models/income_config.dart';
import 'package:time_price/models/pay_frequency.dart';
import 'package:time_price/models/tax_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'time_price_onboarding_completed': true,
    });
  });

  group('Tier 1: Income Frequencies E2E Tests', () {
    test(
      '2.1 Hourly frequency time-cost calculation (\$25/hr -> \$100 item)',
      () {
        const income = IncomeConfig(
          amount: 25.0,
          frequency: PayFrequency.hourly,
        );
        final result = CalculationService.calculateTimeCost(
          price: 100.0,
          income: income,
          deductions: [],
          tax: const TaxConfig(salesTaxRate: 0.0),
        );

        expect(result.netHourlyPay, equals(25.0));
        expect(result.totalWorkingHours, equals(4.0));
        expect(result.hours, equals(4));
        expect(result.formattedNaturalString, equals('4 hours'));
      },
    );

    test(
      '2.2 Weekly frequency time-cost calculation (\$1,000/wk -> \$500 item)',
      () {
        const income = IncomeConfig(
          amount: 1000.0,
          frequency: PayFrequency.weekly,
        );
        final result = CalculationService.calculateTimeCost(
          price: 500.0,
          income: income,
          deductions: [],
          tax: const TaxConfig(salesTaxRate: 0.0),
        );

        expect(income.annualIncome, equals(52000.0));
        expect(result.netHourlyPay, equals(25.0));
        expect(result.totalWorkingHours, equals(20.0));
        expect(result.days, equals(2));
        expect(result.hours, equals(4));
        expect(result.formattedNaturalString, equals('2 days 4 hours'));
      },
    );

    test(
      '2.3 BiWeekly frequency time-cost calculation (\$2,000/biweekly -> \$200 item)',
      () {
        const income = IncomeConfig(
          amount: 2000.0,
          frequency: PayFrequency.biWeekly,
        );
        final result = CalculationService.calculateTimeCost(
          price: 200.0,
          income: income,
          deductions: [],
          tax: const TaxConfig(salesTaxRate: 0.0),
        );

        expect(income.annualIncome, equals(52000.0));
        expect(result.netHourlyPay, equals(25.0));
        expect(result.totalWorkingHours, equals(8.0));
        expect(result.days, equals(1));
        expect(result.hours, equals(0));
        expect(result.formattedNaturalString, equals('1 day'));
      },
    );

    test(
      '2.4 Salary frequency time-cost calculation (\$104,000/yr -> \$1,000 item)',
      () {
        const income = IncomeConfig(
          amount: 104000.0,
          frequency: PayFrequency.salary,
        );
        final result = CalculationService.calculateTimeCost(
          price: 1000.0,
          income: income,
          deductions: [],
          tax: const TaxConfig(salesTaxRate: 0.0),
        );

        expect(income.annualIncome, equals(104000.0));
        expect(result.netHourlyPay, equals(50.0));
        expect(result.totalWorkingHours, equals(20.0));
        expect(result.days, equals(2));
        expect(result.hours, equals(4));
        expect(result.formattedNaturalString, equals('2 days 4 hours'));
      },
    );

    testWidgets(
      '2.5 UI test: Frequency switching in Settings updates Calculator display',
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
        expect(
          find.byKey(const Key('time_cost_natural_string')),
          findsOneWidget,
        );

        // Open settings
        await tester.tap(find.byKey(const Key('settings_button')));
        await tester.pumpAndSettle();

        // Change pay amount to 1000 and frequency to Weekly
        await tester.enterText(
          find.byKey(const Key('settings_pay_amount_input')),
          '1000',
        );
        await tester.tap(
          find.byKey(const Key('settings_pay_frequency_dropdown')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Weekly').last);
        await tester.pumpAndSettle();

        // Save settings
        await tester.ensureVisible(find.byKey(const Key('save_settings_btn')));
        await tester.tap(find.byKey(const Key('save_settings_btn')));
        await tester.pumpAndSettle();

        // Back on calculator screen: $1000/wk = $25/hr. $100 item -> 4 hours
        expect(find.text('TimePrice Calculator'), findsOneWidget);
        expect(find.text('4 hours'), findsOneWidget);
      },
    );
  });
}
