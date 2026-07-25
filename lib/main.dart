import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:time_price/providers/app_state_provider.dart';
import 'package:time_price/services/persistence_service.dart';
import 'package:time_price/ui/calculator/calculator_screen.dart';
import 'package:time_price/ui/onboarding/onboarding_wizard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final persistence = await PersistenceService.init();
  runApp(TimePriceApp(persistenceService: persistence));
}

class TimePriceApp extends StatelessWidget {
  const TimePriceApp({super.key, this.persistenceService});

  final PersistenceService? persistenceService;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppStateProvider>(
      create: (_) => AppStateProvider(persistenceService: persistenceService),
      child: Consumer<AppStateProvider>(
        builder: (context, provider, child) {
          return MaterialApp(
            title: 'TimePrice',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
              useMaterial3: true,
            ),
            home: provider.isOnboardingCompleted
                ? const CalculatorScreen()
                : const OnboardingWizardScreen(),
          );
        },
      ),
    );
  }
}
