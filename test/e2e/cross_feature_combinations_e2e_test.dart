import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:time_price/main.dart';
import 'package:time_price/services/persistence_service.dart';
import 'package:time_price/services/calculation_service.dart';
import 'package:time_price/models/income_config.dart';
import 'package:time_price/models/pay_frequency.dart';
import 'package:time_price/models/deduction.dart';
import 'package:time_price/models/tax_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'time_price_onboarding_completed': true,
    });
  });

  group('Tier 3: Cross-Feature Combinations E2E Tests', () {
    test(
      '3.1 Salary (\$78,000) + BiWeekly pre-tax deduction (\$150) + 6.5% sales tax',
      () {
        const income = IncomeConfig(
          amount: 78000.0,
          frequency: PayFrequency.salary,
        );
        final deductions = [
          const Deduction(
            id: '1',
            name: 'PreTax 401k',
            amount: 150.0,
            type: DeductionType.preTax,
            amountType: DeductionAmountType.flat,
            frequency: PayFrequency.biWeekly,
          ),
        ];
        const tax = TaxConfig(salesTaxRate: 6.5);

        final result = CalculationService.calculateTimeCost(
          price: 500.0,
          income: income,
          deductions: deductions,
          tax: tax,
        );

        // Gross = 78000. Pre-tax = 150 * 26 = 3900. Net annual = 74100. Net hourly = 35.625
        // Price with tax = 500 * 1.065 = 532.50
        // Hours = 532.50 / 35.625 = 14.947368 hrs = 1 day (8 hrs) + 6 hrs 56 mins 51 secs
        expect(result.netHourlyPay, equals(35.625));
        expect(result.totalPriceWithTax, equals(532.50));
        expect(result.totalWorkingHours, closeTo(14.9473, 0.001));
        expect(result.days, equals(1));
        expect(result.hours, equals(6));
        expect(result.minutes, equals(56));
      },
    );

    test(
      '3.2 Hourly (\$30/hr) + 10% pre-tax 401k + \$25 post-tax dues + 8% sales tax',
      () {
        const income = IncomeConfig(
          amount: 30.0,
          frequency: PayFrequency.hourly,
        );
        final deductions = [
          const Deduction(
            id: 'd1',
            name: '401k',
            amount: 10.0,
            type: DeductionType.preTax,
            amountType: DeductionAmountType.percentage,
            frequency: PayFrequency.salary,
          ),
          const Deduction(
            id: 'd2',
            name: 'Union Dues',
            amount: 25.0,
            type: DeductionType.postTax,
            amountType: DeductionAmountType.flat,
            frequency: PayFrequency.weekly,
          ),
        ];
        const tax = TaxConfig(salesTaxRate: 8.0);

        final result = CalculationService.calculateTimeCost(
          price: 250.0,
          income: income,
          deductions: deductions,
          tax: tax,
        );

        // Gross = 62,400. Pre-tax 10% = 6240 -> Taxable = 56,160.
        // Post-tax = 25 * 52 = 1300 -> Net annual = 54,860. Net hourly = 26.375
        // Price w/ tax = 250 * 1.08 = 270.0
        // Hours = 270 / 26.375 = 10.236963 hrs = 1 day (8 hrs) + 2 hrs 14 mins
        expect(result.netHourlyPay, equals(26.375));
        expect(result.totalPriceWithTax, equals(270.0));
        expect(result.totalWorkingHours, closeTo(10.2369, 0.001));
        expect(result.days, equals(1));
        expect(result.hours, equals(2));
      },
    );

    test(
      '3.3 Weekly pay (\$800/wk) + multiple pre & post tax deductions + 0% tax',
      () {
        const income = IncomeConfig(
          amount: 800.0,
          frequency: PayFrequency.weekly,
        );
        final deductions = [
          const Deduction(
            id: '1',
            name: 'Health Insurance',
            amount: 50.0,
            type: DeductionType.preTax,
            amountType: DeductionAmountType.flat,
            frequency: PayFrequency.weekly,
          ),
          const Deduction(
            id: '2',
            name: 'Parking Fee',
            amount: 20.0,
            type: DeductionType.postTax,
            amountType: DeductionAmountType.flat,
            frequency: PayFrequency.weekly,
          ),
        ];

        final result = CalculationService.calculateTimeCost(
          price: 365.0,
          income: income,
          deductions: deductions,
          tax: const TaxConfig(salesTaxRate: 0.0),
        );

        // Gross annual = 800 * 52 = 41600 ($20/hr).
        // Pre-tax = 50 * 52 = 2600. Taxable = 39000.
        // Post-tax = 20 * 52 = 1040. Net annual = 37960. Net hourly = 18.25
        // Hours = 365 / 18.25 = 20.0 hrs = 2 days 4 hours
        expect(result.netHourlyPay, equals(18.25));
        expect(result.totalWorkingHours, equals(20.0));
        expect(result.days, equals(2));
        expect(result.hours, equals(4));
      },
    );

    testWidgets(
      '3.4 UI Pipeline: Full configuration change in Settings reflects instantly on Calculator display',
      (tester) async {
        final persistence = await PersistenceService.init();
        await tester.pumpWidget(TimePriceApp(persistenceService: persistence));
        await tester.pumpAndSettle();

        // Enter price $200
        await tester.enterText(
          find.byKey(const Key('calculator_price_input')),
          '200',
        );
        await tester.pumpAndSettle();
        expect(
          find.text('1 day'),
          findsOneWidget,
        ); // Default $25/hr -> 8 hrs = 1 day

        // Open Settings and configure Salary ($104,000 = $50/hr), 10% Sales Tax, and $100/biweekly deduction
        await tester.tap(find.byKey(const Key('settings_button')));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('settings_pay_amount_input')),
          '104000',
        );
        await tester.tap(
          find.byKey(const Key('settings_pay_frequency_dropdown')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Salary').last);
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('settings_sales_tax_input')),
          '10',
        );

        await tester.enterText(
          find.byKey(const Key('settings_deduction_name_input')),
          'Healthcare',
        );
        await tester.enterText(
          find.byKey(const Key('settings_deduction_amount_input')),
          '5',
        );
        await tester.ensureVisible(
          find.byKey(const Key('settings_add_deduction_btn')),
        );
        await tester.tap(find.byKey(const Key('settings_add_deduction_btn')));
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.byKey(const Key('save_settings_btn')));
        await tester.tap(find.byKey(const Key('save_settings_btn')));
        await tester.pumpAndSettle();

        // Return to Calculator Screen and verify updated display
        expect(find.text('TimePrice Calculator'), findsOneWidget);
        expect(find.text('\$220.00'), findsOneWidget);
        expect(
          find.byKey(const Key('time_cost_natural_string')),
          findsOneWidget,
        );
      },
    );
  });
}
