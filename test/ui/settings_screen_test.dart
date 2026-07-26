import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:time_price/models/pay_frequency.dart';
import 'package:time_price/providers/app_state_provider.dart';
import 'package:time_price/services/persistence_service.dart';
import 'package:time_price/ui/settings/settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'time_price_onboarding_completed': true,
    });
  });

  Widget buildTestableWidget(AppStateProvider provider) {
    return ChangeNotifierProvider<AppStateProvider>.value(
      value: provider,
      child: const MaterialApp(
        home: SettingsScreen(),
      ),
    );
  }

  group('SettingsScreen Widget Tests', () {
    testWidgets('1. SettingsScreen renders initial provider values', (tester) async {
      final persistence = await PersistenceService.init();
      final provider = AppStateProvider(persistenceService: persistence);

      await tester.pumpWidget(buildTestableWidget(provider));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.byKey(const Key('settings_pay_amount_input')), findsOneWidget);
      expect(find.byKey(const Key('settings_pay_frequency_dropdown')), findsOneWidget);
      expect(find.byKey(const Key('settings_sales_tax_input')), findsOneWidget);
      expect(find.byKey(const Key('save_settings_btn')), findsOneWidget);
    });

    testWidgets('2. Update income amount and pay frequency in settings', (tester) async {
      final persistence = await PersistenceService.init();
      final provider = AppStateProvider(persistenceService: persistence);

      await tester.pumpWidget(buildTestableWidget(provider));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('settings_pay_amount_input')),
        '65.0',
      );

      await tester.tap(find.byKey(const Key('settings_pay_frequency_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Monthly').last);
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('save_settings_btn')));
      await tester.tap(find.byKey(const Key('save_settings_btn')));
      await tester.pumpAndSettle();

      expect(provider.incomeConfig.amount, equals(65.0));
      expect(provider.incomeConfig.frequency, equals(PayFrequency.monthly));
    });

    testWidgets('3. Update sales tax rate in settings', (tester) async {
      final persistence = await PersistenceService.init();
      final provider = AppStateProvider(persistenceService: persistence);

      await tester.pumpWidget(buildTestableWidget(provider));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('settings_sales_tax_input')));
      await tester.enterText(
        find.byKey(const Key('settings_sales_tax_input')),
        '7.25',
      );

      await tester.ensureVisible(find.byKey(const Key('save_settings_btn')));
      await tester.tap(find.byKey(const Key('save_settings_btn')));
      await tester.pumpAndSettle();

      expect(provider.taxConfig.salesTaxRate, equals(7.25));
    });

    testWidgets('4. Add and delete deduction in settings', (tester) async {
      final persistence = await PersistenceService.init();
      final provider = AppStateProvider(persistenceService: persistence);

      await tester.pumpWidget(buildTestableWidget(provider));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('settings_deduction_name_input')));
      await tester.enterText(
        find.byKey(const Key('settings_deduction_name_input')),
        'Insurance',
      );
      await tester.enterText(
        find.byKey(const Key('settings_deduction_amount_input')),
        '80',
      );

      await tester.ensureVisible(find.byKey(const Key('settings_add_deduction_btn')));
      await tester.tap(find.byKey(const Key('settings_add_deduction_btn')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Insurance'), findsOneWidget);
      expect(provider.deductions.length, equals(1));

      // Delete deduction
      final deleteBtn = find.byIcon(Icons.delete).first;
      await tester.ensureVisible(deleteBtn);
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      expect(find.textContaining('Insurance'), findsNothing);
      expect(provider.deductions, isEmpty);
    });

    testWidgets('5. Reset onboarding button resets state', (tester) async {
      final persistence = await PersistenceService.init();
      final provider = AppStateProvider(persistenceService: persistence);
      await provider.completeOnboarding();

      await tester.pumpWidget(buildTestableWidget(provider));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('reset_onboarding_btn')));
      await tester.tap(find.byKey(const Key('reset_onboarding_btn')));
      await tester.pumpAndSettle();

      expect(provider.isOnboardingCompleted, isFalse);
    });
  });
}
