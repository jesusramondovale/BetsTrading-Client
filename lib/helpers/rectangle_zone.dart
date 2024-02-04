import 'dart:ui';
import 'package:flutter/material.dart';

class RectangleZone {
  double startX, endX, startY, centerY, endY;
  double originalStartX, originalEndX, originalStartY, originalEndY;
  double height;
  final Color fillColor, strokeColor;
  final String oddsLabel;
  late double scaleX = 1.0;
  late double scaleY = 1.0;
  final double offsetX;
  final double offsetY;

  RectangleZone({
    required this.startX,
    required this.endX,
    required this.startY,
    required this.centerY,
    required this.endY,
    required this.height,
    required this.originalStartX,
    required this.originalEndX,
    required this.originalStartY,
    required this.originalEndY,
    required this.fillColor,
    required this.strokeColor,
    required this.oddsLabel,
    required this.offsetX,
    required this.offsetY,
    }
  );

  bool contains(Offset localPosition) {
    return localPosition.dx >= startX &&
        localPosition.dx <= endX &&
        localPosition.dy >= startY &&
        localPosition.dy <= endY;
  }


}
