import 'dart:math';
import 'package:client_0_0_1/candlesticks/src/constant/view_constants.dart';
import 'package:flutter/material.dart';
import '../candlesticks/src/models/candle.dart';
import 'common.dart';
import 'rectangle_zone.dart';

class RangePainter extends CustomPainter {
  final List<RectangleZone> zones;
  final List<Candle> candles;
  final double candleWidth;
  final double topPrice;
  final double bottomPrice;
  final int index;
  final int minIndex;
  final double priceColumnWidth;

  RangePainter({
    required this.zones,
    required this.candles,
    required this.candleWidth,
    required this.topPrice,
    required this.bottomPrice,
    required this.index,
    required this.minIndex,
    required this.priceColumnWidth,
  });

  double dateToX(DateTime date, int index, double candleWidth,
      DateTime lastCandleDate, Size size) {
    int daysFromLastCandle = date.difference(lastCandleDate).inDays;
    double startXForFuture =
        (size.width - priceColumnWidth) + (index * candleWidth);

    double xPositionForDate =
        startXForFuture + (daysFromLastCandle * candleWidth);

    return xPositionForDate;
  }

  double priceToY(double price, double high, double low, Size size) {
    assert(high > low, "ERROR. Lowest must be lower than highest: High: ${high} Low: ${low}");
    double proportion = (price - low) / (high - low);
    double yPosition = (1 - proportion) * size.height;
    return yPosition;
  }

  @override
  void paint(Canvas canvas, Size size) {
    DateTime maxCandleDate = candles
        .map((candle) => candle.date)
        .reduce((a, b) => a.isAfter(b) ? a : b);

    for (final zone in zones) {
      double startX = dateToX(zone.startDate, index, candleWidth, maxCandleDate, size);
      double endX = dateToX(zone.endDate, index, candleWidth, maxCandleDate, size);
      endX = max(endX, startX + candleWidth);
      double startY = priceToY(zone.highPrice, topPrice, bottomPrice, size);
      double endY = priceToY(zone.lowPrice, topPrice, bottomPrice, size);
      startX = min(startX, size.width - PRICE_BAR_WIDTH);
      endX = min(endX, size.width);
      final paintFill = Paint()
        ..color = zone.fillColor
        ..style = PaintingStyle.fill;
      canvas.drawRect(Rect.fromLTRB(startX, startY, endX, endY), paintFill);

      double fontSize = Common()
          .calculateMaxFontSize('x${zone.odds.toStringAsFixed(2)}', FontWeight.bold, endX - startX);
      final textSpan = TextSpan(
        text: 'x${zone.odds.toStringAsFixed(2)}',
        style: TextStyle(
            color: zone.strokeColor,
            fontSize: fontSize,
            fontWeight: FontWeight.bold),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout(minWidth: 0, maxWidth: size.width);
      final textX = startX + (endX - startX - textPainter.width) / 2;
      final textY = startY + (endY - startY - textPainter.height) / 2;
      textPainter.paint(canvas, Offset(textX, textY));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;

  RectangleZone? hit(double x, double y, Size size) {
    DateTime maxCandleDate = candles
        .map((candle) => candle.date)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    for (final zone in zones) {
      if (x >=
              dateToX(
                  zone.startDate, index, candleWidth, maxCandleDate, size) &&
          x <= dateToX(zone.endDate, index, candleWidth, maxCandleDate, size) &&
          y >= priceToY(zone.highPrice, topPrice, bottomPrice, size) &&
          y <= priceToY(zone.lowPrice, topPrice, bottomPrice, size)) {
        return zone;
      }
    }
    return null;
  }
}
