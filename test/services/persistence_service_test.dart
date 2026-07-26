import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:time_price/models/deduction.dart';
import 'package:time_price/models/income_config.dart';
import 'package:time_price/models/pay_frequency.dart';
import 'package:time_price/models/tax_config.dart';
import 'package:time_price/services/persistence_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('PersistenceService Unit Tests', () {
    test('1. Default values when SharedPreferences is empty', () async {
      final persistence = await PersistenceService.init();

      final income = persistence.loadIncomeConfig();
      expect(income.amount, equals(25.0));
      expect(income.frequency, equals(PayFrequency.hourly));

      final deductions = persistence.loadDeductions();
      expect(deductions, isEmpty);

      final tax = persistence.loadTaxConfig();
      expect(tax.salesTaxRate, equals(0.0));

      expect(persistence.isOnboardingCompleted(), isFalse);
    });

    test('2. Save and load IncomeConfig', () async {
      final persistence = await PersistenceService.init();
      const config = IncomeConfig(
        amount: 75000.0,
        frequency: PayFrequency.salary,
      );

      final saved = await persistence.saveIncomeConfig(config);
      expect(saved, isTrue);

      final loaded = persistence.loadIncomeConfig();
      expect(loaded.amount, equals(75000.0));
      expect(loaded.frequency, equals(PayFrequency.salary));
    });

    test('3. Save and load Deductions list', () async {
      final persistence = await PersistenceService.init();
      final list = [
        const Deduction(
          id: '1',
          name: '401k',
          amount: 5.0,
          type: DeductionType.preTax,
          amountType: DeductionAmountType.percentage,
          frequency: PayFrequency.hourly,
        ),
        const Deduction(
          id: '2',
          name: 'Health',
          amount: 150.0,
          type: DeductionType.postTax,
          amountType: DeductionAmountType.flat,
          frequency: PayFrequency.monthly,
        ),
      ];

      final saved = await persistence.saveDeductions(list);
      expect(saved, isTrue);

      final loaded = persistence.loadDeductions();
      expect(loaded.length, equals(2));
      expect(loaded[0].id, equals('1'));
      expect(loaded[0].name, equals('401k'));
      expect(loaded[0].amount, equals(5.0));
      expect(loaded[0].type, equals(DeductionType.preTax));
      expect(loaded[0].amountType, equals(DeductionAmountType.percentage));

      expect(loaded[1].id, equals('2'));
      expect(loaded[1].name, equals('Health'));
      expect(loaded[1].amount, equals(150.0));
      expect(loaded[1].type, equals(DeductionType.postTax));
      expect(loaded[1].amountType, equals(DeductionAmountType.flat));
    });

    test('4. Save and load TaxConfig', () async {
      final persistence = await PersistenceService.init();
      const tax = TaxConfig(salesTaxRate: 8.875);

      final saved = await persistence.saveTaxConfig(tax);
      expect(saved, isTrue);

      final loaded = persistence.loadTaxConfig();
      expect(loaded.salesTaxRate, equals(8.875));
    });

    test('5. Set and get isOnboardingCompleted', () async {
      final persistence = await PersistenceService.init();

      expect(persistence.isOnboardingCompleted(), isFalse);

      final setRes = await persistence.setOnboardingCompleted(true);
      expect(setRes, isTrue);
      expect(persistence.isOnboardingCompleted(), isTrue);

      await persistence.setOnboardingCompleted(false);
      expect(persistence.isOnboardingCompleted(), isFalse);
    });

    test('6. resetAll clears stored values to defaults', () async {
      final persistence = await PersistenceService.init();

      await persistence.saveIncomeConfig(
        const IncomeConfig(amount: 100.0, frequency: PayFrequency.weekly),
      );
      await persistence.saveTaxConfig(const TaxConfig(salesTaxRate: 10.0));
      await persistence.setOnboardingCompleted(true);

      expect(persistence.isOnboardingCompleted(), isTrue);

      final resetRes = await persistence.resetAll();
      expect(resetRes, isTrue);

      expect(persistence.loadIncomeConfig().amount, equals(25.0));
      expect(persistence.loadTaxConfig().salesTaxRate, equals(0.0));
      expect(persistence.isOnboardingCompleted(), isFalse);
      expect(persistence.loadDeductions(), isEmpty);
    });

    test('7. Graceful fallback on corrupt JSON strings in SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'time_price_income': 'corrupted_json_string',
        'time_price_deductions': 'invalid_json_list',
        'time_price_tax': '{"salesTaxRate": "not_a_number"}',
      });

      final persistence = await PersistenceService.init();

      final income = persistence.loadIncomeConfig();
      expect(income.amount, equals(25.0));

      final deductions = persistence.loadDeductions();
      expect(deductions, isEmpty);

      final tax = persistence.loadTaxConfig();
      expect(tax.salesTaxRate, equals(0.0));
    });
  });
}
