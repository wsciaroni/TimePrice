# TimePrice Architecture & Requirements Documentation

Welcome to the **TimePrice** codebase. This document details the architectural design, requirements specification, core formulas, project layout, testing setup, and guidelines for future developers and AI agents working on this application.

---

## 1. Project Overview

**TimePrice** is a Flutter application that converts item purchase prices into working time equivalents (months, weeks, days, hours, minutes, and seconds).

Users can configure:
- Income with flexible frequencies (Hourly, Weekly, BiWeekly, Salary).
- Pre-tax and Post-tax payroll deductions with custom payment frequencies.
- Sales tax rate percentage.
- Onboarding wizard state and persistent settings.

---

## 2. System Architecture & Component Mapping

```
lib/
├── main.dart                   # Application entry point and theme config
├── models/
│   ├── pay_frequency.dart      # Enum: Hourly, Weekly, BiWeekly, Monthly, Salary
│   ├── income_config.dart     # Income model & gross hourly pay calculator
│   ├── deduction.dart          # Pre/Post tax deduction model
│   ├── tax_config.dart         # Sales tax configuration model
│   └── time_cost_result.dart   # Calculation result container
├── services/
│   ├── calculation_service.dart # Net wage & time-cost conversion logic
│   └── persistence_service.dart # Shared Preferences persistence adapter
├── providers/
│   └── app_state_provider.dart  # Provider/ChangeNotifier state management
└── ui/
    ├── calculator_screen.dart   # Main item price & time-cost screen
    ├── settings_screen.dart     # Pay, deductions & tax config screen
    └── onboarding/
        └── onboarding_wizard.dart # First-run guided setup wizard
```

---

## 3. Financial & Time Conversion Formulas

### Gross Hourly Pay
- **Annual Hours Base**: 2,080 hours/year (40 hrs/week × 52 weeks).
- **Pay Frequencies**:
  - `Hourly`: Amount
  - `Weekly`: $(\text{Amount} \times 52) / 2080$
  - `BiWeekly`: $(\text{Amount} \times 26) / 2080$
  - `Monthly`: $(\text{Amount} \times 12) / 2080$
  - `Salary`: $\text{Amount} / 2080$

### Net Hourly Wage
1. $\text{Gross Annual Income} = \text{Gross Hourly Pay} \times 2080$
2. $\text{Annual Pre-Tax Deductions} = \sum (\text{Deduction Amount} \times \text{Periods Per Year})$
3. $\text{Taxable Income} = \max(0, \text{Gross Annual Income} - \text{Annual Pre-Tax Deductions})$
4. $\text{Annual Post-Tax Deductions} = \sum (\text{Deduction Amount} \times \text{Periods Per Year})$
5. $\text{Net Annual Income} = \max(0, \text{Taxable Income} - \text{Annual Post-Tax Deductions})$
6. $\text{Net Hourly Wage} = \text{Net Annual Income} / 2080$

### Item Total & Time Breakdown
1. $\text{Total Item Price} = \text{Base Price} \times (1 + \frac{\text{Sales Tax \%}}{100})$
2. $\text{Total Hours Required} = \frac{\text{Total Item Price}}{\text{Net Hourly Wage}}$
3. Time breakdown conversion cascade:
   - **Months**: 160 working hours
   - **Weeks**: 40 working hours
   - **Days**: 8 working hours
   - **Hours**: 1 working hour
   - **Minutes**: $1/60$ hour
   - **Seconds**: $1/3600$ hour

---

## 4. Requirements Traceability Matrix

| Req ID | Requirement Description | Implementation Components | Verification Tests |
| :--- | :--- | :--- | :--- |
| **R1.1** | Multi-frequency income setup | `lib/models/pay_frequency.dart`, `lib/models/income_config.dart` | `test/models/income_config_test.dart` |
| **R1.2** | Pre/Post tax payroll deductions | `lib/models/deduction.dart`, `lib/services/calculation_service.dart` | `test/services/calculation_service_test.dart` |
| **R1.3** | Sales tax configuration | `lib/models/tax_config.dart`, `lib/services/calculation_service.dart` | `test/models/tax_config_test.dart` |
| **R1.4** | Onboarding setup & Settings | `lib/ui/onboarding/onboarding_wizard.dart`, `lib/ui/settings_screen.dart` | `test/e2e/onboarding_e2e_test.dart`, `test/e2e/settings_e2e_test.dart` |
| **R2.1** | Dynamic price-to-time conversion | `lib/ui/calculator_screen.dart`, `lib/services/calculation_service.dart` | `test/services/calculation_service_test.dart`, `test/e2e/calculator_e2e_test.dart` |
| **R3.1** | >90% Decision Coverage | Test suite in `test/` (80 unit + 88 E2E/Widget tests) | `flutter test --coverage` (97.11% achieved) |
| **R3.2** | Clean Static Analysis | `analysis_options.yaml` | `flutter analyze` (0 issues) |
| **R4.1** | Automated CI Pipeline | `.github/workflows/ci.yml`, `sonar-project.properties` | GitHub Actions workflow execution |

---

## 5. Developer & Agent Operational Guidelines

### Quality Commands
Before submitting PRs or completing tasks, run:
```bash
# 1. Static code analysis
flutter analyze

# 2. Run unit & widget test suite with coverage
flutter test --coverage

# 3. Build verification
flutter build apk --debug
```

### Future Enhancements Roadmap
- **Augmented Reality (AR) Overlay**: Integrate image/barcode camera recognition to capture price tags in real time and overlay time-cost tags in AR.
- **Advanced Tax Brackets**: Add income tax tier calculations based on filing status.
- **Multiple Currency Support**: Add locale-aware currency symbol formatting.
