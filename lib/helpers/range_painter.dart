import 'dart:math';

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

      final adjustedStartX = max(min((zone.startX + offsetX) * zone.scaleX, 350),zone.originalStartX).toDouble();
      final adjustedEndX = max(min((zone.endX + offsetX) * zone.scaleX, 410),350).toDouble();

      final adjustedStartY = (zone.centerY - zone.height/2 * zone.scaleY);
      final adjustedEndY = (zone.centerY + zone.height/2 * zone.scaleY);

      final paintFill = Paint()..color = zone.fillColor..style = PaintingStyle.fill;

      canvas.drawRect(Rect.fromLTRB(adjustedStartX, adjustedStartY, adjustedEndX, adjustedEndY), paintFill);

      final textSpan = TextSpan(
        text: zone.oddsLabel,
        style: TextStyle(color: zone.strokeColor, fontSize: 18.0, fontWeight: FontWeight.bold),
      );

      final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
      textPainter.layout(minWidth: 0, maxWidth: size.width);
      final textX = adjustedStartX + (adjustedEndX - adjustedStartX - textPainter.width) / 2;
      final textY = adjustedStartY + (adjustedEndY - adjustedStartY - textPainter.height) / 2;
      textPainter.paint(canvas, Offset(textX, textY));

    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }


}