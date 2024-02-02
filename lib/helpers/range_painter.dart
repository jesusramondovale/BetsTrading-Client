import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class RangePainter extends CustomPainter {
  final double startX;
  final double endX;
  final double startY;
  final double endY;
  final Color fillColor;
  final Color strokeColor;
  final String oddsLabel;
  final double scaleY;

  RangePainter({
    required this.startX,
    required this.endX,
    required this.startY,
    required this.endY,
    required this.fillColor,
    required this.strokeColor,
    required this.oddsLabel,
    required this.scaleY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double fixedHeight = this.endY - this.startY ;
    final double newHeight = fixedHeight * scaleY;
    final double centerY = this.startY + (fixedHeight / 2.0) ;
    final double startY = centerY - (newHeight / 2.0);
    final double endY = centerY + (newHeight / 2.0);
    if (kDebugMode) {
      print("Repaint with scale ==> $scaleY");
    }
    final paintFill = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTRB(startX, startY, endX, endY),
      paintFill,
    );

    final textSpan = TextSpan(
      text: oddsLabel,
      style: TextStyle(
        color: strokeColor,
        fontSize: 20.0,
        fontWeight: FontWeight.bold,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(
      minWidth: 0,
      maxWidth: size.width,
    );

    final textX = startX + (endX - startX - textPainter.width) / 2;
    final textY = startY + (endY - startY - textPainter.height) / 2;
    final textOffset = Offset(textX, textY);

    if (textOffset.dx >= startX && textOffset.dy >= startY) {
      textPainter.paint(canvas, textOffset);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}