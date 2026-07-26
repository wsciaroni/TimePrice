import 'package:flutter/material.dart';
import 'package:time_price/models/time_cost_result.dart';

/// Represents a price tag detected within the camera viewfinder or frame.
class DetectedPriceTag {
  const DetectedPriceTag({
    required this.id,
    required this.rawText,
    required this.numericPrice,
    required this.boundingBox,
    required this.timeCostResult,
    this.isHighlighted = false,
  });

  final String id;
  final String rawText;
  final double numericPrice;
  final Rect boundingBox;
  final TimeCostResult timeCostResult;
  final bool isHighlighted;

  DetectedPriceTag copyWith({
    String? id,
    String? rawText,
    double? numericPrice,
    Rect? boundingBox,
    TimeCostResult? timeCostResult,
    bool? isHighlighted,
  }) {
    return DetectedPriceTag(
      id: id ?? this.id,
      rawText: rawText ?? this.rawText,
      numericPrice: numericPrice ?? this.numericPrice,
      boundingBox: boundingBox ?? this.boundingBox,
      timeCostResult: timeCostResult ?? this.timeCostResult,
      isHighlighted: isHighlighted ?? this.isHighlighted,
    );
  }

  /// Compact representation of time cost for AR overlay badge (e.g. "2h 15m" or "3d 4h")
  String get compactTimeBadge {
    final res = timeCostResult;
    if (res.netHourlyPay <= 0) return 'Unaffordable';
    if (res.totalWorkingHours == 0) return '0s';

    final parts = <String>[];
    if (res.months > 0) parts.add('${res.months}mo');
    if (res.weeks > 0) parts.add('${res.weeks}w');
    if (res.days > 0) parts.add('${res.days}d');
    if (res.hours > 0) parts.add('${res.hours}h');
    if (res.minutes > 0) parts.add('${res.minutes}m');
    if (res.seconds > 0 && parts.length < 2) parts.add('${res.seconds}s');

    return parts.isEmpty ? '0s' : parts.take(2).join(' ');
  }
}
