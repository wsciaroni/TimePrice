class TimeCostResult {
  const TimeCostResult({
    required this.totalPriceWithTax,
    required this.netHourlyPay,
    required this.totalWorkingHours,
    required this.months,
    required this.weeks,
    required this.days,
    required this.hours,
    required this.minutes,
    required this.seconds,
    required this.formattedNaturalString,
  });

  final double totalPriceWithTax;
  final double netHourlyPay;
  final double totalWorkingHours;
  final int months;
  final int weeks;
  final int days;
  final int hours;
  final int minutes;
  final int seconds;
  final String formattedNaturalString;
}
