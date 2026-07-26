import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:time_price/providers/app_state_provider.dart';
import 'package:time_price/services/persistence_service.dart';
import 'package:time_price/ui/onboarding/onboarding_wizard_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildTestableWidget(AppStateProvider provider) {
    return ChangeNotifierProvider<AppStateProvider>.value(
      value: provider,
      child: const MaterialApp(
        home: OnboardingWizardScreen(),
      ),
    );
  }

  group('OnboardingWizardScreen Widget Tests', () {
    testWidgets('1. Renders Step 1 Income Setup correctly', (tester) async {
      final persistence = await PersistenceService.init();
      final provider = AppStateProvider(persistenceService: persistence);

      await tester.pumpWidget(buildTestableWidget(provider));
      await tester.pumpAndSettle();

      expect(find.text('Welcome to TimePrice Setup'), findsOneWidget);
      expect(find.text('1. Income Setup'), findsOneWidget);
      expect(find.byKey(const Key('onboarding_pay_amount_input')), findsOneWidget);
      expect(find.byKey(const Key('onboarding_pay_frequency_dropdown')), findsOneWidget);
      expect(find.byKey(const Key('next_step_btn')), findsOneWidget);
    });

    testWidgets('2. Navigates step by step and enters income data', (tester) async {
      final persistence = await PersistenceService.init();
      final provider = AppStateProvider(persistenceService: persistence);

      await tester.pumpWidget(buildTestableWidget(provider));
      await tester.pumpAndSettle();

      // Enter pay amount
      await tester.enterText(
        find.byKey(const Key('onboarding_pay_amount_input')),
        '45.0',
      );

      // Select frequency
      await tester.tap(find.byKey(const Key('onboarding_pay_frequency_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hourly').last);
      await tester.pumpAndSettle();

      // Tap Next
      await tester.tap(find.byKey(const Key('next_step_btn')));
      await tester.pumpAndSettle();

      // Step 2 is active
      expect(find.text('2. Payroll Deductions (Optional)'), findsOneWidget);
    });

    testWidgets('3. Step 2 adding and deleting deductions', (tester) async {
      final persistence = await PersistenceService.init();
      final provider = AppStateProvider(persistenceService: persistence);

      await tester.pumpWidget(buildTestableWidget(provider));
      await tester.pumpAndSettle();

      // Go to step 2
      await tester.tap(find.byKey(const Key('next_step_btn')));
      await tester.pumpAndSettle();

      // Fill deduction fields
      await tester.enterText(
        find.byKey(const Key('onboarding_deduction_name_input')),
        '401k Savings',
      );
      await tester.enterText(
        find.byKey(const Key('onboarding_deduction_amount_input')),
        '50',
      );

      // Add deduction
      await tester.tap(find.byKey(const Key('onboarding_add_deduction_btn')));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(ListTile, '401k Savings'), findsOneWidget);

      // Delete deduction
      await tester.tap(find.byIcon(Icons.delete).first);
      await tester.pumpAndSettle();

      expect(find.widgetWithText(ListTile, '401k Savings'), findsNothing);
      expect(find.text('No deductions added.'), findsOneWidget);
    });

    testWidgets('4. Step 3 completing setup persists data & sets onboarding completed', (tester) async {
      final persistence = await PersistenceService.init();
      final provider = AppStateProvider(persistenceService: persistence);

      await tester.pumpWidget(buildTestableWidget(provider));
      await tester.pumpAndSettle();

      // Step 1 -> Step 2
      await tester.enterText(
        find.byKey(const Key('onboarding_pay_amount_input')),
        '50.0',
      );
      await tester.tap(find.byKey(const Key('next_step_btn')));
      await tester.pumpAndSettle();

      // Step 2 -> Step 3
      await tester.tap(find.byKey(const Key('next_step_btn')));
      await tester.pumpAndSettle();

      // Step 3
      expect(find.text('3. Sales Tax Setup'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('onboarding_sales_tax_input')),
        '8.5',
      );

      // Finish
      await tester.tap(find.byKey(const Key('finish_onboarding_btn')));
      await tester.pumpAndSettle();

      expect(provider.isOnboardingCompleted, isTrue);
      expect(provider.incomeConfig.amount, equals(50.0));
      expect(provider.taxConfig.salesTaxRate, equals(8.5));
    });

    testWidgets('5. Step backward navigation retains state', (tester) async {
      final persistence = await PersistenceService.init();
      final provider = AppStateProvider(persistenceService: persistence);

      await tester.pumpWidget(buildTestableWidget(provider));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('onboarding_pay_amount_input')),
        '33.33',
      );
      await tester.tap(find.byKey(const Key('next_step_btn')));
      await tester.pumpAndSettle();

      // Back to step 1
      await tester.tap(find.text('Back').first);
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextField, '33.33'), findsOneWidget);
    });
  });
}
