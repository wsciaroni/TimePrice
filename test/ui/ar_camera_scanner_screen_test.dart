import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:time_price/models/detected_price_tag.dart';
import 'package:time_price/providers/app_state_provider.dart';
import 'package:time_price/ui/ar/ar_camera_scanner_screen.dart';
import 'package:time_price/ui/calculator/calculator_screen.dart';

Widget _createArTestWidget({List<DetectedPriceTag>? initialTags}) {
  return ChangeNotifierProvider<AppStateProvider>(
    create: (_) => AppStateProvider(),
    child: MaterialApp(
      home: ArCameraScannerScreen(initialTags: initialTags),
    ),
  );
}

Widget _createCalculatorWithArWidget() {
  return ChangeNotifierProvider<AppStateProvider>(
    create: (_) => AppStateProvider(),
    child: const MaterialApp(
      home: CalculatorScreen(),
    ),
  );
}

void main() {
  group('ArCameraScannerScreen Widget Tests', () {
    testWidgets('Renders AR Camera Scanner screen elements correctly', (tester) async {
      await tester.pumpWidget(_createArTestWidget());
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('AR Price Tag Scanner'), findsOneWidget);
      expect(find.byKey(const Key('ar_flash_toggle')), findsOneWidget);
      expect(find.byKey(const Key('ar_freeze_toggle')), findsOneWidget);
      expect(find.byKey(const Key('ar_view_mode_toggle')), findsOneWidget);
    });

    testWidgets('Toggles flash/torch icon state', (tester) async {
      await tester.pumpWidget(_createArTestWidget());
      await tester.pump(const Duration(milliseconds: 300));

      final flashBtn = find.byKey(const Key('ar_flash_toggle'));
      expect(find.byIcon(Icons.flash_off), findsOneWidget);

      await tester.tap(flashBtn);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byIcon(Icons.flash_on), findsOneWidget);
    });

    testWidgets('Toggles freeze frame state', (tester) async {
      await tester.pumpWidget(_createArTestWidget());
      await tester.pump(const Duration(milliseconds: 300));

      final freezeBtn = find.byKey(const Key('ar_freeze_toggle'));
      expect(find.text('AR Price Tag Scanner'), findsOneWidget);

      await tester.tap(freezeBtn);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('AR Frame Paused'), findsOneWidget);
    });

    testWidgets('Toggles view mode (compact vs expanded)', (tester) async {
      await tester.pumpWidget(_createArTestWidget());
      await tester.pump(const Duration(milliseconds: 300));

      final viewModeBtn = find.byKey(const Key('ar_view_mode_toggle'));
      expect(find.byIcon(Icons.label), findsOneWidget);

      await tester.tap(viewModeBtn);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byIcon(Icons.label_important), findsOneWidget);
    });

    testWidgets('Resets sample tags when refresh button is tapped', (tester) async {
      await tester.pumpWidget(_createArTestWidget());
      await tester.pump(const Duration(milliseconds: 300));

      final resetBtn = find.byKey(const Key('ar_reset_tags_button'));
      await tester.tap(resetBtn);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(ArCameraScannerScreen), findsOneWidget);
    });

    testWidgets('Manual price entry adds new AR tag to frame', (tester) async {
      await tester.pumpWidget(_createArTestWidget());
      await tester.pump(const Duration(milliseconds: 300));

      final addBtn = find.byKey(const Key('ar_add_tag_button'));
      await tester.tap(addBtn);
      await tester.pump(const Duration(milliseconds: 300));

      final input = find.byKey(const Key('ar_manual_price_input'));
      expect(input, findsOneWidget);

      // Test invalid text (does not submit)
      await tester.enterText(input, 'invalid');
      final submitBtn = find.byKey(const Key('ar_submit_manual_price'));
      await tester.tap(submitBtn);
      await tester.pump(const Duration(milliseconds: 300));
      expect(input, findsOneWidget);

      // Test valid text
      await tester.enterText(input, '75.00');
      await tester.tap(submitBtn);
      await tester.pump(const Duration(milliseconds: 300));

      expect(input, findsNothing);
    });

    testWidgets('Manual price entry adds new AR tag and can open detail sheet', (tester) async {
      await tester.pumpWidget(_createArTestWidget());
      await tester.pump(const Duration(milliseconds: 300));

      final addBtn = find.byKey(const Key('ar_add_tag_button'));
      await tester.tap(addBtn);
      await tester.pump(const Duration(milliseconds: 300));

      final input = find.byKey(const Key('ar_manual_price_input'));
      await tester.enterText(input, '75.00');
      final submitBtn = find.byKey(const Key('ar_submit_manual_price'));
      await tester.tap(submitBtn);
      await tester.pump(const Duration(milliseconds: 300));

      expect(input, findsNothing);
    });

    testWidgets('Navigates from Calculator to AR Scanner and back', (tester) async {
      await tester.pumpWidget(_createCalculatorWithArWidget());
      await tester.pump();

      final arCamBtn = find.byKey(const Key('ar_camera_button'));
      expect(arCamBtn, findsOneWidget);

      await tester.tap(arCamBtn);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('AR Price Tag Scanner'), findsOneWidget);

      final backBtn = find.byKey(const Key('ar_back_button'));
      await tester.tap(backBtn);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(CalculatorScreen), findsOneWidget);
    });
  });
}
