import 'dart:ui';
import 'package:flutter/material.dart';

class RectangleZone {
  double startX, endX, startY, endY;
  double originalStartX, originalEndX, originalStartY, originalEndY;
  final Color fillColor, strokeColor;
  final String oddsLabel;
  final double scaleX;
  final double scaleY;
  final double offsetX;
  final double offsetY;

  RectangleZone({
    required this.startX,
    required this.endX,
    required this.startY,
    required this.endY,
    required this.originalStartX,
    required this.originalEndX,
    required this.originalStartY,
    required this.originalEndY,
    required this.fillColor,
    required this.strokeColor,
    required this.oddsLabel,
    required this.scaleX,
    required this.scaleY,
    required this.offsetX,
    required this.offsetY,
  });

  bool contains(Offset localPosition) {
    return localPosition.dx >= startX &&
        localPosition.dx <= endX &&
        localPosition.dy >= startY &&
        localPosition.dy <= endY;
  }


}
