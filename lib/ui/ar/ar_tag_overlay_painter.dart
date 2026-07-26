import 'dart:math';
import 'package:flutter/material.dart';
import 'package:time_price/models/detected_price_tag.dart';

enum ArViewMode {
  compact,
  expanded,
}

class ArTagOverlayPainter extends CustomPainter {
  ArTagOverlayPainter({
    required this.tags,
    required this.scanAnimationValue,
    this.viewMode = ArViewMode.compact,
    this.selectedTagId,
  });

  final List<DetectedPriceTag> tags;
  final double scanAnimationValue; // 0.0 to 1.0
  final ArViewMode viewMode;
  final String? selectedTagId;

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw animated AR scan line
    _drawScanLine(canvas, size);

    // 2. Draw target reticle crosshairs in center
    _drawCenterReticle(canvas, size);

    // 3. Draw AR price tags
    for (final tag in tags) {
      final isSelected = tag.id == selectedTagId || tag.isHighlighted;
      _drawArTag(canvas, tag, isSelected);
    }
  }

  void _drawScanLine(Canvas canvas, Size size) {
    final scanY = size.height * scanAnimationValue;
    final scanPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.cyan.withValues(alpha: 0.0),
          Colors.cyan.withValues(alpha: 0.8),
          Colors.purpleAccent.withValues(alpha: 0.8),
          Colors.cyan.withValues(alpha: 0.0),
        ],
      ).createShader(
        Rect.fromLTWH(0, scanY - 2, size.width, 4),
      )
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(0, scanY), Offset(size.width, scanY), scanPaint);
  }

  void _drawCenterReticle(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const radius = 24.0;
    canvas.drawCircle(center, radius, paint);

    // Reticle crosshair ticks
    canvas.drawLine(
      Offset(center.dx - radius - 10, center.dy),
      Offset(center.dx - radius + 4, center.dy),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx + radius - 4, center.dy),
      Offset(center.dx + radius + 10, center.dy),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - radius - 10),
      Offset(center.dx, center.dy - radius + 4),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy + radius - 4),
      Offset(center.dx, center.dy + radius + 10),
      paint,
    );
  }

  void _drawArTag(Canvas canvas, DetectedPriceTag tag, bool isSelected) {
    final rect = tag.boundingBox;

    // Corner bracket paint
    final bracketPaint = Paint()
      ..color = isSelected ? Colors.amberAccent : Colors.cyanAccent
      ..strokeWidth = isSelected ? 3.0 : 2.0
      ..style = PaintingStyle.stroke;

    // Draw AR bracket corners over price tag
    const cornerLength = 12.0;
    // Top-Left
    canvas.drawLine(
        rect.topLeft, rect.topLeft + const Offset(cornerLength, 0), bracketPaint);
    canvas.drawLine(
        rect.topLeft, rect.topLeft + const Offset(0, cornerLength), bracketPaint);
    // Top-Right
    canvas.drawLine(rect.topRight,
        rect.topRight + const Offset(-cornerLength, 0), bracketPaint);
    canvas.drawLine(
        rect.topRight, rect.topRight + const Offset(0, cornerLength), bracketPaint);
    // Bottom-Left
    canvas.drawLine(rect.bottomLeft,
        rect.bottomLeft + const Offset(cornerLength, 0), bracketPaint);
    canvas.drawLine(rect.bottomLeft,
        rect.bottomLeft + const Offset(0, -cornerLength), bracketPaint);
    // Bottom-Right
    canvas.drawLine(rect.bottomRight,
        rect.bottomRight + const Offset(-cornerLength, 0), bracketPaint);
    canvas.drawLine(rect.bottomRight,
        rect.bottomRight + const Offset(0, -cornerLength), bracketPaint);

    // Bounding Box Glow background
    final bgPaint = Paint()
      ..color = isSelected
          ? Colors.deepPurple.withValues(alpha: 0.85)
          : Colors.black.withValues(alpha: 0.75)
      ..style = PaintingStyle.fill;

    // Badge label content
    final badgeText = viewMode == ArViewMode.compact
        ? '⚡ ${tag.compactTimeBadge}'
        : '${tag.rawText} ➔ ⚡ ${tag.compactTimeBadge}';

    final textSpan = TextSpan(
      text: badgeText,
      style: TextStyle(
        color: isSelected ? Colors.amberAccent : Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: isSelected ? 15 : 13,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    const badgePadding = EdgeInsets.symmetric(horizontal: 10, vertical: 6);
    final badgeWidth = textPainter.width + badgePadding.horizontal;
    final badgeHeight = textPainter.height + badgePadding.vertical;

    final badgeCenter = Offset(rect.center.dx, rect.center.dy);
    final badgeRect = Rect.fromCenter(
      center: badgeCenter,
      width: max(badgeWidth, rect.width),
      height: max(badgeHeight, rect.height),
    );

    final RRect rrect = RRect.fromRectAndRadius(
      badgeRect,
      const Radius.circular(8.0),
    );

    canvas.drawRRect(rrect, bgPaint);

    final borderPaint = Paint()
      ..color = isSelected ? Colors.amberAccent : Colors.cyanAccent
      ..strokeWidth = isSelected ? 2.0 : 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(rrect, borderPaint);

    textPainter.paint(
      canvas,
      Offset(
        badgeRect.left + (badgeRect.width - textPainter.width) / 2,
        badgeRect.top + (badgeRect.height - textPainter.height) / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant ArTagOverlayPainter oldDelegate) {
    return oldDelegate.scanAnimationValue != scanAnimationValue ||
        oldDelegate.tags != tags ||
        oldDelegate.viewMode != viewMode ||
        oldDelegate.selectedTagId != selectedTagId;
  }
}
