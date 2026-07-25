import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:time_price/main.dart';
import 'package:time_price/services/persistence_service.dart';
import 'package:time_price/models/pay_frequency.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> tapNextStep(WidgetTester tester) async {
    final finder = find.byKey(const Key('next_step_btn'));
    await tester.tap(finder.first, warnIfMissed: false);
    await tester.pumpAndSettle();
  }

  Future<void> tapFinishSetup(WidgetTester tester) async {
    final finder = find.byKey(const Key('finish_onboarding_btn'));
    await tester.tap(finder.first, warnIfMissed: false);
    await tester.pumpAndSettle();
  }

  group('Tier 1: Onboarding E2E Tests', () {
    testWidgets('1.1 Complete onboarding flow with default hourly wage', (
      tester,
    ) async {
      final persistence = await PersistenceService.init();
      await tester.pumpWidget(TimePriceApp(persistenceService: persistence));
      await tester.pumpAndSettle();

      // Step 1: Base Pay
      expect(find.text('1. Income Setup'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('onboarding_pay_amount_input')),
        '30.0',
      );
      await tapNextStep(tester);

      // Step 2: Deductions
      expect(find.text('2. Payroll Deductions (Optional)'), findsOneWidget);
      await tapNextStep(tester);

      // Step 3: Tax
      expect(find.text('3. Sales Tax Setup'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('onboarding_sales_tax_input')),
        '5.0',
      );
      await tapFinishSetup(tester);

      // Verify navigated to Calculator Screen
      expect(find.text('TimePrice Calculator'), findsOneWidget);
      expect(persistence.isOnboardingCompleted(), isTrue);
      expect(persistence.loadIncomeConfig().amount, equals(30.0));
      expect(persistence.loadTaxConfig().salesTaxRate, equals(5.0));
    });

    testWidgets('1.2 Onboarding flow with salary and pre-tax deduction', (
      tester,
    ) async {
      final persistence = await PersistenceService.init();
      await tester.pumpWidget(TimePriceApp(persistenceService: persistence));
      await tester.pumpAndSettle();

      // Step 1: Set Salary
      await tester.enterText(
        find.byKey(const Key('onboarding_pay_amount_input')),
        '104000',
      );
      await tester.tap(
        find.byKey(const Key('onboarding_pay_frequency_dropdown')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salary').last);
      await tester.pumpAndSettle();
      await tapNextStep(tester);

      // Step 2: Add Pre-Tax 401k Deduction
      await tester.enterText(
        find.byKey(const Key('onboarding_deduction_name_input')),
        '401k',
      );
      await tester.enterText(
        find.byKey(const Key('onboarding_deduction_amount_input')),
        '5.0',
      );
      await tester.tap(
        find.byKey(const Key('onboarding_add_deduction_btn')),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ListTile, '401k'), findsOneWidget);

      await tapNextStep(tester);

      // Step 3: Tax 7%
      await tester.enterText(
        find.byKey(const Key('onboarding_sales_tax_input')),
        '7.0',
      );
      await tapFinishSetup(tester);

      expect(find.text('TimePrice Calculator'), findsOneWidget);
      expect(
        persistence.loadIncomeConfig().frequency,
        equals(PayFrequency.salary),
      );
      expect(persistence.loadDeductions().length, equals(1));
      expect(persistence.loadDeductions().first.name, equals('401k'));
    });

    testWidgets(
      '1.3 Onboarding wizard handles empty and negative inputs safely',
      (tester) async {
        final persistence = await PersistenceService.init();
        await tester.pumpWidget(TimePriceApp(persistenceService: persistence));
        await tester.pumpAndSettle();

        // Step 1: Negative pay input
        await tester.enterText(
          find.byKey(const Key('onboarding_pay_amount_input')),
          '-500',
        );
        await tapNextStep(tester);

        // Step 2: Skip deductions
        await tapNextStep(tester);

        // Step 3: Negative tax input
        await tester.enterText(
          find.byKey(const Key('onboarding_sales_tax_input')),
          '-10',
        );
        await tapFinishSetup(tester);

        expect(find.text('TimePrice Calculator'), findsOneWidget);
        expect(persistence.loadIncomeConfig().amount, equals(0.0));
        expect(persistence.loadTaxConfig().salesTaxRate, equals(0.0));
      },
    );

    testWidgets(
      '1.4 Adding and deleting multiple deductions in onboarding step',
      (tester) async {
        final persistence = await PersistenceService.init();
        await tester.pumpWidget(TimePriceApp(persistenceService: persistence));
        await tester.pumpAndSettle();

        // Go to step 2
        await tapNextStep(tester);

        // Add Deduction A
        await tester.enterText(
          find.byKey(const Key('onboarding_deduction_name_input')),
          'Health',
        );
        await tester.enterText(
          find.byKey(const Key('onboarding_deduction_amount_input')),
          '50',
        );
        await tester.tap(
          find.byKey(const Key('onboarding_add_deduction_btn')),
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();

        // Add Deduction B
        await tester.enterText(
          find.byKey(const Key('onboarding_deduction_name_input')),
          'Gym',
        );
        await tester.enterText(
          find.byKey(const Key('onboarding_deduction_amount_input')),
          '20',
        );
        await tester.tap(
          find.byKey(const Key('onboarding_add_deduction_btn')),
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();

        expect(find.widgetWithText(ListTile, 'Health'), findsOneWidget);
        expect(find.widgetWithText(ListTile, 'Gym'), findsOneWidget);

        // Remove Gym
        await tester.tap(find.byIcon(Icons.delete).last, warnIfMissed: false);
        await tester.pumpAndSettle();

        expect(find.widgetWithText(ListTile, 'Gym'), findsNothing);
        expect(find.widgetWithText(ListTile, 'Health'), findsOneWidget);

        // Finish
        await tapNextStep(tester);
        await tapFinishSetup(tester);

        expect(persistence.loadDeductions().length, equals(1));
        expect(persistence.loadDeductions().first.name, equals('Health'));
      },
    );

    testWidgets(
      '1.5 Persistent state bypasses onboarding wizard on subsequent launch',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'time_price_onboarding_completed': true,
        });
        final persistence = await PersistenceService.init();
        await tester.pumpWidget(TimePriceApp(persistenceService: persistence));
        await tester.pumpAndSettle();

        expect(find.text('TimePrice Calculator'), findsOneWidget);
        expect(find.text('1. Income Setup'), findsNothing);
      },
    );

    testWidgets(
      '1.6 Step backward navigation retains filled data in onboarding wizard',
      (tester) async {
        final persistence = await PersistenceService.init();
        await tester.pumpWidget(TimePriceApp(persistenceService: persistence));
        await tester.pumpAndSettle();

        // Set Pay
        await tester.enterText(
          find.byKey(const Key('onboarding_pay_amount_input')),
          '42.50',
        );
        await tapNextStep(tester);

        // Go back to Step 1
        final backBtn = find.text('Back').first;
        await tester.tap(backBtn, warnIfMissed: false);
        await tester.pumpAndSettle();

        expect(find.widgetWithText(TextField, '42.50'), findsOneWidget);
      },
    );
  });
}
