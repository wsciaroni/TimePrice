import 'package:flutter_test/flutter_test.dart';
import 'package:time_price/models/tax_config.dart';

void main() {
  group('TaxConfig', () {
    test('fromJson parses JSON correctly', () {
      final json = {'salesTaxRate': 8.875};
      final taxConfig = TaxConfig.fromJson(json);
      expect(taxConfig.salesTaxRate, equals(8.875));
    });

    test('toJson serializes properties correctly', () {
      const taxConfig = TaxConfig(salesTaxRate: 7.5);
      expect(taxConfig.toJson(), equals({'salesTaxRate': 7.5}));
    });

    test('taxMultiplier calculates correct factor', () {
      const zeroTax = TaxConfig(salesTaxRate: 0.0);
      const standardTax = TaxConfig(salesTaxRate: 8.5);
      const highTax = TaxConfig(salesTaxRate: 100.0);

      expect(zeroTax.taxMultiplier, equals(1.0));
      expect(standardTax.taxMultiplier, equals(1.085));
      expect(highTax.taxMultiplier, equals(2.0));
    });
  });
}
