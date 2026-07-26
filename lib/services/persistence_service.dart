import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:time_price/models/deduction.dart';
import 'package:time_price/models/income_config.dart';
import 'package:time_price/models/pay_frequency.dart';
import 'package:time_price/models/tax_config.dart';

class PersistenceService {
  PersistenceService(this.prefs);

  final SharedPreferences prefs;

  static const _keyIncome = 'time_price_income';
  static const _keyDeductions = 'time_price_deductions';
  static const _keyTax = 'time_price_tax';
  static const _keyOnboardingCompleted = 'time_price_onboarding_completed';

  static Future<PersistenceService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return PersistenceService(prefs);
  }

  IncomeConfig loadIncomeConfig() {
    try {
      final str = prefs.getString(_keyIncome);
      if (str != null) {
        return IncomeConfig.fromJson(jsonDecode(str) as Map<String, dynamic>);
      }
    } catch (_) {}
    return const IncomeConfig(amount: 25.0, frequency: PayFrequency.hourly);
  }

  Future<bool> saveIncomeConfig(IncomeConfig config) async {
    return prefs.setString(_keyIncome, jsonEncode(config.toJson()));
  }

  List<Deduction> loadDeductions() {
    try {
      final str = prefs.getString(_keyDeductions);
      if (str != null) {
        final list = jsonDecode(str) as List<dynamic>;
        return list
            .map((e) => Deduction.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  Future<bool> saveDeductions(List<Deduction> deductions) async {
    final list = deductions.map((e) => e.toJson()).toList();
    return prefs.setString(_keyDeductions, jsonEncode(list));
  }

  TaxConfig loadTaxConfig() {
    try {
      final str = prefs.getString(_keyTax);
      if (str != null) {
        return TaxConfig.fromJson(jsonDecode(str) as Map<String, dynamic>);
      }
    } catch (_) {}
    return const TaxConfig(salesTaxRate: 0.0);
  }

  Future<bool> saveTaxConfig(TaxConfig tax) async {
    return prefs.setString(_keyTax, jsonEncode(tax.toJson()));
  }

  bool isOnboardingCompleted() {
    try {
      return prefs.getBool(_keyOnboardingCompleted) ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> setOnboardingCompleted(bool completed) async {
    return prefs.setBool(_keyOnboardingCompleted, completed);
  }

  Future<bool> resetAll() async {
    await prefs.remove(_keyIncome);
    await prefs.remove(_keyDeductions);
    await prefs.remove(_keyTax);
    await prefs.remove(_keyOnboardingCompleted);
    return true;
  }
}
