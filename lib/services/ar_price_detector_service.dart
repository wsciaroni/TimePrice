import 'package:flutter/material.dart';
import 'package:time_price/models/deduction.dart';
import 'package:time_price/models/detected_price_tag.dart';
import 'package:time_price/models/income_config.dart';
import 'package:time_price/models/tax_config.dart';
import 'package:time_price/services/calculation_service.dart';

/// Service for analyzing text elements, extracting prices, and building AR tags.
class ArPriceDetectorService {
  /// Match dollar/currency prices ($49.99, $ 19.99, USD 25, €12.50, £5) or decimal prices (49.99)
  static final RegExp priceRegexWithSymbol = RegExp(
    r'(?:\$|USD|EUR|GBP|€|£)\s*(\d{1,3}(?:,\d{3})*(?:\.\d{1,2})?|\d+(?:\.\d{1,2})?)',
    caseSensitive: false,
  );

  static final RegExp priceRegexDecimal = RegExp(
    r'\b(\d{1,3}(?:,\d{3})*\.\d{2})\b',
  );

  /// Extract numeric price from text input. Returns null if invalid or <= 0.
  static double? extractPrice(String input) {
    final clean = input.trim();
    if (clean.isEmpty || clean.startsWith('-')) return null;

    // First try matching explicit currency symbol ($19.99, $ 20)
    var match = priceRegexWithSymbol.firstMatch(clean);
    if (match != null) {
      final numberStr = match.group(1)?.replaceAll(',', '');
      if (numberStr != null) {
        final val = double.tryParse(numberStr);
        if (val != null && val > 0 && val < 1000000) return val;
      }
    }

    // Secondary try matching standard 2-decimal price format (19.99)
    match = priceRegexDecimal.firstMatch(clean);
    if (match != null) {
      final numberStr = match.group(1)?.replaceAll(',', '');
      if (numberStr != null) {
        final val = double.tryParse(numberStr);
        if (val != null && val > 0 && val < 1000000) return val;
      }
    }

    return null;
  }

  /// Process raw OCR/text detection results and return a list of DetectedPriceTags
  static List<DetectedPriceTag> detectPricesFromTextBlocks({
    required List<({String text, Rect boundingBox})> textBlocks,
    required IncomeConfig income,
    required List<Deduction> deductions,
    required TaxConfig tax,
  }) {
    final tags = <DetectedPriceTag>[];
    int counter = 1;

    for (final block in textBlocks) {
      final priceVal = extractPrice(block.text);
      if (priceVal != null) {
        final timeResult = CalculationService.calculateTimeCost(
          price: priceVal,
          income: income,
          deductions: deductions,
          tax: tax,
        );

        tags.add(
          DetectedPriceTag(
            id: 'tag_$counter',
            rawText: block.text.trim(),
            numericPrice: priceVal,
            boundingBox: block.boundingBox,
            timeCostResult: timeResult,
          ),
        );
        counter++;
      }
    }

    return tags;
  }

  /// Generate sample AR price tags for simulation / test gallery
  static List<DetectedPriceTag> getSamplePriceTags({
    required Size screenSize,
    required IncomeConfig income,
    required List<Deduction> deductions,
    required TaxConfig tax,
  }) {
    final width = screenSize.width;
    final height = screenSize.height;

    final sampleInputs = [
      (
        text: '\$14.99',
        boundingBox: Rect.fromLTWH(
          width * 0.15,
          height * 0.22,
          130,
          60,
        )
      ),
      (
        text: '\$49.99',
        boundingBox: Rect.fromLTWH(
          width * 0.55,
          height * 0.35,
          140,
          65,
        )
      ),
      (
        text: '\$199.00',
        boundingBox: Rect.fromLTWH(
          width * 0.25,
          height * 0.58,
          150,
          70,
        )
      ),
      (
        text: '\$1,250.00',
        boundingBox: Rect.fromLTWH(
          width * 0.58,
          height * 0.72,
          160,
          70,
        )
      ),
    ];

    return detectPricesFromTextBlocks(
      textBlocks: sampleInputs,
      income: income,
      deductions: deductions,
      tax: tax,
    );
  }
}
