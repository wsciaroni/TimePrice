class TaxConfig {
  const TaxConfig({required this.salesTaxRate});

  factory TaxConfig.fromJson(Map<String, dynamic> json) {
    return TaxConfig(salesTaxRate: (json['salesTaxRate'] as num).toDouble());
  }

  final double salesTaxRate;

  double get taxMultiplier => 1.0 + (salesTaxRate / 100.0);

  Map<String, dynamic> toJson() => {'salesTaxRate': salesTaxRate};
}
