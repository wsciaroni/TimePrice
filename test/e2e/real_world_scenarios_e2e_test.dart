import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:time_price/main.dart';
import 'package:time_price/services/persistence_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  group('Tier 4: Real-World Application Scenarios E2E Tests', () {
    testWidgets(
      'Scenario 1: First-Time User Onboarding & Daily Coffee Purchase Evaluation',
      (tester) async {
        SharedPreferences.setMockInitialValues({}); // Fresh state
        final persistence = await PersistenceService.init();
        await tester.pumpWidget(TimePriceApp(persistenceService: persistence));
        await tester.pumpAndSettle();

        // Step 1: Base Pay $20/hr
        expect(find.text('1. Income Setup'), findsOneWidget);
        await tester.enterText(
          find.byKey(const Key('onboarding_pay_amount_input')),
          '20.0',
        );
        await tapNextStep(tester);

        // Step 2: Skip deductions
        expect(find.text('2. Payroll Deductions (Optional)'), findsOneWidget);
        await tapNextStep(tester);

        // Step 3: Set Sales Tax 5.0%
        expect(find.text('3. Sales Tax Setup'), findsOneWidget);
        await tester.enterText(
          find.byKey(const Key('onboarding_sales_tax_input')),
          '5.0',
        );
        await tapFinishSetup(tester);

        // Main Calculator Screen: Calculate $4.50 Coffee
        expect(find.text('TimePrice Calculator'), findsOneWidget);
        await tester.enterText(
          find.byKey(const Key('calculator_price_input')),
          '4.50',
        );
        await tester.pumpAndSettle();

        // Price w/ tax = $4.725 ($4.73). Net wage = $20/hr. Working hours = 0.23625 = 14 mins 11 secs
        expect(find.text('\$4.73'), findsOneWidget);
        expect(find.text('14 minutes 11 seconds'), findsOneWidget);
      },
    );

    testWidgets(
      'Scenario 2: Salaried Employee Major Purchase & Tax Rate Adjustments',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'time_price_onboarding_completed': true,
        });
        final persistence = await PersistenceService.init();
        await tester.pumpWidget(TimePriceApp(persistenceService: persistence));
        await tester.pumpAndSettle();

        // Configure Salary ($75,000) & 5% 401k pre-tax in Settings
        await tester.tap(find.byKey(const Key('settings_button')));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('settings_pay_amount_input')),
          '75000',
        );
        await tester.tap(
          find.byKey(const Key('settings_pay_frequency_dropdown')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Salary').last);
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('settings_deduction_name_input')),
          '401k',
        );
        await tester.enterText(
          find.byKey(const Key('settings_deduction_amount_input')),
          '5',
        );
        await tester.tap(
          find.byKey(const Key('settings_add_deduction_btn')),
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const Key('save_settings_btn')),
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();

        // Enter Car Price $25,000 on Calculator screen
        await tester.enterText(
          find.byKey(const Key('calculator_price_input')),
          '25000',
        );
        await tester.pumpAndSettle();

        // Gross = 75,000. 401k = 3,750 -> Net annual = 71,250. Net hourly = 34.2548
        // 25,000 / 34.2548 = 729.8245 working hours = 4 months 4 days 4 hours 49 minutes 28 seconds
        expect(find.textContaining('4 months'), findsOneWidget);

        // Now open Settings and update sales tax rate to 7%
        await tester.tap(find.byKey(const Key('settings_button')));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('settings_sales_tax_input')),
          '7',
        );
        await tester.tap(
          find.byKey(const Key('save_settings_btn')),
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();

        // Price w/ tax is now $26,750
        expect(find.text('\$26750.00'), findsOneWidget);
      },
    );

    testWidgets(
      'Scenario 3: Gig Worker Weekly Pay & Persistent State Session Reboot',
      (tester) async {
        final mockPrefs = <String, Object>{
          'time_price_onboarding_completed': true,
          'time_price_income': '{"amount":1200.0,"frequency":"weekly"}',
          'time_price_tax': '{"salesTaxRate":8.0}',
        };
        SharedPreferences.setMockInitialValues(mockPrefs);

        final persistence = await PersistenceService.init();
        await tester.pumpWidget(TimePriceApp(persistenceService: persistence));
        await tester.pumpAndSettle();

        // Weekly $1,200 = $62,400/yr = $30/hr. 8% tax.
        // Laptop $1,000 -> w/ tax $1,080 / 30 = 36 hours = 4 days 4 hours
        await tester.enterText(
          find.byKey(const Key('calculator_price_input')),
          '1000',
        );
        await tester.pumpAndSettle();

        expect(find.text('\$1080.00'), findsOneWidget);
        expect(find.text('4 days 4 hours'), findsOneWidget);
      },
    );

    testWidgets('Scenario 4: Setup Reset and Re-configuration Workflow', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'time_price_onboarding_completed': true,
      });
      final persistence = await PersistenceService.init();
      await tester.pumpWidget(TimePriceApp(persistenceService: persistence));
      await tester.pumpAndSettle();

      // Open Settings and tap Reset Setup
      await tester.tap(find.byKey(const Key('settings_button')));
      await tester.pumpAndSettle();

      await tester.dragUntilVisible(
        find.byKey(const Key('reset_onboarding_btn')),
        find.byType(SingleChildScrollView),
        const Offset(0, -200),
      );
      await tester.tap(find.byKey(const Key('reset_onboarding_btn')));
      await tester.pumpAndSettle();

      // Verify routed to Onboarding Wizard
      expect(find.text('1. Income Setup'), findsOneWidget);

      // Complete wizard with $50/hr
      await tester.enterText(
        find.byKey(const Key('onboarding_pay_amount_input')),
        '50',
      );
      await tapNextStep(tester);
      await tapNextStep(tester);
      await tapFinishSetup(tester);

      // Enter price $100 -> 2 hours
      await tester.enterText(
        find.byKey(const Key('calculator_price_input')),
        '100',
      );
      await tester.pumpAndSettle();

      expect(find.text('2 hours'), findsOneWidget);
    });

    testWidgets(
      'Scenario 5: Complete End-to-End User Journey Across All Screens',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final persistence = await PersistenceService.init();
        await tester.pumpWidget(TimePriceApp(persistenceService: persistence));
        await tester.pumpAndSettle();

        // 1. Onboarding Wizard
        await tester.enterText(
          find.byKey(const Key('onboarding_pay_amount_input')),
          '40',
        );
        await tapNextStep(tester);

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
        await tapNextStep(tester);

        await tester.enterText(
          find.byKey(const Key('onboarding_sales_tax_input')),
          '6',
        );
        await tapFinishSetup(tester);

        // 2. Calculator Screen
        expect(find.text('TimePrice Calculator'), findsOneWidget);
        await tester.enterText(
          find.byKey(const Key('calculator_price_input')),
          '500',
        );
        await tester.pumpAndSettle();

        // 3. Settings Screen Edits
        await tester.tap(find.byKey(const Key('settings_button')));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('settings_pay_amount_input')),
          '60',
        );
        await tester.tap(
          find.byKey(const Key('save_settings_btn')),
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();

        // 4. Return to Calculator Screen and verify recalculation
        expect(find.text('TimePrice Calculator'), findsOneWidget);
        expect(
          find.byKey(const Key('time_cost_natural_string')),
          findsOneWidget,
        );
      },
    );
  });
}
