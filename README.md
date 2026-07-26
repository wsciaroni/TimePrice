# TimePrice ⏳ Dollar-to-Time Cost Calculator

**TimePrice** is a Flutter application designed to help users evaluate purchases in terms of their actual working time. By factoring in gross income, pre-tax and post-tax payroll deductions, and local sales tax rates, TimePrice translates prices into exact working months, weeks, days, hours, minutes, and seconds.

---

## 🚀 Key Features

- **Multi-Frequency Income Configuration**:
  - Support for **Hourly**, **Weekly**, **BiWeekly**, **Monthly**, and **Salary** pay structures.
- **Flexible Payroll Deductions**:
  - Pre-tax and Post-tax deduction tracking with custom recurrence frequencies.
- **Sales Tax Customization**:
  - Configurable sales tax percentage automatically applied to item prices.
- **Natural Time Conversion**:
  - Instant conversion into months (160h), weeks (40h), days (8h), hours, minutes, and seconds.
- **Guided Onboarding & Settings**:
  - Step-by-step first-run wizard and dedicated Settings screen for updating pay, tax, or deductions.
- **Local Persistence**:
  - Preferences saved locally via `shared_preferences`.

---

## 📐 Core Formulas

1. **Annual Hours**: Based on standard 2,080 working hours/year (40 hrs/week × 52 weeks).
2. **Net Hourly Wage Calculation**:
   $$\text{Gross Annual Income} = \text{Gross Hourly Pay} \times 2080$$
   $$\text{Taxable Income} = \max(0, \text{Gross Annual Income} - \text{Annual Pre-Tax Deductions})$$
   $$\text{Net Annual Income} = \max(0, \text{Taxable Income} - \text{Annual Post-Tax Deductions})$$
   $$\text{Net Hourly Wage} = \frac{\text{Net Annual Income}}{2080}$$
3. **Item Time-Cost Calculation**:
   $$\text{Total Item Price} = \text{Base Price} \times (1 + \frac{\text{Sales Tax \%}}{100})$$
   $$\text{Hours Required} = \frac{\text{Total Item Price}}{\text{Net Hourly Wage}}$$

---

## 🛠 Project Structure

```
lib/
├── main.dart                   # Main app entry point & theme setup
├── models/
│   ├── pay_frequency.dart      # Frequency enum & pay period conversion
│   ├── income_config.dart     # Income configuration & gross pay logic
│   ├── deduction.dart          # Deduction model (pre/post-tax)
│   ├── tax_config.dart         # Sales tax configuration
│   └── time_cost_result.dart   # Calculation output format
├── services/
│   ├── calculation_service.dart # Net pay & time conversion calculations
│   └── persistence_service.dart # Shared preferences storage adapter
├── providers/
│   └── app_state_provider.dart  # Provider state management
└── ui/
    ├── calculator_screen.dart   # Main item price calculator
    ├── settings_screen.dart     # Settings & preference updates
    └── onboarding/
        └── onboarding_wizard.dart # First-time setup wizard
```

---

## 🧪 Testing & Code Quality

The project mandates zero static analysis errors and high decision coverage (>90%).

```bash
# Analyze code
flutter analyze

# Run unit and widget tests with coverage report
flutter test --coverage

# Build verification
flutter build apk --debug
```

Current Quality Metrics:
- **Test Pass Rate**: 100% (168 / 168 tests passing)
- **Decision / Branch Coverage**: 97.11%
- **Static Analysis**: 0 issues

---

## ⚙️ CI/CD Pipeline

The GitHub Actions workflow is located at `.github/workflows/ci.yml`. It automatically executes:
1. Flutter SDK setup and dependency installation (`flutter pub get`)
2. Static code analysis (`flutter analyze`)
3. Test suite execution with coverage (`flutter test --coverage`)
4. Debug APK build (`flutter build apk --debug`)
5. SonarCloud analysis scanning (`sonar-project.properties`)
