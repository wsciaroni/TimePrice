import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:time_price/main.dart';
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

  group('Tier 1: Calculator & Time-Cost Breakdown E2E Tests', () {
    test(
      r'5.1 Micro-price item calculation ($0.50 at $25/hr -> 1 minute 12 seconds)',
      () {
        final result = CalculationService.calculateTimeCost(
          price: 0.50,
          income: const IncomeConfig(
            amount: 25.0,
            frequency: PayFrequency.hourly,
          ),
          deductions: [],
          tax: const TaxConfig(salesTaxRate: 0.0),
        );

        expect(result.minutes, equals(1));
        expect(result.seconds, equals(12));
        expect(result.formattedNaturalString, equals('1 minute 12 seconds'));
      },
    );

    test(r'5.2 Medium-price item calculation ($49.99 at $25/hr)', () {
      final result = CalculationService.calculateTimeCost(
        price: 49.99,
        income: const IncomeConfig(
          amount: 25.0,
          frequency: PayFrequency.hourly,
        ),
        deductions: [],
        tax: const TaxConfig(salesTaxRate: 0.0),
      );

      expect(result.hours, equals(1));
      expect(result.minutes, equals(59));
      expect(result.seconds, equals(59));
    });

    test(
      r'5.3 High-price item calculation ($10,000 at $25/hr -> 400 hrs = 2 months 1 week 2 days)',
      () {
        final result = CalculationService.calculateTimeCost(
          price: 10000.0,
          income: const IncomeConfig(
            amount: 25.0,
            frequency: PayFrequency.hourly,
          ),
          deductions: [],
          tax: const TaxConfig(salesTaxRate: 0.0),
        );

        expect(result.months, equals(2));
        expect(result.weeks, equals(1));
        expect(result.days, equals(1));
        expect(result.hours, equals(5));
        expect(result.minutes, equals(20));
        expect(
          result.formattedNaturalString,
          equals('2 months 1 week 1 day 5 hours 20 minutes'),
        );
      },
    );

    test('5.4 Zero price item returns 0 seconds', () {
      final result = CalculationService.calculateTimeCost(
        price: 0.0,
        income: const IncomeConfig(
          amount: 25.0,
          frequency: PayFrequency.hourly,
        ),
        deductions: [],
        tax: const TaxConfig(salesTaxRate: 0.0),
      );

      expect(result.totalWorkingHours, equals(0.0));
      expect(result.formattedNaturalString, equals('0 seconds'));
    });

    testWidgets(
      '5.5 Interactive typing in Calculator TextField updates TimeCostDisplay dynamically',
      (tester) async {
        final persistence = await PersistenceService.init();
        await tester.pumpWidget(TimePriceApp(persistenceService: persistence));
        await tester.pumpAndSettle();

        final input = find.byKey(const Key('calculator_price_input'));

        // Type 25
        await tester.enterText(input, '25');
        await tester.pumpAndSettle();
        expect(find.text('1 hour'), findsOneWidget);

        // Type 50
        await tester.enterText(input, '50');
        await tester.pumpAndSettle();
        expect(find.text('2 hours'), findsOneWidget);

        // Clear input
        await tester.enterText(input, '');
        await tester.pumpAndSettle();
        expect(find.text('0 seconds'), findsOneWidget);
      },
    );
  });
}
