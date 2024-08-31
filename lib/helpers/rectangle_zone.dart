import 'dart:ui';
import 'package:flutter/material.dart';

import '../models/bets.dart';

class RectangleZone {
  DateTime startDate, endDate;
  double highPrice, lowPrice;
  double centerPrice;
  Color fillColor, strokeColor;
  String oddsLabel;
  Bet bet;

  RectangleZone({
    required this.startDate,
    required this.endDate,
    required this.highPrice,
    required this.lowPrice,
    required this.fillColor,
    required this.strokeColor,
    required this.oddsLabel,
    required this.bet
  })
      : centerPrice = (highPrice + lowPrice) / 2;
}
