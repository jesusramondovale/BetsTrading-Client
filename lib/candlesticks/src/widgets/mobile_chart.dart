import 'dart:convert';
import 'dart:math';
import 'package:betrader/locale/localized_texts.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../helpers/range_painter.dart';
import '../../../helpers/rectangle_zone.dart';
import '../../../ui/bets_page.dart';
import '../../candlesticks.dart';
import '../constant/view_constants.dart';
import '../models/main_window_indicator.dart';
import '../utils/helper_functions.dart';
import '../widgets/candle_stick_widget.dart';
import '../widgets/mainwindow_indicator_widget.dart';
import '../widgets/price_column.dart';
import '../widgets/time_row.dart';
import '../widgets/top_panel.dart';
import '../widgets/volume_widget.dart';
import 'package:flutter/material.dart';
import 'dash_line.dart';

/// This widget manages gestures
/// Calculates the highest and lowest price of visible candles.
/// Updates right-hand side numbers.
/// And pass values down to [CandleStickWidget].
class MobileChart extends StatefulWidget {

  final Function onScaleUpdate;
  final Function onHorizontalDragUpdate;
  final double candleWidth;
  final List<Candle> candles;
  final int index;
  final MainWindowDataContainer mainWindowDataContainer;
  final ChartAdjust chartAdjust;
  final CandleSticksStyle style;
  final void Function(double) onPanDown;
  final void Function() onPanEnd;
  final void Function(String)? onRemoveIndicator;
  final Function() onReachEnd;
  final List<RectangleZone> rectangleZones;
  final String chartTitle;
  final String iconPath;

  const MobileChart({
    super.key,

    required this.style,
    required this.onScaleUpdate,
    required this.onHorizontalDragUpdate,
    required this.candleWidth,
    required this.candles,
    required this.index,
    required this.chartAdjust,
    required this.onPanDown,
    required this.onPanEnd,
    required this.onReachEnd,
    required this.mainWindowDataContainer,
    required this.onRemoveIndicator,
    required this.rectangleZones,
    required this.chartTitle,
    required this.iconPath,
      });

  @override
  State<MobileChart> createState() => MobileChartState();
}

class MobileChartState extends State<MobileChart> {
  final GlobalKey _customPaintKey = GlobalKey();
  double? longPressX;
  double? longPressY;
  bool showIndicatorNames = false;
  double? manualScaleHigh;
  double? manualScaleLow;
  double scaleX = 1.0, scaleY = 1.0;
  double offsetX = 0.0, offsetY = 0.0;
  ScaleUpdateDetails lastDetails = ScaleUpdateDetails();
  int lastTimestamp = 0;
  bool firstVerticalDragOffset = true;

  @override
  void initState() {
    super.initState();
    _ensureZonesVisible();
  }

  void _ensureZonesVisible() {
    if (widget.rectangleZones.isEmpty) return;

    List<Candle> last30Candles = widget.candles.length > 30
        ? widget.candles.sublist(0, 30)
        : widget.candles;

    double minPrice = min(
        widget.rectangleZones
            .map((zone) => zone.lowPrice)
            .reduce((value, element) => value < element ? value : element),
        last30Candles
            .map((candle) => candle.low)
            .reduce((value, element) => value < element ? value : element));

    double maxPrice = max(
        widget.rectangleZones
            .map((zone) => zone.highPrice)
            .reduce((value, element) => value > element ? value : element),
        last30Candles
            .map((candle) => candle.high)
            .reduce((value, element) => value > element ? value : element));

    setState(() {
      manualScaleHigh = maxPrice * 1;
      manualScaleLow = minPrice * 1;
      scaleX = 1.0;
      offsetY = 0.0;
    });
  }


