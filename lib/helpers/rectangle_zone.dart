import 'dart:ui';
import 'package:flutter/material.dart';

class RectangleZone {
  DateTime startDate, endDate;
  double highPrice, lowPrice;
  double centerPrice;
  Color fillColor, strokeColor;
  String oddsLabel;

  RectangleZone({
    required this.startDate,
    required this.endDate,
    required this.highPrice,
    required this.lowPrice,
    required this.fillColor,
    required this.strokeColor,
    required this.oddsLabel,
  })
      : centerPrice = (highPrice + lowPrice) / 2;
}
