import 'package:flutter_test/flutter_test.dart';
import 'package:time_price/models/pay_frequency.dart';

void main() {
  group('PayFrequency', () {
    test('displayName returns correct string representation for all enum values', () {
      expect(PayFrequency.hourly.displayName, equals('Hourly'));
      expect(PayFrequency.weekly.displayName, equals('Weekly'));
      expect(PayFrequency.biWeekly.displayName, equals('Bi-Weekly'));
      expect(PayFrequency.monthly.displayName, equals('Monthly'));
      expect(PayFrequency.salary.displayName, equals('Salary'));
    });

    test('payPeriodsPerYear returns correct factor for all enum values', () {
      expect(PayFrequency.hourly.payPeriodsPerYear, equals(2080.0));
      expect(PayFrequency.weekly.payPeriodsPerYear, equals(52.0));
      expect(PayFrequency.biWeekly.payPeriodsPerYear, equals(26.0));
      expect(PayFrequency.monthly.payPeriodsPerYear, equals(12.0));
      expect(PayFrequency.salary.payPeriodsPerYear, equals(1.0));
    });

    test('annualHours returns 2080.0 for all enum values', () {
      for (final freq in PayFrequency.values) {
        expect(freq.annualHours, equals(2080.0));
      }
    });
  });
}
