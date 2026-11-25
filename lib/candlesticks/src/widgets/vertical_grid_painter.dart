import 'dart:math';

import 'package:flutter/cupertino.dart';

import '../utils/helper_functions.dart';

/// Rejilla anclada a los datos: las líneas verticales siguen a las velas y las
/// horizontales a los niveles de precio, así se desplaza y escala con el gráfico.
class GreyFixedGridPainter extends CustomPainter {
  final double targetSpacingPx;
  final double candleWidth;
  final int index;
  final double high;
  final double low;
  final Color lineColor;
  final double strokeWidth;

  GreyFixedGridPainter({
    required this.targetSpacingPx,
    required this.candleWidth,
    required this.index,
    required this.high,
    required this.low,
    this.lineColor = const Color(0xFFFFFFFF),
    this.strokeWidth = 1.0,
  });

  static int _niceStep(double raw) {
    if (raw <= 1) return 1;
    final double base = pow(10, (log(raw) / ln10).floor()).toDouble();
    for (final m in const [1, 2, 5, 10]) {
      if (m * base >= raw) return (m * base).round();
    }
    return (10 * base).round();
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final Paint p = Paint()
      ..color = lineColor.withValues(alpha: .10)
      ..strokeWidth = strokeWidth
      ..isAntiAlias = false;

    double topY = 0;
    double bottomY = size.height;
    final double range = high - low;
    if (range > 0 && range.isFinite) {
      final double priceStep =
          HelperFunctions.calculatePriceScale(size.height, high, low);
      if (priceStep > 0 && priceStep.isFinite) {
        double minY = double.infinity;
        double maxY = double.negativeInfinity;
        double price = (low / priceStep).ceil() * priceStep;
        while (price <= high) {
          final double y = (high - price) / range * size.height;
          canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
          minY = min(minY, y);
          maxY = max(maxY, y);
          price += priceStep;
        }
        if (minY.isFinite) topY = minY;
        if (maxY.isFinite) bottomY = maxY;
      }
    }

    if (candleWidth > 0 && targetSpacingPx > 0) {
      final int step = _niceStep(targetSpacingPx / candleWidth);
      final int firstSlot = index;
      final int lastSlot = index + (size.width / candleWidth).ceil() + 1;
      int k = (firstSlot / step).floor() * step;
      for (; k <= lastSlot; k += step) {
        final double x = size.width - (k - index + 0.5) * candleWidth;
        if (x < 0 || x > size.width) continue;
        canvas.drawLine(Offset(x, topY), Offset(x, bottomY), p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant GreyFixedGridPainter old) {
    return targetSpacingPx != old.targetSpacingPx ||
        candleWidth != old.candleWidth ||
        index != old.index ||
        high != old.high ||
        low != old.low ||
        lineColor != old.lineColor ||
        strokeWidth != old.strokeWidth;
  }
}
