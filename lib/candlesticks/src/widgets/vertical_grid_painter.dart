
import 'package:flutter/cupertino.dart';

class GreyFixedGridPainter extends CustomPainter {
  final double spacingPx;
  final double priceBarWidth;
  final double topPadding;
  final double bottomPadding;
  final Color lineColor;
  final double strokeWidth;
  final double startOffsetPx;

  GreyFixedGridPainter({
    this.spacingPx = 100.0,
    required this.priceBarWidth,
    this.topPadding = 0,
    this.bottomPadding = 0,
    this.lineColor = const Color(0xFFFFFFFF),
    this.strokeWidth = 1.0,
    this.startOffsetPx = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double usableWidth = size.width - priceBarWidth;
    if (usableWidth <= 0 || spacingPx <= 0) return;

    final Paint p = Paint()
      ..color = lineColor.withValues(alpha: .10)
      ..strokeWidth = strokeWidth
      ..isAntiAlias = false;

    final double top = topPadding;
    final double bottom = size.height - bottomPadding;

    double x = startOffsetPx;
    if (x < 0) x = 0;

    while (x <= usableWidth) {
      canvas.drawLine(Offset(x + 0.5, top), Offset(x + 0.5, bottom), p);
      x += spacingPx;
    }
  }

  @override
  bool shouldRepaint(covariant GreyFixedGridPainter old) {
    return spacingPx != old.spacingPx ||
        priceBarWidth != old.priceBarWidth ||
        topPadding != old.topPadding ||
        bottomPadding != old.bottomPadding ||
        lineColor != old.lineColor ||
        strokeWidth != old.strokeWidth ||
        startOffsetPx != old.startOffsetPx;
  }
}
