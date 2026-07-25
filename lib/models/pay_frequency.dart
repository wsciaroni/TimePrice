enum PayFrequency {
  hourly,
  weekly,
  biWeekly,
  monthly,
  salary;

  String get displayName {
    switch (this) {
      case PayFrequency.hourly:
        return 'Hourly';
      case PayFrequency.weekly:
        return 'Weekly';
      case PayFrequency.biWeekly:
        return 'Bi-Weekly';
      case PayFrequency.monthly:
        return 'Monthly';
      case PayFrequency.salary:
        return 'Salary';
    }
  }

  double get payPeriodsPerYear {
    switch (this) {
      case PayFrequency.hourly:
        return 2080.0;
      case PayFrequency.weekly:
        return 52.0;
      case PayFrequency.biWeekly:
        return 26.0;
      case PayFrequency.monthly:
        return 12.0;
      case PayFrequency.salary:
        return 1.0;
    }
  }

  double get annualHours => 2080.0;
}
