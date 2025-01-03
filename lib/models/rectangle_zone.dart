import 'dart:ui';
import 'package:flutter/material.dart';


class RectangleZone {
  int id;
  DateTime startDate, endDate;
  double highPrice, lowPrice;
  double margin;
  double targetPrice;
  double centerPrice;
  Color fillColor, strokeColor;
  double odds;
  String ticker;



  RectangleZone({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.highPrice,
    required this.lowPrice,
    required this.margin,
    required this.fillColor,
    required this.strokeColor,
    required this.odds,
    required this.ticker,


  })
      : centerPrice = (highPrice + lowPrice) / 2, targetPrice = (highPrice + lowPrice) / 2;

}
