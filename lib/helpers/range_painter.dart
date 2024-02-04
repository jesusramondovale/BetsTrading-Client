import 'package:client_0_0_1/helpers/rectangle_zone.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class RangePainter extends CustomPainter {

  final List<RectangleZone> zones;
  final double scaleX, scaleY, offsetX, offsetY;

  RangePainter({
    required this.zones,
    required this.scaleX ,
    required this.scaleY ,
    required this.offsetX ,
    required this.offsetY ,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final zone in zones) {

      double startX = (zone.startX + offsetX) * scaleX;
      double endX = (zone.endX + offsetX) * scaleX;
      double fixedHeight = (zone.endY - zone.startY) * scaleY;
      double centerY = (zone.startY + offsetY) * scaleY + (fixedHeight / 2.0);
      double startY = centerY - (fixedHeight / 2.0);
      double endY = centerY + (fixedHeight / 2.0);
      final adjustedStartX = (zone.startX + offsetX) * scaleX;
      final adjustedEndX = (zone.endX + offsetX) * scaleX;
      final adjustedStartY = (zone.startY + offsetY) * scaleY;
      final adjustedEndY = (zone.endY + offsetY) * scaleY;
      final paintFill = Paint()..color = zone.fillColor..style = PaintingStyle.fill;
      canvas.drawRect(Rect.fromLTRB(adjustedStartX, adjustedStartY, adjustedEndX, adjustedEndY), paintFill);

      final textSpan = TextSpan(
        text: zone.oddsLabel,
        style: TextStyle(color: zone.strokeColor, fontSize: 20.0, fontWeight: FontWeight.bold),
      );
      final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
      textPainter.layout(minWidth: 0, maxWidth: size.width);
      final textX = startX + (endX - startX - textPainter.width) / 2;
      final textY = startY + (endY - startY - textPainter.height) / 2;

      if (textX >= startX && textY >= startY) {
        textPainter.paint(canvas, Offset(textX, textY));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }


}