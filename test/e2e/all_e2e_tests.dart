import 'onboarding_e2e_test.dart' as onboarding_test;
import 'income_frequencies_e2e_test.dart' as income_test;
import 'deductions_e2e_test.dart' as deductions_test;
import 'tax_e2e_test.dart' as tax_test;
import 'calculator_e2e_test.dart' as calculator_test;
import 'settings_e2e_test.dart' as settings_test;
import 'boundary_corner_e2e_test.dart' as boundary_test;
import 'cross_feature_combinations_e2e_test.dart' as cross_feature_test;
import 'real_world_scenarios_e2e_test.dart' as real_world_test;

void main() {
  onboarding_test.main();
  income_test.main();
  deductions_test.main();
  tax_test.main();
  calculator_test.main();
  settings_test.main();
  boundary_test.main();
  cross_feature_test.main();
  real_world_test.main();
}
