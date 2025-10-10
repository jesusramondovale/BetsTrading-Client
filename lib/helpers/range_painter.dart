
import 'package:betrader/candlesticks/src/constant/view_constants.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../candlesticks/src/models/candle.dart';
import 'common.dart';
import '../models/rectangle_zone.dart';

class RangePainter extends CustomPainter {
  final ValueNotifier<List<RectangleZone>> zones;
  final List<Candle> candles;
  final double candleWidth;
  final double topPrice;
  final double bottomPrice;
  final int index;
  final double priceColumnWidth;
  final String noBetsText;
  final bool noIcon;
  final int timeframe ;

  RangePainter( {
    required this.zones,
    required this.candles,
    required this.candleWidth,
    required this.topPrice,
    required this.bottomPrice,
    required this.index,
    required this.priceColumnWidth,
    required this.noBetsText,
    required this.noIcon,
    this.timeframe = 1,
  }) : super(repaint: zones);

  double hoursToX(DateTime date, int index, double candleWidth, DateTime lastCandleDate, Size size, int timeframe) {
    int hoursFromLastCandle = date.difference(lastCandleDate).inHours;
    double candleOffset = hoursFromLastCandle / timeframe;
    double startXForFuture = (size.width - priceColumnWidth) + ((index-1) * candleWidth);
    double xPositionForDate = startXForFuture + (candleOffset * candleWidth);
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
    if (zones.value.isEmpty){

      final textSpan = TextSpan(
        text: this.noBetsText,
        style: GoogleFonts.montserrat(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w300),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout(minWidth: 0, maxWidth: size.width);
      final double offsetX = (size.width - textPainter.width) / 2;
      final double offsetY = size.height * (noIcon ? 0.12 : 0.3);

      textPainter.paint(canvas, Offset(offsetX , offsetY));

    }

    DateTime maxCandleDate = candles
        .map((candle) => candle.date)
        .reduce((a, b) => a.isAfter(b) ? a : b);

    for (final zone in zones.value) {
      double startX = hoursToX(zone.startDate, index, candleWidth, maxCandleDate, size, timeframe);
      double endX = hoursToX(zone.endDate, index, candleWidth, maxCandleDate, size, timeframe);

      final durationHours = zone.endDate.difference(zone.startDate).inHours.abs();
      final widthFactor = (durationHours / timeframe).clamp(1, double.infinity);

      endX = startX + widthFactor * candleWidth;
      startX = startX.clamp(0.0, size.width - PRICE_BAR_WIDTH);
      endX = endX.clamp(0.0, size.width);

      double startY = priceToY(zone.highPrice, topPrice, bottomPrice, size);
      double endY = priceToY(zone.lowPrice, topPrice, bottomPrice, size);

      final paintFill = Paint()
        ..color = zone.fillColor.withValues(alpha: 0.6)
        ..style = PaintingStyle.fill;
      canvas.drawRect(Rect.fromLTRB(startX, startY, endX, endY), paintFill);

      final paintStroke = Paint()
        ..color = Colors.white.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5;
      canvas.drawRect(Rect.fromLTRB(startX, startY, endX, endY), paintStroke);

      double fontSize = Common()
          .calculateMaxFontSize('x${zone.odds.toStringAsFixed(2)}', FontWeight.bold, endX - startX);
      final textSpan = TextSpan(
        text: 'x${zone.odds.toStringAsFixed(2)}',
        style: GoogleFonts.montserrat(
            color: zone.strokeColor,
            fontSize: fontSize,
            fontWeight: FontWeight.w300),
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
    for (final zone in zones.value) {
      if (x >=
          hoursToX(
                  zone.startDate, index, candleWidth, maxCandleDate, size, timeframe) &&
          x <= hoursToX(zone.endDate, index, candleWidth, maxCandleDate, size, timeframe ) &&
          y >= priceToY(zone.highPrice, topPrice, bottomPrice, size) &&
          y <= priceToY(zone.lowPrice, topPrice, bottomPrice, size)) {
        return zone;
      }
    }
    return null;
  }
}
