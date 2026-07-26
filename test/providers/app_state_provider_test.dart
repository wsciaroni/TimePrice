import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:time_price/models/deduction.dart';
import 'package:time_price/models/income_config.dart';
import 'package:time_price/models/pay_frequency.dart';
import 'package:time_price/models/tax_config.dart';
import 'package:time_price/providers/app_state_provider.dart';
import 'package:time_price/services/persistence_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AppStateProvider Unit Tests', () {
    test('1. Initial state defaults without persistence service', () {
      final provider = AppStateProvider();

      expect(provider.incomeConfig.amount, equals(25.0));
      expect(provider.incomeConfig.frequency, equals(PayFrequency.hourly));
      expect(provider.deductions, isEmpty);
      expect(provider.taxConfig.salesTaxRate, equals(0.0));
      expect(provider.price, equals(0.0));
      expect(provider.priceInput, equals(0.0));
      expect(provider.isOnboardingCompleted, isFalse);
      expect(provider.result.formattedNaturalString, equals('0 seconds'));
      expect(provider.timeCostResult.formattedNaturalString, equals('0 seconds'));
    });

    test('2. Initial state loads from PersistenceService', () async {
      SharedPreferences.setMockInitialValues({
        'time_price_income': '{"amount": 50.0, "frequency": "salary"}',
        'time_price_tax': '{"salesTaxRate": 7.0}',
        'time_price_onboarding_completed': true,
      });

      final persistence = await PersistenceService.init();
      final provider = AppStateProvider(persistenceService: persistence);

      expect(provider.incomeConfig.amount, equals(50.0));
      expect(provider.incomeConfig.frequency, equals(PayFrequency.salary));
      expect(provider.taxConfig.salesTaxRate, equals(7.0));
      expect(provider.isOnboardingCompleted, isTrue);
    });

    test('3. initialize() reloads state from PersistenceService', () async {
      final persistence = await PersistenceService.init();
      final provider = AppStateProvider(persistenceService: persistence);

      await persistence.saveIncomeConfig(
        const IncomeConfig(amount: 100.0, frequency: PayFrequency.weekly),
      );

      var notified = false;
      provider.addListener(() {
        notified = true;
      });

      await provider.initialize();
      expect(notified, isTrue);
      expect(provider.incomeConfig.amount, equals(100.0));
    });

    test('4. updateIncome & updateIncomeConfig update state and persist', () async {
      final persistence = await PersistenceService.init();
      final provider = AppStateProvider(persistenceService: persistence);

      var notified = false;
      provider.addListener(() => notified = true);

      await provider.updateIncome(
        const IncomeConfig(amount: 40.0, frequency: PayFrequency.hourly),
      );

      expect(notified, isTrue);
      expect(provider.incomeConfig.amount, equals(40.0));
      expect(persistence.loadIncomeConfig().amount, equals(40.0));

      notified = false;
      await provider.updateIncomeConfig(
        const IncomeConfig(amount: 50.0, frequency: PayFrequency.hourly),
      );
      expect(notified, isTrue);
      expect(provider.incomeConfig.amount, equals(50.0));
    });

    test('5. Deduction management: add, update, delete, setDeductions', () async {
      final persistence = await PersistenceService.init();
      final provider = AppStateProvider(persistenceService: persistence);

      const d1 = Deduction(
        id: 'd1',
        name: 'Health',
        amount: 50.0,
        type: DeductionType.preTax,
        amountType: DeductionAmountType.flat,
        frequency: PayFrequency.monthly,
      );

      // Add deduction
      await provider.addDeduction(d1);
      expect(provider.deductions.length, equals(1));
      expect(provider.deductions.first.name, equals('Health'));
      expect(persistence.loadDeductions().length, equals(1));

      // Update deduction existing
      const d1Updated = Deduction(
        id: 'd1',
        name: 'Health Premium',
        amount: 60.0,
        type: DeductionType.preTax,
        amountType: DeductionAmountType.flat,
        frequency: PayFrequency.monthly,
      );
      await provider.updateDeduction(d1Updated);
      expect(provider.deductions.length, equals(1));
      expect(provider.deductions.first.name, equals('Health Premium'));

      // Update deduction new
      const d2 = Deduction(
        id: 'd2',
        name: 'Dental',
        amount: 20.0,
        type: DeductionType.postTax,
        amountType: DeductionAmountType.flat,
        frequency: PayFrequency.monthly,
      );
      await provider.updateDeduction(d2);
      expect(provider.deductions.length, equals(2));

      // Delete deduction
      await provider.deleteDeduction('d1');
      expect(provider.deductions.length, equals(1));
      expect(provider.deductions.first.id, equals('d2'));

      // Remove deduction
      await provider.removeDeduction('d2');
      expect(provider.deductions, isEmpty);

      // Set deductions bulk
      await provider.setDeductions([d1, d2]);
      expect(provider.deductions.length, equals(2));
    });

    test('6. TaxConfig updating', () async {
      final persistence = await PersistenceService.init();
      final provider = AppStateProvider(persistenceService: persistence);

      await provider.updateTaxConfig(const TaxConfig(salesTaxRate: 6.5));
      expect(provider.taxConfig.salesTaxRate, equals(6.5));
      expect(persistence.loadTaxConfig().salesTaxRate, equals(6.5));
    });

    test('7. Price input updating and clamping negative prices', () {
      final provider = AppStateProvider();

      provider.updatePriceInput(100.0);
      expect(provider.price, equals(100.0));
      expect(provider.priceInput, equals(100.0));
      expect(provider.result.totalPriceWithTax, equals(100.0));

      provider.updatePrice(-20.0);
      expect(provider.price, equals(0.0));
      expect(provider.result.totalPriceWithTax, equals(0.0));
    });

    test('8. Onboarding completion & reset', () async {
      final persistence = await PersistenceService.init();
      final provider = AppStateProvider(persistenceService: persistence);

      await provider.completeOnboarding();
      expect(provider.isOnboardingCompleted, isTrue);
      expect(persistence.isOnboardingCompleted(), isTrue);

      await provider.setOnboardingCompleted(false);
      expect(provider.isOnboardingCompleted, isFalse);

      await provider.completeOnboarding();
      expect(provider.isOnboardingCompleted, isTrue);

      await provider.resetOnboarding();
      expect(provider.isOnboardingCompleted, isFalse);
      expect(provider.incomeConfig.amount, equals(25.0));
      expect(provider.deductions, isEmpty);
      expect(provider.taxConfig.salesTaxRate, equals(0.0));
      expect(provider.price, equals(0.0));
    });

    test('9. TimeCostResult recalculates dynamically on price / config changes', () async {
      final provider = AppStateProvider();

      // Default: $25/hr
      provider.updatePrice(25.0);
      expect(provider.timeCostResult.formattedNaturalString, equals('1 hour'));

      // Change income to $50/hr
      await provider.updateIncomeConfig(
        const IncomeConfig(amount: 50.0, frequency: PayFrequency.hourly),
      );
      expect(provider.timeCostResult.formattedNaturalString, equals('30 minutes'));
    });
  });
}
