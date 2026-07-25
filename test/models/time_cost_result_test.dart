import 'package:flutter_test/flutter_test.dart';
import 'package:time_price/models/time_cost_result.dart';

void main() {
  group('TimeCostResult', () {
    test('Constructor correctly assigns all fields', () {
      const result = TimeCostResult(
        totalPriceWithTax: 108.875,
        netHourlyPay: 25.0,
        totalWorkingHours: 4.355,
        months: 0,
        weeks: 0,
        days: 0,
        hours: 4,
        minutes: 21,
        seconds: 18,
        formattedNaturalString: '4 hours 21 minutes 18 seconds',
      );

      expect(result.totalPriceWithTax, equals(108.875));
      expect(result.netHourlyPay, equals(25.0));
      expect(result.totalWorkingHours, equals(4.355));
      expect(result.months, equals(0));
      expect(result.weeks, equals(0));
      expect(result.days, equals(0));
      expect(result.hours, equals(4));
      expect(result.minutes, equals(21));
      expect(result.seconds, equals(18));
      expect(result.formattedNaturalString, equals('4 hours 21 minutes 18 seconds'));
    });
  });
}
