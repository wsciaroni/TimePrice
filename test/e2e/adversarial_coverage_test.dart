import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:time_price/main.dart';
import 'package:time_price/models/deduction.dart';
import 'package:time_price/models/income_config.dart';
import 'package:time_price/models/pay_frequency.dart';
import 'package:time_price/models/tax_config.dart';
import 'package:time_price/providers/app_state_provider.dart';
import 'package:time_price/services/calculation_service.dart';
import 'package:time_price/services/persistence_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Tier 5: Adversarial Coverage Hardening E2E Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({
        'time_price_onboarding_completed': true,
      });
    });

    // ------------------------------------------------------------------------
    // 1. Extreme Boundary Inputs
    // ------------------------------------------------------------------------
    group('1. Extreme Boundary Inputs', () {
      test('1.1 Price near double.maxFinite handling without crash or infinite loops', () {
        const extremePrice = 1e300;
        final res = CalculationService.calculateTimeCost(
          price: extremePrice,
          income: const IncomeConfig(amount: 50.0, frequency: PayFrequency.hourly),
          deductions: [],
          tax: const TaxConfig(salesTaxRate: 10.0),
        );

        expect(res.totalPriceWithTax, closeTo(1.1e300, 1e285));
        expect(res.netHourlyPay, equals(50.0));
        expect(res.totalWorkingHours.isFinite, isTrue);
        expect(res.months, greaterThan(0));
      });

      test('1.2 Sub-cent precision price (\$0.00001) and sub-second natural string result', () {
        final res = CalculationService.calculateTimeCost(
          price: 0.00001,
          income: const IncomeConfig(amount: 100.0, frequency: PayFrequency.hourly),
          deductions: [],
          tax: const TaxConfig(salesTaxRate: 0.0),
        );

        expect(res.totalPriceWithTax, equals(0.00001));
        expect(res.totalWorkingHours, lessThan(0.001));
        expect(res.formattedNaturalString, equals('0 seconds'));
      });

      test('1.3 Negative price inputs in CalculationService and AppStateProvider', () {
        final res = CalculationService.calculateTimeCost(
          price: -500.0,
          income: const IncomeConfig(amount: 25.0, frequency: PayFrequency.hourly),
          deductions: [],
          tax: const TaxConfig(salesTaxRate: 5.0),
        );

        expect(res.totalPriceWithTax, equals(0.0));
        expect(res.totalWorkingHours, equals(0.0));
        expect(res.formattedNaturalString, equals('0 seconds'));

        final provider = AppStateProvider();
        provider.updatePrice(-100.0);
        expect(provider.priceInput, equals(0.0));
        expect(provider.result.totalPriceWithTax, equals(0.0));
      });

      test('1.4 Extremely large income (\$1e12) and price calculations', () {
        final res = CalculationService.calculateTimeCost(
          price: 1000000.0,
          income: const IncomeConfig(amount: 1e12, frequency: PayFrequency.salary),
          deductions: [],
          tax: const TaxConfig(salesTaxRate: 0.0),
        );

        expect(res.netHourlyPay, closeTo(480769230.769, 1.0));
        expect(res.totalWorkingHours, lessThan(1.0));
        expect(res.formattedNaturalString, contains('seconds'));
      });

      test('1.5 Zero wage (\$0.00/hr) with positive price yields Infinity (Unaffordable)', () {
        final res = CalculationService.calculateTimeCost(
          price: 1.0,
          income: const IncomeConfig(amount: 0.0, frequency: PayFrequency.hourly),
          deductions: [],
          tax: const TaxConfig(salesTaxRate: 0.0),
        );

        expect(res.netHourlyPay, equals(0.0));
        expect(res.totalWorkingHours.isInfinite, isTrue);
        expect(res.formattedNaturalString, equals('Infinity (Unaffordable)'));
      });

      testWidgets('1.6 Invalid non-numeric price string input in UI text fields defaults to 0.0', (tester) async {
        final prefs = await SharedPreferences.getInstance();
        final persistence = PersistenceService(prefs);
        await tester.pumpWidget(
          MaterialApp(
            home: TimePriceApp(persistenceService: persistence),
          ),
        );
        await tester.pumpAndSettle();

        // Enter invalid text in calculator price field
        final priceFinder = find.byKey(const Key('calculator_price_input'));
        expect(priceFinder, findsOneWidget);

        await tester.enterText(priceFinder, 'abc-xyz!@#');
        await tester.pumpAndSettle();

        expect(find.text('0 seconds'), findsOneWidget);

        // Enter valid number afterwards
        await tester.enterText(priceFinder, '25.00');
        await tester.pumpAndSettle();
        expect(find.text('1 hour'), findsOneWidget);
      });
    });

    // ------------------------------------------------------------------------
    // 2. Complex Multi-Deduction Scenarios
    // ------------------------------------------------------------------------
    group('2. Complex Multi-Deduction Scenarios', () {
      test('2.1 Multi-tiered deductions mixing pre-tax %, flat pre-tax, post-tax %, flat post-tax across frequencies', () {
        final deductions = [
          const Deduction(
            id: 'd1',
            name: '401k',
            amount: 5.0,
            type: DeductionType.preTax,
            amountType: DeductionAmountType.percentage,
            frequency: PayFrequency.salary,
          ),
          const Deduction(
            id: 'd2',
            name: 'HSA',
            amount: 200.0,
            type: DeductionType.preTax,
            amountType: DeductionAmountType.flat,
            frequency: PayFrequency.monthly,
          ),
          const Deduction(
            id: 'd3',
            name: 'State Tax',
            amount: 10.0,
            type: DeductionType.postTax,
            amountType: DeductionAmountType.percentage,
            frequency: PayFrequency.salary,
          ),
          const Deduction(
            id: 'd4',
            name: 'Union Dues',
            amount: 50.0,
            type: DeductionType.postTax,
            amountType: DeductionAmountType.flat,
            frequency: PayFrequency.weekly,
          ),
        ];

        final res = CalculationService.calculateTimeCost(
          price: 40.0961538,
          income: const IncomeConfig(amount: 104000.0, frequency: PayFrequency.salary),
          deductions: deductions,
          tax: const TaxConfig(salesTaxRate: 0.0),
        );

        expect(res.netHourlyPay, closeTo(40.0961538, 0.001));
        expect(res.totalWorkingHours, closeTo(1.0, 0.001));
        expect(res.formattedNaturalString, equals('1 hour'));
      });

      test('2.2 Over-deduction exceeding 100% of income clamps net hourly pay to 0.0 and yields Infinity (Unaffordable)', () {
        final deductions = [
          const Deduction(
            id: 'd1',
            name: 'Huge Pre-tax',
            amount: 70.0,
            type: DeductionType.preTax,
            amountType: DeductionAmountType.percentage,
            frequency: PayFrequency.salary,
          ),
          const Deduction(
            id: 'd2',
            name: 'Huge Post-tax',
            amount: 50.0,
            type: DeductionType.postTax,
            amountType: DeductionAmountType.percentage,
            frequency: PayFrequency.salary,
          ),
        ];

        final res = CalculationService.calculateTimeCost(
          price: 100.0,
          income: const IncomeConfig(amount: 50000.0, frequency: PayFrequency.salary),
          deductions: deductions,
          tax: const TaxConfig(salesTaxRate: 0.0),
        );

        expect(res.netHourlyPay, equals(0.0));
        expect(res.totalWorkingHours.isInfinite, isTrue);
        expect(res.formattedNaturalString, equals('Infinity (Unaffordable)'));
      });

      test('2.3 Zero income with active deductions returns 0.0 net pay cleanly', () {
        final deductions = [
          const Deduction(
            id: 'd1',
            name: 'Insurance',
            amount: 100.0,
            type: DeductionType.preTax,
            amountType: DeductionAmountType.flat,
            frequency: PayFrequency.monthly,
          ),
        ];

        final res = CalculationService.calculateTimeCost(
          price: 50.0,
          income: const IncomeConfig(amount: 0.0, frequency: PayFrequency.hourly),
          deductions: deductions,
          tax: const TaxConfig(salesTaxRate: 0.0),
        );

        expect(res.netHourlyPay, equals(0.0));
        expect(res.formattedNaturalString, equals('Infinity (Unaffordable)'));
      });

      test('2.4 Deductions with 0 amount or negative amount produce zero annual deduction', () {
        const dZero = Deduction(
          id: 'd0',
          name: 'Zero',
          amount: 0.0,
          type: DeductionType.preTax,
          amountType: DeductionAmountType.flat,
          frequency: PayFrequency.hourly,
        );
        const dNeg = Deduction(
          id: 'dn',
          name: 'Negative',
          amount: -50.0,
          type: DeductionType.postTax,
          amountType: DeductionAmountType.percentage,
          frequency: PayFrequency.monthly,
        );

        expect(dZero.calculateAnnualAmount(50000.0), equals(0.0));
        expect(dNeg.calculateAnnualAmount(50000.0), equals(0.0));
      });

      test('2.5 Multiple deductions added, updated, and removed dynamically in AppStateProvider', () async {
        final provider = AppStateProvider();
        const d1 = Deduction(
          id: '1',
          name: 'Health',
          amount: 100.0,
          type: DeductionType.preTax,
          amountType: DeductionAmountType.flat,
          frequency: PayFrequency.monthly,
        );
        const d1Update = Deduction(
          id: '1',
          name: 'Health Insurance',
          amount: 150.0,
          type: DeductionType.preTax,
          amountType: DeductionAmountType.flat,
          frequency: PayFrequency.monthly,
        );

        await provider.addDeduction(d1);
        expect(provider.deductions.length, equals(1));
        expect(provider.deductions.first.name, equals('Health'));

        await provider.updateDeduction(d1Update);
        expect(provider.deductions.length, equals(1));
        expect(provider.deductions.first.name, equals('Health Insurance'));

        await provider.removeDeduction('1');
        expect(provider.deductions.isEmpty, isTrue);
      });
    });

    // ------------------------------------------------------------------------
    // 3. Rapid UI Interactions
    // ------------------------------------------------------------------------
    group('3. Rapid UI Interactions', () {
      testWidgets('3.1 Rapid repeated taps on Settings button and Back without crash or memory leak', (tester) async {
        final prefs = await SharedPreferences.getInstance();
        final persistence = PersistenceService(prefs);
        await tester.pumpWidget(
          MaterialApp(
            home: TimePriceApp(persistenceService: persistence),
          ),
        );
        await tester.pumpAndSettle();

        // Perform rapid push & pop
        for (int i = 0; i < 5; i++) {
          final settingsBtn = find.byKey(const Key('settings_button'));
          expect(settingsBtn, findsOneWidget);
          await tester.tap(settingsBtn);
          await tester.pumpAndSettle();

          expect(find.text('Settings'), findsOneWidget);

          // Tap back icon or save button
          final saveBtn = find.byKey(const Key('save_settings_btn'));
          await tester.tap(saveBtn);
          await tester.pumpAndSettle();

          expect(find.text('TimePrice Calculator'), findsOneWidget);
        }
      });

      testWidgets('3.2 Rapid text entry updates on calculator price field with fast repaints', (tester) async {
        final prefs = await SharedPreferences.getInstance();
        final persistence = PersistenceService(prefs);
        await tester.pumpWidget(
          MaterialApp(
            home: TimePriceApp(persistenceService: persistence),
          ),
        );
        await tester.pumpAndSettle();

        final priceFinder = find.byKey(const Key('calculator_price_input'));
        final inputs = ['1', '12', '125', '1250', '1250.5', '1250.50', '0', ''];

        for (final val in inputs) {
          await tester.enterText(priceFinder, val);
          await tester.pump(); // Fast pump without settle
        }
        await tester.pumpAndSettle();

        expect(find.text('0 seconds'), findsOneWidget);
      });

      testWidgets('3.3 Rapid deduction additions and deletions in SettingsScreen', (tester) async {
        final prefs = await SharedPreferences.getInstance();
        final persistence = PersistenceService(prefs);
        await tester.pumpWidget(
          MaterialApp(
            home: TimePriceApp(persistenceService: persistence),
          ),
        );
        await tester.pumpAndSettle();

        // Open settings
        await tester.tap(find.byKey(const Key('settings_button')));
        await tester.pumpAndSettle();

        // Add 3 deductions rapidly
        for (int i = 1; i <= 3; i++) {
          final nameInput = find.byKey(const Key('settings_deduction_name_input'));
          final amtInput = find.byKey(const Key('settings_deduction_amount_input'));
          final addBtn = find.byKey(const Key('settings_add_deduction_btn'));

          await tester.ensureVisible(nameInput);
          await tester.enterText(nameInput, 'Deduction $i');

          await tester.ensureVisible(amtInput);
          await tester.enterText(amtInput, '${i * 10}');

          await tester.ensureVisible(addBtn);
          await tester.tap(addBtn, warnIfMissed: false);
          await tester.pumpAndSettle();
        }

        expect(find.text('Deduction 1'), findsOneWidget);
        expect(find.text('Deduction 2'), findsOneWidget);
        expect(find.text('Deduction 3'), findsOneWidget);

        // Delete deductions
        for (int i = 0; i < 3; i++) {
          final deleteBtn = find.byIcon(Icons.delete).first;
          await tester.ensureVisible(deleteBtn);
          await tester.tap(deleteBtn);
          await tester.pumpAndSettle();
        }

        expect(find.text('No deductions configured.'), findsOneWidget);
      });
    });

    // ------------------------------------------------------------------------
    // 4. Persistence Corruption Recovery
    // ------------------------------------------------------------------------
    group('4. Persistence Corruption Recovery', () {
      test('4.1 Malformed JSON string in SharedPreferences for IncomeConfig falls back to default (\$25/hr hourly)', () async {
        SharedPreferences.setMockInitialValues({
          'time_price_income': '{corrupted_json_syntax: true, amount: }',
          'time_price_onboarding_completed': true,
        });
        final prefs = await SharedPreferences.getInstance();
        final service = PersistenceService(prefs);

        final income = service.loadIncomeConfig();
        expect(income.amount, equals(25.0));
        expect(income.frequency, equals(PayFrequency.hourly));
      });

      test('4.2 Corrupt JSON array in SharedPreferences for Deductions falls back to empty list', () async {
        SharedPreferences.setMockInitialValues({
          'time_price_deductions': 'NOT_A_JSON_LIST',
          'time_price_onboarding_completed': true,
        });
        final prefs = await SharedPreferences.getInstance();
        final service = PersistenceService(prefs);

        final deductions = service.loadDeductions();
        expect(deductions, isEmpty);
      });

      test('4.3 Corrupt JSON string in SharedPreferences for TaxConfig falls back to default (0.0% sales tax)', () async {
        SharedPreferences.setMockInitialValues({
          'time_price_tax': '{"salesTaxRate": "INVALID_STRING_INSTEAD_OF_NUM"}',
          'time_price_onboarding_completed': true,
        });
        final prefs = await SharedPreferences.getInstance();
        final service = PersistenceService(prefs);

        final tax = service.loadTaxConfig();
        expect(tax.salesTaxRate, equals(0.0));
      });

      test('4.4 Invalid type values in SharedPreferences keys handle gracefully without crash', () async {
        SharedPreferences.setMockInitialValues({
          'time_price_income': 12345, // int instead of String JSON
          'time_price_deductions': true, // bool instead of String JSON
          'time_price_tax': 99.99, // double instead of String JSON
        });
        final prefs = await SharedPreferences.getInstance();
        final service = PersistenceService(prefs);

        final income = service.loadIncomeConfig();
        final deductions = service.loadDeductions();
        final tax = service.loadTaxConfig();

        expect(income.amount, equals(25.0));
        expect(deductions, isEmpty);
        expect(tax.salesTaxRate, equals(0.0));
      });

      testWidgets('4.5 Full recovery: App initialized with corrupt state displays cleanly and saves new settings', (tester) async {
        SharedPreferences.setMockInitialValues({
          'time_price_income': 'CORRUPT_JSON_DATA',
          'time_price_deductions': 'CORRUPT_LIST_DATA',
          'time_price_tax': 'CORRUPT_TAX_DATA',
          'time_price_onboarding_completed': true,
        });
        final prefs = await SharedPreferences.getInstance();
        final persistence = PersistenceService(prefs);

        final provider = AppStateProvider(persistenceService: persistence);
        await provider.initialize();

        expect(provider.incomeConfig.amount, equals(25.0));
        expect(provider.deductions, isEmpty);
        expect(provider.taxConfig.salesTaxRate, equals(0.0));

        await tester.pumpWidget(
          MaterialApp(
            home: TimePriceApp(persistenceService: persistence),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('TimePrice Calculator'), findsOneWidget);

        // Update settings to verify recovery save
        await tester.tap(find.byKey(const Key('settings_button')));
        await tester.pumpAndSettle();

        await tester.enterText(find.byKey(const Key('settings_pay_amount_input')), '40.0');
        await tester.tap(find.byKey(const Key('save_settings_btn')));
        await tester.pumpAndSettle();

        expect(persistence.loadIncomeConfig().amount, equals(40.0));
      });
    });

    // ------------------------------------------------------------------------
    // 5. Edge-Case Tax Rates
    // ------------------------------------------------------------------------
    group('5. Edge-Case Tax Rates', () {
      test('5.1 0.0% sales tax rate calculations', () {
        final res = CalculationService.calculateTimeCost(
          price: 100.0,
          income: const IncomeConfig(amount: 25.0, frequency: PayFrequency.hourly),
          deductions: [],
          tax: const TaxConfig(salesTaxRate: 0.0),
        );

        expect(res.totalPriceWithTax, equals(100.0));
        expect(res.totalWorkingHours, equals(4.0));
        expect(res.formattedNaturalString, equals('4 hours'));
      });

      test('5.2 Negative sales tax rate (-25.0%) is clamped to 0.0%', () {
        final res = CalculationService.calculateTimeCost(
          price: 100.0,
          income: const IncomeConfig(amount: 25.0, frequency: PayFrequency.hourly),
          deductions: [],
          tax: const TaxConfig(salesTaxRate: -25.0),
        );

        expect(res.totalPriceWithTax, equals(100.0));
        expect(res.totalWorkingHours, equals(4.0));
      });

      test('5.3 High sales tax rates (e.g. 500.0%, 999.99%) calculate total price with tax correctly', () {
        final res500 = CalculationService.calculateTimeCost(
          price: 50.0,
          income: const IncomeConfig(amount: 50.0, frequency: PayFrequency.hourly),
          deductions: [],
          tax: const TaxConfig(salesTaxRate: 500.0),
        );
        // Price = 50 * (1 + 5.0) = 300
        expect(res500.totalPriceWithTax, equals(300.0));
        expect(res500.totalWorkingHours, equals(6.0));

        final res999 = CalculationService.calculateTimeCost(
          price: 10.0,
          income: const IncomeConfig(amount: 10.0, frequency: PayFrequency.hourly),
          deductions: [],
          tax: const TaxConfig(salesTaxRate: 999.99),
        );
        // Price = 10 * (1 + 9.9999) = 109.999
        expect(res999.totalPriceWithTax, closeTo(109.999, 0.001));
      });

      test('5.4 Fractional tax rates with high decimal precision (e.g. 8.875%, 7.25%)', () {
        final res = CalculationService.calculateTimeCost(
          price: 100.0,
          income: const IncomeConfig(amount: 20.0, frequency: PayFrequency.hourly),
          deductions: [],
          tax: const TaxConfig(salesTaxRate: 8.875),
        );

        expect(res.totalPriceWithTax, closeTo(108.875, 0.0001));
        expect(res.totalWorkingHours, closeTo(5.44375, 0.0001));
      });

      testWidgets('5.5 Invalid text input in Settings tax rate input field falls back safely', (tester) async {
        final prefs = await SharedPreferences.getInstance();
        final persistence = PersistenceService(prefs);
        await tester.pumpWidget(
          MaterialApp(
            home: TimePriceApp(persistenceService: persistence),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('settings_button')));
        await tester.pumpAndSettle();

        final taxInput = find.byKey(const Key('settings_sales_tax_input'));
        await tester.enterText(taxInput, 'INVALID_TAX');
        await tester.tap(find.byKey(const Key('save_settings_btn')));
        await tester.pumpAndSettle();

        expect(persistence.loadTaxConfig().salesTaxRate, equals(0.0));
      });
    });
  });
}
