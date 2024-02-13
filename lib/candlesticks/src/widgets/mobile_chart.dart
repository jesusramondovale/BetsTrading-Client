import 'dart:math';

import '../../../helpers/common.dart';
import '../../../helpers/range_painter.dart';
import '../../../helpers/rectangle_zone.dart';
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
  /// onScaleUpdate callback
  /// called when user scales chart using buttons or scale gesture
  final Function onScaleUpdate;

  /// onHorizontalDragUpdate
  /// callback calls when user scrolls horizontally along the chart
  final Function onHorizontalDragUpdate;

  /// candleWidth controls the width of the single candles.
  /// range: [2...10]
  final double candleWidth;

  /// list of all candles to display in chart
  final List<Candle> candles;

  /// index of the newest candle to be displayed
  /// changes when user scrolls along the chart
  final int index;

  /// holds main window indicators data and high and low prices.
  final MainWindowDataContainer mainWindowDataContainer;

  /// How chart price range will be adjusted when moving chart
  final ChartAdjust chartAdjust;

  final CandleSticksStyle style;

  final void Function(double) onPanDown;
  final void Function() onPanEnd;

  final void Function(String)? onRemoveIndicator;

  final Function() onReachEnd;

  final List<RectangleZone> rectangleZones;

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
  });

  @override
  State<MobileChart> createState() => _MobileChartState();
}

class _MobileChartState extends State<MobileChart> {
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
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // determine charts width and height
        final double maxWidth = constraints.maxWidth - PRICE_BAR_WIDTH;
        final double maxHeight = constraints.maxHeight - DATE_BAR_HEIGHT;

        // visible candles start and end indexes
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

        if (candlesHighPrice == candlesLowPrice) {
          candlesHighPrice += 10;
          candlesLowPrice -= 10;
        }

        // calculate priceScale
        double chartHeight = maxHeight * 0.75 - 2 * MAIN_CHART_VERTICAL_PADDING;

        // calculate highest volume
        double volumeHigh = inRangeCandles.map((e) => e.volume).reduce(max);

        if (longPressX != null && longPressY != null) {
          longPressX = max(longPressX!, 0);
          longPressX = min(longPressX!, maxWidth);
          longPressY = max(longPressY!, 0);
          longPressY = min(longPressY!, maxHeight);
        }

        return TweenAnimationBuilder(
          tween: Tween(begin: candlesHighPrice, end: candlesHighPrice),
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
                                        topPrice: candlesHighPrice,
                                        bottomPrice: candlesLowPrice,
                                        index: widget.index,
                                        minIndex: -20,
                                        priceColumnWidth: PRICE_BAR_WIDTH),
                                  ),
                                ),
                                PriceColumn(
                                  style: widget.style,
                                  low: candlesLowPrice,
                                  high: candlesHighPrice,
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
                                              width: 1,
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
                      longPressY != null
                          ? Positioned(
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
                                    color: widget
                                        .style.hoverIndicatorBackgroundColor,
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
                                                                maxHeight *
                                                                    0.75 -
                                                                10) /
                                                            (maxHeight * 0.25 -
                                                                10))),
                                        style: TextStyle(
                                          color:
                                              widget.style.secondaryTextColor,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Container(),
                      longPressX != null
                          ? Positioned(
                              right: (maxWidth - longPressX!) ~/
                                      widget.candleWidth *
                                      widget.candleWidth +
                                  PRICE_BAR_WIDTH,
                              child: Container(
                                width: widget.candleWidth,
                                height: maxHeight,
                                color: widget.style.mobileCandleHoverColor,
                              ),
                            )
                          : Container(),
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
                            widget.onScaleUpdate(details.scale);
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
                      Positioned(
                        right: 0,
                        bottom: 0,
                        width: PRICE_BAR_WIDTH,
                        height: 20,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            backgroundColor:
                                widget.style.hoverIndicatorBackgroundColor,
                          ),
                          onPressed: manualScaleHigh == null
                              ? null
                              : () {
                                  setState(() {
                                    manualScaleHigh = null;
                                    manualScaleLow = null;
                                  });
                                },
                          child: Text(
                            "Auto",
                            style: TextStyle(
                              color: widget.style.secondaryTextColor,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(onTapUp: (TapUpDetails details) {
                        final RenderBox renderBox =
                            _customPaintKey.currentContext?.findRenderObject()
                                as RenderBox;
                        final size = renderBox.size;

                        RectangleZone? zoneClicked = RangePainter(
                                zones: widget.rectangleZones,
                                candles: widget.candles,
                                candleWidth: widget.candleWidth,
                                topPrice: candlesHighPrice,
                                bottomPrice: candlesLowPrice,
                                index: widget.index,
                                minIndex: -20,
                                priceColumnWidth: PRICE_BAR_WIDTH)
                            .hit(details.localPosition.dx,
                                details.localPosition.dy, size);

                        if (zoneClicked != null) {
                          Common().unimplementedAction(
                              "newBet() on ${zoneClicked.oddsLabel}", context);
                        }
                      }),
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