  @override
  Widget build(BuildContext context) {
    final noBetsText =
        LocalizedStrings.of(context)!.noBetsAvailable ?? "No Bets available!";
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth - PRICE_BAR_WIDTH;
        final double maxHeight = constraints.maxHeight - DATE_BAR_HEIGHT;

        final int candlesStartIndex = max(widget.index, 0);
        final int candlesEndIndex = min(
            maxWidth ~/ widget.candleWidth + widget.index,
            widget.candles.length - 1);

        if (candlesEndIndex == widget.candles.length - 1) {
          Future(() {
            widget.onReachEnd();
          });
        }

        List<Candle> inRangeCandles = widget.candles
            .getRange(candlesStartIndex, max(candlesEndIndex, 0) + 1)
            .toList();

        double candlesHighPrice = 0;
        double candlesLowPrice = 0;
        double tweenBegin;
        double tweenEnd;

        if (manualScaleHigh != null) {
          candlesHighPrice = manualScaleHigh!;
          candlesLowPrice = manualScaleLow!;
        } else if (widget.chartAdjust == ChartAdjust.visibleRange) {
          candlesHighPrice = widget.mainWindowDataContainer.highs
              .getRange(candlesStartIndex, max(candlesEndIndex, 0) + 1)
              .reduce(max);
          candlesLowPrice = widget.mainWindowDataContainer.lows
              .getRange(candlesStartIndex, max(candlesEndIndex, 0) + 1)
              .reduce(min);
        } else if (widget.chartAdjust == ChartAdjust.fullRange) {
          candlesHighPrice = widget.mainWindowDataContainer.highs.reduce(max);
          candlesLowPrice = widget.mainWindowDataContainer.lows.reduce(min);
        }

        double priceRange = candlesHighPrice - candlesLowPrice;
        candlesHighPrice += priceRange;
        candlesLowPrice -= priceRange;

        if (candlesHighPrice == candlesLowPrice) {
          candlesHighPrice += 10;
          candlesLowPrice -= 10;
        }

        double chartHeight = maxHeight * 0.75 - 2 * MAIN_CHART_VERTICAL_PADDING;

        double volumeHigh = inRangeCandles.map((e) => e.volume).reduce(max);

        if (longPressX != null && longPressY != null) {
          longPressX = max(longPressX!, 0);
          longPressX = min(longPressX!, maxWidth);
          longPressY = max(longPressY!, 0);
          longPressY = min(longPressY!, maxHeight);
        }

        if (widget.rectangleZones.isNotEmpty) {
          tweenBegin = min(
              widget.rectangleZones.map((zone) => zone.lowPrice).reduce(
                  (value, element) => value < element ? value : element),
              candlesLowPrice);
          tweenEnd = max(
              widget.rectangleZones.map((zone) => zone.highPrice).reduce(
                  (value, element) => value > element ? value : element),
              candlesHighPrice);
        } else {
          tweenBegin = candlesLowPrice;
          tweenEnd = candlesHighPrice;
        }
        return TweenAnimationBuilder(
          tween: Tween(begin: tweenBegin, end: tweenEnd),
          duration: Duration(milliseconds: manualScaleHigh == null ? 300 : 0),
          builder: (context, double high, _) {
            return TweenAnimationBuilder(
              tween: Tween(begin: candlesLowPrice, end: candlesLowPrice),
              duration:
                  Duration(milliseconds: manualScaleHigh == null ? 300 : 0),
              builder: (context, double low, _) {
                final currentCandle = longPressX == null
                    ? null
                    : widget.candles[min(
                        max(
                            (maxWidth - longPressX!) ~/ widget.candleWidth +
                                widget.index,
                            0),
                        widget.candles.length - 1)];

                return Container(
                  color: widget.style.background,
                  child: Stack(
                    children: [
                      Positioned(
                        top: 10.0,
                        left: 20.0,
                        right: 20.0,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(height: 10),
                            if (widget.iconPath != "null") ...[
                              Image.memory(
                                base64Decode(widget.iconPath),
                                height: 120,
                                width: 120,
                                gaplessPlayback: true,
                              )
                            ] else ...[
                              Text(
                                widget.chartTitle.length > 15
                                    ? widget.chartTitle.substring(0, 15) + '...'
                                    : widget.chartTitle,
                                style: GoogleFonts.openSans(
                                  fontSize: 26.0,
                                  fontWeight: FontWeight.w300,
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white
                                      : Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                              ),
                            ],
                          ],
                        ),
                      ),
                      TimeRow(
                        style: widget.style,
                        indicatorX: longPressX,
                        candles: widget.candles,
                        candleWidth: widget.candleWidth,
                        indicatorTime: currentCandle?.date,
                        index: widget.index,
                      ),
                      Column(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: CustomPaint(
                                    key: _customPaintKey,
                                    painter: RangePainter(
                                        zones: widget.rectangleZones,
                                        candles: widget.candles,
                                        candleWidth: widget.candleWidth,
                                        topPrice: tweenEnd,
                                        bottomPrice: tweenBegin,
                                        index: widget.index,
                                        minIndex: -20,
                                        priceColumnWidth: PRICE_BAR_WIDTH,
                                        noBetsText: noBetsText,
                                        noIcon: widget.iconPath == "null"),
                                  ),
                                ),
                                PriceColumn(
                                  style: widget.style,
                                  low: tweenBegin,
                                  high: tweenEnd,
                                  width: constraints.maxWidth,
                                  chartHeight: chartHeight,
                                  lastCandle: widget.candles[
                                      widget.index < 0 ? 0 : widget.index],
                                  onScale: (delta) {
                                    if (manualScaleHigh == null ||
                                        manualScaleLow == null) {
                                      manualScaleHigh = candlesHighPrice;
                                      manualScaleLow = candlesLowPrice;
                                    }
                                    setState(() {
                                      double deltaPrice = delta /
                                          chartHeight *
                                          (manualScaleHigh! - manualScaleLow!);

                                      double newManualScaleHigh =
                                          manualScaleHigh! + deltaPrice;
                                      double newManualScaleLow =
                                          manualScaleLow! - deltaPrice;

                                      manualScaleHigh = newManualScaleHigh;
                                      manualScaleLow = newManualScaleLow;
                                    });
                                  },
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          border: Border(
                                            right: BorderSide(
                                              color: widget.style.borderColor,
                                              width: 5,
                                            ),
                                          ),
                                        ),
                                        child: AnimatedPadding(
                                          duration:
                                              const Duration(milliseconds: 300),
                                          padding: const EdgeInsets.symmetric(
                                              vertical:
                                                  MAIN_CHART_VERTICAL_PADDING),
                                          child: RepaintBoundary(
                                            child: Stack(
                                              children: [
                                                MainWindowIndicatorWidget(
                                                  indicatorDatas: widget
                                                      .mainWindowDataContainer
                                                      .indicatorComponentData,
                                                  index: widget.index,
                                                  candleWidth:
                                                      widget.candleWidth,
                                                  low: low,
                                                  high: high,
                                                ),
                                                CandleStickWidget(
                                                  candles: widget.candles,
                                                  candleWidth:
                                                      widget.candleWidth,
                                                  index: widget.index,
                                                  high: high,
                                                  low: low,
                                                  bearColor:
                                                      widget.style.primaryBear,
                                                  bullColor:
                                                      widget.style.primaryBull,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      width: PRICE_BAR_WIDTH,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border(
                                        right: BorderSide(
                                          color: widget.style.borderColor,
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 10.0),
                                      child: VolumeWidget(
                                        candles: widget.candles,
                                        barWidth: widget.candleWidth,
                                        index: widget.index,
                                        high:
                                            HelperFunctions.getRoof(volumeHigh),
                                        bearColor: widget.style.secondaryBear,
                                        bullColor: widget.style.secondaryBull,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: PRICE_BAR_WIDTH,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        height: DATE_BAR_HEIGHT,
                                        child: Center(
                                          child: Row(
                                            children: [
                                              Text(
                                                "-${HelperFunctions.addMetricPrefix(HelperFunctions.getRoof(volumeHigh))}",
                                                style: TextStyle(
                                                  color:
                                                      widget.style.borderColor,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(
                            height: DATE_BAR_HEIGHT,
                          ),
                        ],
                      ),
                      if (longPressY != null)
                        Positioned(
                          top: longPressY! - 10,
                          child: Row(
                            children: [
                              DashLine(
                                length: maxWidth,
                                color: widget.style.borderColor,
                                direction: Axis.horizontal,
                                thickness: 0.5,
                              ),
                              Container(
                                color:
                                    widget.style.hoverIndicatorBackgroundColor,
                                width: PRICE_BAR_WIDTH,
                                height: 20,
                                child: Center(
                                  child: Text(
                                    longPressY! < maxHeight * 0.75
                                        ? HelperFunctions.priceToString(high -
                                            (longPressY! -
                                                    MAIN_CHART_VERTICAL_PADDING) /
                                                (maxHeight * 0.75 -
                                                    2 *
                                                        MAIN_CHART_VERTICAL_PADDING) *
                                                (high - low))
                                        : HelperFunctions.addMetricPrefix(
                                            HelperFunctions.getRoof(
                                                    volumeHigh) *
                                                (1 -
                                                    (longPressY! -
                                                            maxHeight * 0.75 -
                                                            10) /
                                                        (maxHeight * 0.25 -
                                                            10))),
                                    style: TextStyle(
                                      color: widget.style.secondaryTextColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (longPressX != null)
                        Positioned(
                          right: (maxWidth - longPressX!) ~/
                                  widget.candleWidth *
                                  widget.candleWidth +
                              PRICE_BAR_WIDTH,
                          child: Container(
                            width: widget.candleWidth,
                            height: maxHeight,
                            color: widget.style.mobileCandleHoverColor,
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(right: 50, bottom: 20),
                        child: GestureDetector(
                          onScaleUpdate: (details) {
                            if (details.scale == 1) {
                              widget.onHorizontalDragUpdate(details);
                              setState(() {
                                if (manualScaleHigh != null) {
                                  double deltaPrice =
                                      details.focalPointDelta.dy /
                                          chartHeight *
                                          (manualScaleHigh! - manualScaleLow!);
                                  for (RectangleZone zone
                                      in widget.rectangleZones) {
                                    zone.centerPrice +=
                                        details.focalPointDelta.dy;
                                  }
                                  manualScaleHigh =
                                      manualScaleHigh! + deltaPrice;
                                  manualScaleLow = manualScaleLow! + deltaPrice;
                                }
                              });
                            }
                            widget
                                .onScaleUpdate(1 + (details.scale - 1) * 0.05);
                          },
                          onScaleStart: (details) {
                            widget.onPanDown(details.localFocalPoint.dx);
                          },
                          onScaleEnd: (details) {
                            widget.onPanEnd();
                          },
                          onLongPressStart: (LongPressStartDetails details) {
                            setState(() {
                              longPressX = details.localPosition.dx;
                              longPressY = details.localPosition.dy;
                            });
                          },
                          onLongPressEnd: (_) {
                            longPressX = null;
                            longPressY = null;
                          },
                          behavior: HitTestBehavior.translucent,
                          onLongPressMoveUpdate:
                              (LongPressMoveUpdateDetails details) {
                            setState(() {
                              longPressX = details.localPosition.dx;
                              longPressY = details.localPosition.dy;
                            });
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 12),
                        child: TopPanel(
                          style: widget.style,
                          onRemoveIndicator: widget.onRemoveIndicator,
                          currentCandle: currentCandle,
                          indicators: widget.mainWindowDataContainer.indicators,
                          toggleIndicatorVisibility: (indicatorName) {
                            setState(() {
                              longPressX = null;
                              longPressY = null;
                            });
                            setState(() {
                              widget.mainWindowDataContainer
                                  .toggleIndicatorVisibility(indicatorName);
                            });
                          },
                          unvisibleIndicators: widget
                              .mainWindowDataContainer.unvisibleIndicators,
                        ),
                      ),
                      GestureDetector(
                        onTapUp: (TapUpDetails details) {
                          final RenderBox renderBox =
                              _customPaintKey.currentContext?.findRenderObject()
                                  as RenderBox;
                          final size = renderBox.size;

                          RectangleZone? zoneClicked = RangePainter(
                                  zones: widget.rectangleZones,
                                  candles: widget.candles,
                                  candleWidth: widget.candleWidth,
                                  topPrice: max(
                                      widget.rectangleZones
                                          .map((zone) => zone.highPrice)
                                          .reduce((value, element) =>
                                              value > element
                                                  ? value
                                                  : element),
                                      candlesHighPrice),
                                  bottomPrice: min(
                                      widget.rectangleZones
                                          .map((zone) => zone.lowPrice)
                                          .reduce((value, element) =>
                                              value < element
                                                  ? value
                                                  : element),
                                      candlesLowPrice),
                                  index: widget.index,
                                  minIndex: -20,
                                  priceColumnWidth: PRICE_BAR_WIDTH,
                                  noBetsText: noBetsText,
                                  noIcon: widget.iconPath == "null")
                              .hit(details.localPosition.dx,
                                  details.localPosition.dy, size);

                          if (zoneClicked != null) {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder:
                                    (context, animation, secondaryAnimation) =>
                                        BetConfirmationPage(
                                  name: widget.chartTitle,
                                  zone: zoneClicked,
                                  currentValue: widget.candles.first.close,
                                  iconPath: widget.iconPath,
                                  onCancel: () {
                                    Navigator.pop(context);
                                  },
                                ),
                                transitionsBuilder: (context, animation,
                                    secondaryAnimation, child) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  );
                                },
                              ),
                            );
                          }
                        },
                      ),
                      Positioned(
                        top: 10.0,
                        right: 10.0,
                        child: IconButton(
                          icon: Icon(
                            Icons.refresh,
                            size: 25,
                          ), // Ícono de ejemplo
                          onPressed: () {
                            _ensureZonesVisible();
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
