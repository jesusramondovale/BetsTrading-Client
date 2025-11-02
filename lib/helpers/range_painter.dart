import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'dart:ui' as ui;
import 'package:betrader/candlesticks/src/constant/view_constants.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../candlesticks/src/models/candle.dart';
import '../ui/bets_page.dart';
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

  Color oddsToColor(double odds, Color fillColor) {
    const double minOdds = 1.0;
    const double maxOdds = 6.0;

    final double clamped =
    odds.clamp(minOdds, maxOdds).toDouble();

    const double minAlpha = 0.75;
    const double maxAlpha = 1.0;

    final double t = (clamped - minOdds) / (maxOdds - minOdds);
    final double alpha = minAlpha + (maxAlpha - minAlpha) * t;

    return fillColor.withValues(alpha: alpha);
  }

  Shader buildZoneShader(Color base, double odds, Rect rect) {
    const double minOdds = 1.0;
    const double maxOdds = 6.0;

    final double t = ((odds.clamp(minOdds, maxOdds) - minOdds) / (maxOdds - minOdds)).toDouble();

    final hsl = HSLColor.fromColor(base);

    // lightness base
    final double baseLight = hsl.lightness;

    final double darkFactor = lerpDouble(0.65, 0.8, t)!;
    final double lightFactor = lerpDouble(1.02, 1.15, t)!;

    final Color startColor = hsl
        .withLightness((baseLight * darkFactor).clamp(0.0, 1.0))
        .toColor();

    final Color endColor = hsl
        .withLightness((baseLight * lightFactor).clamp(0.0, 1.0))
        .toColor();

    return LinearGradient(
      colors: [
        startColor,
        endColor,
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(rect);
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
        ..shader = buildZoneShader(zone.fillColor, zone.odds, Rect.fromLTRB(startX, startY, endX, endY))
        ..color = oddsToColor(zone.odds, zone.fillColor)
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

Future<ui.Image?> _loadImage(String iconPath) async {
  if (iconPath.isEmpty || iconPath == "null") return null;
  try {
    if (iconPath.startsWith('http')) {
      final response = await http.get(Uri.parse(iconPath));
      if (response.statusCode == 200) {
        return _decodeImage(response.bodyBytes);
      }
    } else {
      return _decodeImage(base64Decode(iconPath));
    }
  } catch (_) {}
  return null;
}

Future<ui.Image> _decodeImage(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  return frame.image;
}

Future<Future<Object?>> showZoneDialogAnimated(
    BuildContext context,
    RectangleZone zone,
    String assetName,
    double currentValue,
    String iconPath,
    Rect originRect,
    bool dollarCurrency,
    { bool fromInactive = false }
    ) async {
  final durationHours = zone.endDate.difference(zone.startDate).inHours.abs();
  final ui.Image? image = await _loadImage(iconPath);
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
                    onTap: () {
                      if (!fromInactive) {
                        Common().vibrate();
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (_, __, ___) =>
                                BetConfirmationPage(
                                  name: assetName,
                                  zone: zone,
                                  currentValue: currentValue,
                                  iconPath: iconPath,
                                  onCancel: () {
                                    Common().vibrate();
                                    Navigator.pop(context);
                                  },
                                ),
                            transitionsBuilder: (_, animation, __, child) =>
                                FadeTransition(
                                    opacity: animation, child: child),
                          ),
                        );
                      }
                    },
                    child: CustomPaint(
                      size: const Size(250, 260),
                      painter: _ZoneDialogPainter(zone, durationHours, dollarCurrency, image),
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
  final bool dollarCurrency;
  final ui.Image? image;

  _ZoneDialogPainter(this.zone, this.durationHours, this.dollarCurrency, this.image);

  String _formatPrice(double value, bool dollarCurrency) {
    final thresholds = {
      5.0: 2,
      1.0: 3,
      0.1: 4,
      0.001: 5,
      0.000001: 8,
    };

    int decimals = 10;
    for (final entry in thresholds.entries) {
      if (value >= entry.key) {
        decimals = entry.value;
        break;
      }
    }

    String formatted = double.parse(value.toStringAsFixed(decimals)).toString();
    return "$formatted ${dollarCurrency ? '\$' : '€'}";
  }

  String _formatDate(DateTime date) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${date.year}-${twoDigits(date.month)}-${twoDigits(date.day)} @ ${twoDigits(date.hour)}:${twoDigits(date.minute)} UTC";
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    final fill = Paint()
      ..shader = LinearGradient(
        colors: [
          HSLColor.fromColor(zone.fillColor).withLightness(
            (HSLColor.fromColor(zone.fillColor).lightness * 0.75).clamp(0.0, 1.0),
          ).toColor(),
          HSLColor.fromColor(zone.fillColor).withLightness(
            (HSLColor.fromColor(zone.fillColor).lightness * 1.1).clamp(0.0, 1.0),
          ).toColor(),
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
        (size.height - oddsPainter.height) * 0.7,
      ),
    );

    if (image != null) {
      final double iconSize = 100;
      final double x = (size.width - iconSize) / 2;
      final double y = (size.height - iconSize) * 0.2;
      final rectDst = Rect.fromLTWH(x, y, iconSize, iconSize);

      final double srcAspect = image!.width / image!.height;
      const double dstAspect = 1.0;
      Rect srcRect;

      if (srcAspect > dstAspect) {
        final double newWidth = image!.height * dstAspect;
        final double xOffset = (image!.width - newWidth) / 2;
        srcRect = Rect.fromLTWH(xOffset, 0, newWidth, image!.height.toDouble());
      } else {
        final double newHeight = image!.width / dstAspect;
        final double yOffset = (image!.height - newHeight) / 2;
        srcRect = Rect.fromLTWH(0, yOffset, image!.width.toDouble(), newHeight);
      }

      canvas.save();
      canvas.clipRRect(RRect.fromRectAndRadius(rectDst, const Radius.circular(20)));
      canvas.drawImageRect(
        image!,
        srcRect,
        rectDst,
        Paint(),
      );
      canvas.restore();
    }



    final highSpan = TextSpan(
      children: [
        TextSpan(
          text: String.fromCharCode(FontAwesomeIcons.chevronUp.codePoint),
          style: TextStyle(
            fontFamily: FontAwesomeIcons.chevronUp.fontFamily,
            package: FontAwesomeIcons.chevronUp.fontPackage,
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        const TextSpan(text: '  '),
        TextSpan(
          text: _formatPrice(zone.highPrice, dollarCurrency),
          style: GoogleFonts.figtree(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w300,
          ),
        ),
        const TextSpan(text: '  '),
        TextSpan(
          text: String.fromCharCode(FontAwesomeIcons.chevronUp.codePoint),
          style: TextStyle(
            fontFamily: FontAwesomeIcons.chevronUp.fontFamily,
            package: FontAwesomeIcons.chevronUp.fontPackage,
            color: Colors.white,
            fontSize: 16,
          ),
        ),
      ],
    );
    final lowSpan = TextSpan(
      children: [

        TextSpan(
          text: String.fromCharCode(FontAwesomeIcons.chevronDown.codePoint),
          style: TextStyle(
            fontFamily: FontAwesomeIcons.chevronDown.fontFamily,
            package: FontAwesomeIcons.chevronDown.fontPackage,
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        const TextSpan(text: '  '),
        TextSpan(
          text: _formatPrice(zone.lowPrice, dollarCurrency),
          style: GoogleFonts.figtree(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w300,
          ),
        ),
        const TextSpan(text: '  '),
        TextSpan(
          text: String.fromCharCode(FontAwesomeIcons.chevronDown.codePoint),
          style: TextStyle(
            fontFamily: FontAwesomeIcons.chevronDown.fontFamily,
            package: FontAwesomeIcons.chevronDown.fontPackage,
            color: Colors.white,
            fontSize: 16,
          ),
        ),
      ],

    );

    final highPainter = TextPainter(text: highSpan, textDirection: TextDirection.ltr)..layout();
    final lowPainter = TextPainter(text: lowSpan, textDirection: TextDirection.ltr)..layout();
    final highX = (size.width - highPainter.width) / 2;
    final lowX = (size.width - lowPainter.width) / 2;

    highPainter.paint(canvas, Offset(highX, size.height * 0.004));
    lowPainter.paint(canvas, Offset(lowX, size.height - lowPainter.height - size.height * 0.004));

    final startDateSpan = TextSpan(
      text: _formatDate(zone.startDate),
      style: GoogleFonts.montserrat(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w300,
      ),
    );
    final startDatePainter =
    TextPainter(text: startDateSpan, textDirection: TextDirection.ltr)
      ..layout();

    canvas.save();
    canvas.translate(
      size.width * 0.05,
      size.height / 2,
    );
    canvas.rotate(90 * 3.1415926535 / 180);
    startDatePainter.paint(
      canvas,
      Offset(-startDatePainter.width / 2, -startDatePainter.height / 2),
    );
    canvas.restore();

    final endDateSpan = TextSpan(
      text: _formatDate(zone.endDate),
      style: GoogleFonts.montserrat(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w300,
      ),
    );
    final endDatePainter =
    TextPainter(text: endDateSpan, textDirection: TextDirection.ltr)
      ..layout();

    canvas.save();
    canvas.translate(
      size.width * 0.95,
      size.height / 2,
    );
    canvas.rotate(-90 * 3.1415926535 / 180);
    endDatePainter.paint(
      canvas,
      Offset(-endDatePainter.width / 2, -endDatePainter.height / 2),
    );
    canvas.restore();

    final durationSpan = TextSpan(
      text: '← $durationHours h →',
      style: GoogleFonts.montserrat(
        color: Colors.white,
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

    final tickerText = zone.ticker.split('.')[0];
    final tickerSpan = TextSpan(
      text: tickerText,
      style: GoogleFonts.syncopate(
        color: Colors.white,
        fontSize: 26,
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
        ((size.height - tickerPainter.height) / 2) * 1.7 ,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
