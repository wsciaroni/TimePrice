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

  group('Tier 1: Sales Tax E2E Tests', () {
    test('4.1 0% sales tax rate does not alter item cost', () {
      final result = CalculationService.calculateTimeCost(
        price: 100.0,
        income: const IncomeConfig(
          amount: 25.0,
          frequency: PayFrequency.hourly,
        ),
        deductions: [],
        tax: const TaxConfig(salesTaxRate: 0.0),
      );

      expect(result.totalPriceWithTax, equals(100.0));
      expect(result.totalWorkingHours, equals(4.0));
    });

    test('4.2 Standard 7% sales tax rate correctly inflates item cost', () {
      final result = CalculationService.calculateTimeCost(
        price: 100.0,
        income: const IncomeConfig(
          amount: 25.0,
          frequency: PayFrequency.hourly,
        ),
        deductions: [],
        tax: const TaxConfig(salesTaxRate: 7.0),
      );

      expect(result.totalPriceWithTax, equals(107.0));
      expect(result.totalWorkingHours, equals(4.28));
    });

    test('4.3 High 25% sales tax rate calculation', () {
      final result = CalculationService.calculateTimeCost(
        price: 100.0,
        income: const IncomeConfig(
          amount: 25.0,
          frequency: PayFrequency.hourly,
        ),
        deductions: [],
        tax: const TaxConfig(salesTaxRate: 25.0),
      );

      expect(result.totalPriceWithTax, equals(125.0));
      expect(result.totalWorkingHours, equals(5.0));
      expect(result.hours, equals(5));
    });

    test('4.4 100% sales tax rate doubles effective item price', () {
      final result = CalculationService.calculateTimeCost(
        price: 100.0,
        income: const IncomeConfig(
          amount: 25.0,
          frequency: PayFrequency.hourly,
        ),
        deductions: [],
        tax: const TaxConfig(salesTaxRate: 100.0),
      );

      expect(result.totalPriceWithTax, equals(200.0));
      expect(result.totalWorkingHours, equals(8.0));
      expect(result.days, equals(1));
      expect(result.hours, equals(0));
    });

    test('4.5 Fractional sales tax rate (8.875% NYC tax)', () {
      final result = CalculationService.calculateTimeCost(
        price: 200.0,
        income: const IncomeConfig(
          amount: 25.0,
          frequency: PayFrequency.hourly,
        ),
        deductions: [],
        tax: const TaxConfig(salesTaxRate: 8.875),
      );

      expect(result.totalPriceWithTax, closeTo(217.75, 0.001));
      expect(result.totalWorkingHours, closeTo(8.71, 0.01));
    });

    testWidgets(
      '4.6 UI test: Sales tax update in Settings inflates price on Calculator screen',
      (tester) async {
        final persistence = await PersistenceService.init();
        await tester.pumpWidget(TimePriceApp(persistenceService: persistence));
        await tester.pumpAndSettle();

        // Price $100
        await tester.enterText(
          find.byKey(const Key('calculator_price_input')),
          '100',
        );
        await tester.pumpAndSettle();
        expect(find.text('\$100.00'), findsOneWidget);

        // Go to Settings and set sales tax to 10%
        await tester.tap(find.byKey(const Key('settings_button')));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('settings_sales_tax_input')),
          '10',
        );
        await tester.ensureVisible(find.byKey(const Key('save_settings_btn')));
        await tester.tap(find.byKey(const Key('save_settings_btn')));
        await tester.pumpAndSettle();

        // Total price on Calculator Screen should show $110.00
        expect(find.text('\$110.00'), findsOneWidget);
      },
    );
  });
}
