import 'dart:math';
import 'package:time_price/models/income_config.dart';
import 'package:time_price/models/deduction.dart';
import 'package:time_price/models/tax_config.dart';
import 'package:time_price/models/time_cost_result.dart';

class CalculationService {
  static TimeCostResult calculateTimeCost({
    required double price,
    required IncomeConfig income,
    required List<Deduction> deductions,
    required TaxConfig tax,
  }) {
    if (price <= 0) {
      return const TimeCostResult(
        totalPriceWithTax: 0.0,
        netHourlyPay: 0.0,
        totalWorkingHours: 0.0,
        months: 0,
        weeks: 0,
        days: 0,
        hours: 0,
        minutes: 0,
        seconds: 0,
        formattedNaturalString: '0 seconds',
      );
    }

    final grossAnnualIncome = income.annualIncome;

    double preTaxAnnualDeductions = 0.0;
    double postTaxAnnualDeductions = 0.0;

    for (final d in deductions) {
      final annualAmount = d.calculateAnnualAmount(grossAnnualIncome);
      if (d.type == DeductionType.preTax) {
        preTaxAnnualDeductions += annualAmount;
      } else {
        postTaxAnnualDeductions += annualAmount;
      }
    }

    final taxableAnnualIncome = max(
      0.0,
      grossAnnualIncome - preTaxAnnualDeductions,
    );
    final netAnnualIncome = max(
      0.0,
      taxableAnnualIncome - postTaxAnnualDeductions,
    );
    final netHourlyPay = netAnnualIncome / 2080.0;

    final taxRate = tax.salesTaxRate < 0 ? 0.0 : tax.salesTaxRate;
    final totalPriceWithTax = price * (1.0 + (taxRate / 100.0));

    if (netHourlyPay <= 0) {
      return TimeCostResult(
        totalPriceWithTax: totalPriceWithTax,
        netHourlyPay: 0.0,
        totalWorkingHours: double.infinity,
        months: 0,
        weeks: 0,
        days: 0,
        hours: 0,
        minutes: 0,
        seconds: 0,
        formattedNaturalString: 'Infinity (Unaffordable)',
      );
    }

    final totalWorkingHours = totalPriceWithTax / netHourlyPay;
    double remSecs = (totalWorkingHours * 3600.0).roundToDouble();

    const monthSecs = 624000.0; // 173.333333 * 3600
    const weekSecs = 144000.0; // 40 * 3600
    const daySecs = 28800.0; // 8 * 3600
    const hourSecs = 3600.0;
    const minSecs = 60.0;

    final months = (remSecs / monthSecs).floor();
    remSecs -= months * monthSecs;

    final weeks = (remSecs / weekSecs).floor();
    remSecs -= weeks * weekSecs;

    final days = (remSecs / daySecs).floor();
    remSecs -= days * daySecs;

    final hours = (remSecs / hourSecs).floor();
    remSecs -= hours * hourSecs;

    final minutes = (remSecs / minSecs).floor();
    remSecs -= minutes * minSecs;

    final seconds = remSecs.round();

    final parts = <String>[];
    if (months > 0) {
      parts.add('$months ${months == 1 ? "month" : "months"}');
    }
    if (weeks > 0) {
      parts.add('$weeks ${weeks == 1 ? "week" : "weeks"}');
    }
    if (days > 0) {
      parts.add('$days ${days == 1 ? "day" : "days"}');
    }
    if (hours > 0) {
      parts.add('$hours ${hours == 1 ? "hour" : "hours"}');
    }
    if (minutes > 0) {
      parts.add('$minutes ${minutes == 1 ? "minute" : "minutes"}');
    }
    if (seconds > 0 || parts.isEmpty) {
      parts.add('$seconds ${seconds == 1 ? "second" : "seconds"}');
    }

    final formattedNaturalString = parts.join(' ');

    return TimeCostResult(
      totalPriceWithTax: totalPriceWithTax,
      netHourlyPay: netHourlyPay,
      totalWorkingHours: totalWorkingHours,
      months: months,
      weeks: weeks,
      days: days,
      hours: hours,
      minutes: minutes,
      seconds: seconds,
      formattedNaturalString: formattedNaturalString,
    );
  }
}
