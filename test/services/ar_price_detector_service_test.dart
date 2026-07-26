import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_price/models/detected_price_tag.dart';
import 'package:time_price/models/income_config.dart';
import 'package:time_price/models/pay_frequency.dart';
import 'package:time_price/models/tax_config.dart';
import 'package:time_price/services/ar_price_detector_service.dart';

void main() {
  group('ArPriceDetectorService Unit Tests', () {
    const income = IncomeConfig(amount: 25.0, frequency: PayFrequency.hourly);
    const tax = TaxConfig(salesTaxRate: 0.0);

    test('extractPrice parses various price formats correctly', () {
      expect(ArPriceDetectorService.extractPrice('\$49.99'), 49.99);
      expect(ArPriceDetectorService.extractPrice('USD 120.50'), 120.50);
      expect(ArPriceDetectorService.extractPrice('€19.99'), 19.99);
      expect(ArPriceDetectorService.extractPrice('£5.00'), 5.00);
      expect(ArPriceDetectorService.extractPrice('99.00'), 99.00);
      expect(ArPriceDetectorService.extractPrice('\$1,250.00'), 1250.00);
      expect(ArPriceDetectorService.extractPrice('invalid text'), null);
      expect(ArPriceDetectorService.extractPrice(''), null);
      expect(ArPriceDetectorService.extractPrice('\$0.00'), null);
      expect(ArPriceDetectorService.extractPrice('-\$10.00'), null);
    });

    test('detectPricesFromTextBlocks processes blocks and returns AR tags', () {
      final blocks = [
        (text: 'Special Sale \$25.00', boundingBox: const Rect.fromLTWH(10, 20, 100, 40)),
        (text: 'No price here', boundingBox: const Rect.fromLTWH(50, 50, 80, 30)),
        (text: '\$100.00', boundingBox: const Rect.fromLTWH(200, 100, 120, 50)),
      ];

      final tags = ArPriceDetectorService.detectPricesFromTextBlocks(
        textBlocks: blocks,
        income: income,
        deductions: [],
        tax: tax,
      );

      expect(tags.length, 2);
      expect(tags[0].numericPrice, 25.0);
      expect(tags[0].timeCostResult.hours, 1);
      expect(tags[1].numericPrice, 100.0);
      expect(tags[1].timeCostResult.hours, 4);
    });

    test('getSamplePriceTags generates screen-proportional sample tags', () {
      final sampleTags = ArPriceDetectorService.getSamplePriceTags(
        screenSize: const Size(400, 800),
        income: income,
        deductions: [],
        tax: tax,
      );

      expect(sampleTags.length, 4);
      expect(sampleTags.any((t) => t.numericPrice == 14.99), true);
      expect(sampleTags.any((t) => t.numericPrice == 49.99), true);
    });

    test('DetectedPriceTag compactTimeBadge formats time properly', () {
      final tag = DetectedPriceTag(
        id: 't1',
        rawText: '\$50.00',
        numericPrice: 50.0,
        boundingBox: const Rect.fromLTWH(0, 0, 50, 50),
        timeCostResult: ArPriceDetectorService.detectPricesFromTextBlocks(
          textBlocks: [
            (text: '\$50.00', boundingBox: const Rect.fromLTWH(0, 0, 50, 50))
          ],
          income: income,
          deductions: [],
          tax: tax,
        ).first.timeCostResult,
      );

      expect(tag.compactTimeBadge, '2h');
      expect(tag.copyWith(isHighlighted: true).isHighlighted, true);
    });
  });
}
