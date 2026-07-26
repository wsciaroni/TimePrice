import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_price/models/detected_price_tag.dart';
import 'package:time_price/models/time_cost_result.dart';
import 'package:time_price/ui/ar/ar_tag_overlay_painter.dart';

void main() {
  group('ArTagOverlayPainter Unit Tests', () {
    testWidgets('ArTagOverlayPainter paints scan animation reticle and price badges', (tester) async {
      const result1 = TimeCostResult(
        totalPriceWithTax: 19.99,
        netHourlyPay: 20.0,
        totalWorkingHours: 1.0,
        months: 0,
        weeks: 0,
        days: 0,
        hours: 1,
        minutes: 0,
        seconds: 0,
        formattedNaturalString: '1 hour',
      );

      const result2 = TimeCostResult(
        totalPriceWithTax: 49.99,
        netHourlyPay: 20.0,
        totalWorkingHours: 2.5,
        months: 0,
        weeks: 0,
        days: 0,
        hours: 2,
        minutes: 30,
        seconds: 0,
        formattedNaturalString: '2 hours, 30 minutes',
      );

      const tag1 = DetectedPriceTag(
        id: 't1',
        rawText: '\$19.99',
        numericPrice: 19.99,
        boundingBox: Rect.fromLTWH(50, 50, 100, 40),
        timeCostResult: result1,
        isHighlighted: true,
      );

      const tag2 = DetectedPriceTag(
        id: 't2',
        rawText: '\$49.99',
        numericPrice: 49.99,
        boundingBox: Rect.fromLTWH(200, 200, 120, 50),
        timeCostResult: result2,
        isHighlighted: false,
      );

      final oldPainter = ArTagOverlayPainter(
        tags: const [tag1, tag2],
        scanAnimationValue: 0.1,
        viewMode: ArViewMode.compact,
      );

      final painter = ArTagOverlayPainter(
        tags: const [tag1, tag2],
        scanAnimationValue: 0.5,
        viewMode: ArViewMode.expanded,
        selectedTagId: 't1',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomPaint(
              size: const Size(400, 800),
              painter: painter,
            ),
          ),
        ),
      );

      expect(find.byType(CustomPaint), findsWidgets);
      expect(painter.shouldRepaint(oldPainter), true);
    });
  });
}
