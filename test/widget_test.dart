import 'package:flutter_test/flutter_test.dart';
import 'package:time_price/main.dart';

void main() {
  testWidgets('TimePriceApp renders onboarding screen when not completed', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const TimePriceApp());

    expect(find.text('Welcome to TimePrice Setup'), findsOneWidget);
    expect(find.text('1. Income Setup'), findsOneWidget);
  });
}
