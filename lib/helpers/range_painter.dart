import 'dart:ui';
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
      final oddsTextSpan = TextSpan(
        text: 'x${zone.odds.toStringAsFixed(2)}',
        style: GoogleFonts.montserrat(
            color: zone.strokeColor,
            fontSize: fontSize,
            fontWeight: FontWeight.w300),
      );

      final textPainter = TextPainter(
        text: oddsTextSpan,
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

Future<Future<Object?>> showZoneDialogAnimated(
    BuildContext context,
    RectangleZone zone,
    Rect originRect,
    bool dollarCurrency
    ) async {
  final durationHours = zone.endDate.difference(zone.startDate).inHours.abs();

  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: '',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (_, __, ___) => const SizedBox.shrink(),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final fade = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      final scale = CurvedAnimation(parent: animation, curve: Curves.easeOutBack);

      final screenSize = MediaQuery.of(context).size;
      final originCenter = Offset(
        originRect.left + originRect.width / 2,
        originRect.top + originRect.height / 2,
      );
      final screenCenter = Offset(screenSize.width / 2, screenSize.height / 2);
      final offsetTween = Tween<Offset>(
        begin: originCenter - screenCenter,
        end: Offset.zero,
      );

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).pop(),
        child: Stack(
          children: [
            AnimatedBuilder(
              animation: fade,
              builder: (context, _) => BackdropFilter(
                filter: ImageFilter.blur(
                    sigmaX: 4 * fade.value, sigmaY: 4 * fade.value),
                child: Container(
                  color: Colors.black.withValues(alpha: .5 * fade.value),
                ),
              ),
            ),
            Center(
              child: Transform.translate(
                offset: offsetTween.evaluate(fade),
                child: Transform.scale(
                  scale: scale.value,
                  child: GestureDetector(
                    onTap: () {},
                    child: CustomPaint(
                      size: const Size(250, 260),
                      painter: _ZoneDialogPainter(zone, durationHours, dollarCurrency),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _ZoneDialogPainter extends CustomPainter {
  final RectangleZone zone;
  final int durationHours;
  bool dollarCurrency;

  _ZoneDialogPainter(this.zone, this.durationHours, this.dollarCurrency);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    final fill = Paint()
      ..shader = LinearGradient(
        colors: [
          zone.fillColor.withValues(alpha: .9),
          zone.fillColor.withValues(alpha: .6),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(14)),
      fill,
    );

    final border = Paint()
      ..color = Colors.white.withValues(alpha: .9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(14)),
      border,
    );

    final oddsText = 'x${zone.odds.toStringAsFixed(2)}';
    final oddsSpan = TextSpan(
      text: oddsText,
      style: GoogleFonts.montserrat(
        color: Colors.white,
        fontSize: 60,
        fontWeight: FontWeight.w300,
      ),
    );
    final oddsPainter = TextPainter(
      text: oddsSpan,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width);
    oddsPainter.paint(
      canvas,
      Offset(
        (size.width - oddsPainter.width) / 2,
        (size.height - oddsPainter.height) / 2,
      ),
    );

    final tickerText = zone.ticker;
    final tickerSpan = TextSpan(
      text: tickerText,
      style: GoogleFonts.syncopate(
        color: Colors.white,
        fontSize: 35,
        fontWeight: FontWeight.w300,
      ),
    );
    final tickerPainter = TextPainter(
      text: tickerSpan,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width);
    tickerPainter.paint(
      canvas,
      Offset(
        (size.width - tickerPainter.width) / 2,
        ((size.height - tickerPainter.height) / 2) * 1.5 ,
      ),
    );



    final highSpan = TextSpan(
      text: "${zone.highPrice.toStringAsFixed(2)} ${dollarCurrency ? '\$' : '€'}",
      style: GoogleFonts.syncopate(
        color: Colors.white.withValues(alpha: .85),
        fontSize: 20,
        fontWeight: FontWeight.w300,
      ),
    );
    final lowSpan = TextSpan(
      text: "${zone. lowPrice.toStringAsFixed(2)} ${dollarCurrency ? '\$' : '€'}",
      style: GoogleFonts.syncopate(
        color: Colors.white.withValues(alpha: .85),
        fontSize: 20,
        fontWeight: FontWeight.w300,
      ),
    );

    final highPainter = TextPainter(text: highSpan, textDirection: TextDirection.ltr)..layout();
    final lowPainter = TextPainter(text: lowSpan, textDirection: TextDirection.ltr)..layout();
    final highX = (size.width - highPainter.width) / 2;
    final lowX = (size.width - lowPainter.width) / 2;

    highPainter.paint(canvas, Offset(highX, size.height * 0.004));
    lowPainter.paint(canvas, Offset(lowX, size.height - lowPainter.height - size.height * 0.004));

    final durationSpan = TextSpan(
      text: '← $durationHours h →',
      style: GoogleFonts.montserrat(
        color: Colors.white.withValues(alpha: .85),
        fontSize: 20,
        fontWeight: FontWeight.w300,
      ),
    );
    final durationPainter =
    TextPainter(text: durationSpan, textDirection: TextDirection.ltr)
      ..layout();
    durationPainter.paint(
      canvas,
      Offset((size.width - durationPainter.width) / 2, size.height + 6),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}