import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:time_price/main.dart';
import 'package:time_price/services/persistence_service.dart';
import 'package:time_price/models/pay_frequency.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'time_price_onboarding_completed': true,
    });
  });

  group('Tier 1: Settings Update E2E Tests', () {
    testWidgets('6.1 Updating base pay amount in Settings', (tester) async {
      final persistence = await PersistenceService.init();
      await tester.pumpWidget(TimePriceApp(persistenceService: persistence));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('settings_button')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('settings_pay_amount_input')),
        '50.0',
      );
      await tester.ensureVisible(find.byKey(const Key('save_settings_btn')));
      await tester.tap(find.byKey(const Key('save_settings_btn')));
      await tester.pumpAndSettle();

      expect(persistence.loadIncomeConfig().amount, equals(50.0));
    });

    testWidgets('6.2 Switch pay frequency in Settings', (tester) async {
      final persistence = await PersistenceService.init();
      await tester.pumpWidget(TimePriceApp(persistenceService: persistence));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('settings_button')));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('settings_pay_frequency_dropdown')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salary').last);
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('save_settings_btn')));
      await tester.tap(find.byKey(const Key('save_settings_btn')));
      await tester.pumpAndSettle();

      expect(
        persistence.loadIncomeConfig().frequency,
        equals(PayFrequency.salary),
      );
    });

    testWidgets('6.3 Adding a new deduction in Settings', (tester) async {
      final persistence = await PersistenceService.init();
      await tester.pumpWidget(TimePriceApp(persistenceService: persistence));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('settings_button')));
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.byKey(const Key('settings_deduction_name_input')),
      );
      await tester.enterText(
        find.byKey(const Key('settings_deduction_name_input')),
        'Pension',
      );
      await tester.enterText(
        find.byKey(const Key('settings_deduction_amount_input')),
        '100',
      );
      await tester.ensureVisible(
        find.byKey(const Key('settings_add_deduction_btn')),
      );
      await tester.tap(find.byKey(const Key('settings_add_deduction_btn')));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('save_settings_btn')));
      await tester.tap(find.byKey(const Key('save_settings_btn')));
      await tester.pumpAndSettle();

      expect(persistence.loadDeductions().length, equals(1));
      expect(persistence.loadDeductions().first.name, equals('Pension'));
    });

    testWidgets('6.4 Removing an existing deduction in Settings', (
      tester,
    ) async {
      final persistence = await PersistenceService.init();
      await tester.pumpWidget(TimePriceApp(persistenceService: persistence));
      await tester.pumpAndSettle();

      // Add deduction first
      await tester.tap(find.byKey(const Key('settings_button')));
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.byKey(const Key('settings_deduction_name_input')),
      );
      await tester.enterText(
        find.byKey(const Key('settings_deduction_name_input')),
        'Temp Dues',
      );
      await tester.enterText(
        find.byKey(const Key('settings_deduction_amount_input')),
        '15',
      );
      await tester.ensureVisible(
        find.byKey(const Key('settings_add_deduction_btn')),
      );
      await tester.tap(find.byKey(const Key('settings_add_deduction_btn')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Temp Dues'), findsOneWidget);

      // Delete deduction
      final deleteBtn = find.byIcon(Icons.delete).first;
      await tester.ensureVisible(deleteBtn);
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();
      expect(find.textContaining('Temp Dues'), findsNothing);

      await tester.ensureVisible(find.byKey(const Key('save_settings_btn')));
      await tester.tap(find.byKey(const Key('save_settings_btn')));
      await tester.pumpAndSettle();

      expect(persistence.loadDeductions(), isEmpty);
    });

    testWidgets('6.5 Updating sales tax rate in Settings', (tester) async {
      final persistence = await PersistenceService.init();
      await tester.pumpWidget(TimePriceApp(persistenceService: persistence));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('settings_button')));
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.byKey(const Key('settings_sales_tax_input')),
      );
      await tester.enterText(
        find.byKey(const Key('settings_sales_tax_input')),
        '8.25',
      );
      await tester.ensureVisible(find.byKey(const Key('save_settings_btn')));
      await tester.tap(find.byKey(const Key('save_settings_btn')));
      await tester.pumpAndSettle();

      expect(persistence.loadTaxConfig().salesTaxRate, equals(8.25));
    });

    testWidgets(
      '6.6 Reset Setup & Onboarding button resets app to Onboarding Wizard',
      (tester) async {
        final persistence = await PersistenceService.init();
        await tester.pumpWidget(TimePriceApp(persistenceService: persistence));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('settings_button')));
        await tester.pumpAndSettle();

        await tester.ensureVisible(
          find.byKey(const Key('reset_onboarding_btn')),
        );
        await tester.tap(find.byKey(const Key('reset_onboarding_btn')));
        await tester.pumpAndSettle();

        expect(find.text('1. Income Setup'), findsOneWidget);
        expect(persistence.isOnboardingCompleted(), isFalse);
      },
    );
  });
}
