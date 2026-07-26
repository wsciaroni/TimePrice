import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:time_price/models/time_cost_result.dart';
import 'package:time_price/providers/app_state_provider.dart';
import 'package:time_price/services/persistence_service.dart';
import 'package:time_price/ui/calculator/calculator_screen.dart';
import 'package:time_price/ui/calculator/time_cost_display.dart';

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
        home: CalculatorScreen(),
      ),
    );
  }

  group('CalculatorScreen & TimeCostDisplay Widget Tests', () {
    testWidgets('1. CalculatorScreen initial rendering', (tester) async {
      final persistence = await PersistenceService.init();
      final provider = AppStateProvider(persistenceService: persistence);

      await tester.pumpWidget(buildTestableWidget(provider));
      await tester.pumpAndSettle();

      expect(find.text('TimePrice Calculator'), findsOneWidget);
      expect(find.byKey(const Key('calculator_price_input')), findsOneWidget);
      expect(find.byKey(const Key('settings_button')), findsOneWidget);
      expect(find.byKey(const Key('time_cost_natural_string')), findsOneWidget);
      expect(find.text('0 seconds'), findsOneWidget);
    });

    testWidgets('2. Interactive typing in price input updates result real-time', (tester) async {
      final persistence = await PersistenceService.init();
      final provider = AppStateProvider(persistenceService: persistence);

      await tester.pumpWidget(buildTestableWidget(provider));
      await tester.pumpAndSettle();

      final input = find.byKey(const Key('calculator_price_input'));

      // Enter 25.0
      await tester.enterText(input, '25.0');
      await tester.pumpAndSettle();
      expect(find.text('1 hour'), findsOneWidget);

      // Enter 100.0
      await tester.enterText(input, '100.0');
      await tester.pumpAndSettle();
      expect(find.text('4 hours'), findsOneWidget);

      // Clear input
      await tester.enterText(input, '');
      await tester.pumpAndSettle();
      expect(find.text('0 seconds'), findsOneWidget);
    });

    testWidgets('3. Navigation to SettingsScreen via settings_button', (tester) async {
      final persistence = await PersistenceService.init();
      final provider = AppStateProvider(persistenceService: persistence);

      await tester.pumpWidget(buildTestableWidget(provider));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('settings_button')));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.byKey(const Key('save_settings_btn')), findsOneWidget);
    });

    testWidgets('4. TimeCostDisplay renders breakdown card values correctly', (tester) async {
      const result = TimeCostResult(
        totalPriceWithTax: 108.0,
        netHourlyPay: 20.0,
        totalWorkingHours: 5.4,
        months: 0,
        weeks: 0,
        days: 0,
        hours: 5,
        minutes: 24,
        seconds: 0,
        formattedNaturalString: '5 hours 24 minutes',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TimeCostDisplay(result: result),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('time_cost_natural_string')), findsOneWidget);
      expect(find.text('5 hours 24 minutes'), findsOneWidget);
      expect(find.text('\$20.00/hr'), findsOneWidget);
      expect(find.text('\$108.00'), findsOneWidget);
      expect(find.text('5.40'), findsOneWidget);
    });

    testWidgets('5. TimeCostDisplay renders Infinite working hours when net pay is zero', (tester) async {
      const result = TimeCostResult(
        totalPriceWithTax: 100.0,
        netHourlyPay: 0.0,
        totalWorkingHours: double.infinity,
        months: 0,
        weeks: 0,
        days: 0,
        hours: 0,
        minutes: 0,
        seconds: 0,
        formattedNaturalString: 'Infinity (Unaffordable)',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TimeCostDisplay(result: result),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Infinity (Unaffordable)'), findsOneWidget);
      expect(find.text('Infinite'), findsOneWidget);
      expect(find.text('\$0.00/hr'), findsOneWidget);
    });
  });
}
