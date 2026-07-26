import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:time_price/main.dart';
import 'package:time_price/services/persistence_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TimePriceApp Main Widget Tests', () {
    testWidgets('1. Renders OnboardingWizardScreen when onboarding is NOT completed', (tester) async {
      SharedPreferences.setMockInitialValues({
        'time_price_onboarding_completed': false,
      });

      final persistence = await PersistenceService.init();
      await tester.pumpWidget(TimePriceApp(persistenceService: persistence));
      await tester.pumpAndSettle();

      expect(find.text('Welcome to TimePrice Setup'), findsOneWidget);
      expect(find.text('1. Income Setup'), findsOneWidget);
      expect(find.text('TimePrice Calculator'), findsNothing);
    });

    testWidgets('2. Renders CalculatorScreen when onboarding IS completed', (tester) async {
      SharedPreferences.setMockInitialValues({
        'time_price_onboarding_completed': true,
      });

      final persistence = await PersistenceService.init();
      await tester.pumpWidget(TimePriceApp(persistenceService: persistence));
      await tester.pumpAndSettle();

      expect(find.text('TimePrice Calculator'), findsOneWidget);
      expect(find.text('Welcome to TimePrice Setup'), findsNothing);
    });
  });
}
