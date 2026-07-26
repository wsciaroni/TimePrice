import 'package:flutter/foundation.dart';
import 'package:time_price/models/deduction.dart';
import 'package:time_price/models/income_config.dart';
import 'package:time_price/models/pay_frequency.dart';
import 'package:time_price/models/tax_config.dart';
import 'package:time_price/models/time_cost_result.dart';
import 'package:time_price/services/calculation_service.dart';
import 'package:time_price/services/persistence_service.dart';

class AppStateProvider extends ChangeNotifier {
  AppStateProvider({PersistenceService? persistenceService})
      : _persistenceService = persistenceService {
    if (_persistenceService != null) {
      _loadSavedState();
    }
  }

  final PersistenceService? _persistenceService;

  IncomeConfig _incomeConfig = const IncomeConfig(
    amount: 25.0,
    frequency: PayFrequency.hourly,
  );
  List<Deduction> _deductions = [];
  TaxConfig _taxConfig = const TaxConfig(salesTaxRate: 0.0);
  double _price = 0.0;
  bool _isOnboardingCompleted = false;

  IncomeConfig get incomeConfig => _incomeConfig;
  List<Deduction> get deductions => List.unmodifiable(_deductions);
  TaxConfig get taxConfig => _taxConfig;
  double get priceInput => _price;
  double get price => _price;
  bool get isOnboardingCompleted => _isOnboardingCompleted;

  TimeCostResult get timeCostResult => CalculationService.calculateTimeCost(
        price: _price,
        income: _incomeConfig,
        deductions: _deductions,
        tax: _taxConfig,
      );

  TimeCostResult get result => timeCostResult;

  void _loadSavedState() {
    final ps = _persistenceService;
    if (ps == null) return;
    _incomeConfig = ps.loadIncomeConfig();
    _deductions = ps.loadDeductions();
    _taxConfig = ps.loadTaxConfig();
    _isOnboardingCompleted = ps.isOnboardingCompleted();
    notifyListeners();
  }

  Future<void> initialize() async {
    _loadSavedState();
  }

  Future<void> updateIncome(IncomeConfig config) async {
    await updateIncomeConfig(config);
  }

  Future<void> updateIncomeConfig(IncomeConfig config) async {
    _incomeConfig = config;
    await _persistenceService?.saveIncomeConfig(config);
    notifyListeners();
  }

  Future<void> setDeductions(List<Deduction> deductions) async {
    _deductions = List.from(deductions);
    await _persistenceService?.saveDeductions(_deductions);
    notifyListeners();
  }

  Future<void> addDeduction(Deduction deduction) async {
    _deductions.add(deduction);
    await _persistenceService?.saveDeductions(_deductions);
    notifyListeners();
  }

  Future<void> updateDeduction(Deduction deduction) async {
    final index = _deductions.indexWhere((d) => d.id == deduction.id);
    if (index != -1) {
      _deductions[index] = deduction;
    } else {
      _deductions.add(deduction);
    }
    await _persistenceService?.saveDeductions(_deductions);
    notifyListeners();
  }

  Future<void> deleteDeduction(String id) async {
    await removeDeduction(id);
  }

  Future<void> removeDeduction(String id) async {
    _deductions.removeWhere((d) => d.id == id);
    await _persistenceService?.saveDeductions(_deductions);
    notifyListeners();
  }

  Future<void> updateTaxConfig(TaxConfig tax) async {
    _taxConfig = tax;
    await _persistenceService?.saveTaxConfig(tax);
    notifyListeners();
  }

  void updatePriceInput(double price) {
    updatePrice(price);
  }

  void updatePrice(double price) {
    _price = price < 0 ? 0.0 : price;
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    await setOnboardingCompleted(true);
  }

  Future<void> setOnboardingCompleted(bool completed) async {
    _isOnboardingCompleted = completed;
    await _persistenceService?.setOnboardingCompleted(completed);
    notifyListeners();
  }

  Future<void> resetOnboarding() async {
    _isOnboardingCompleted = false;
    _incomeConfig = const IncomeConfig(
      amount: 25.0,
      frequency: PayFrequency.hourly,
    );
    _deductions = [];
    _taxConfig = const TaxConfig(salesTaxRate: 0.0);
    _price = 0.0;
    await _persistenceService?.resetAll();
    notifyListeners();
  }
}
