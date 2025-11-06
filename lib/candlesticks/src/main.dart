// ignore_for_file: must_be_immutable

import 'dart:math';
import 'package:betrader/candlesticks/src/constant/view_constants.dart';
import '../../helpers/common.dart';
import '../../models/rectangle_zone.dart';
import '../../ui/layout_page.dart';
import '../candlesticks.dart';
import 'models/main_window_indicator.dart';
import 'widgets/mobile_chart.dart';
import 'widgets/desktop_chart.dart';
import 'widgets/toolbar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io' show Platform;

enum ChartAdjust {
  /// Will adjust chart size by max and min value from visible area
  visibleRange,

  /// Will adjust chart size by max and min value from the whole data
  fullRange
}

/// StatefulWidget that holds Chart's State (index of
/// current position and candles width).
class Candlesticks extends StatefulWidget {
  /// The arrangement of the array should be such that
  /// the newest item is in position 0
  final List<Candle> candles;
  final String ticker;
  final MainMenuPageController controller;

  /// This callback calls when the last candle gets visible
  final Future<void> Function()? onLoadMoreCandles;
  /// List of buttons you what to add on top tool bar
  final List<ToolBarAction> actions;
  /// List of indicators to draw
  final List<Indicator>? indicators;
  /// This callback calls when ever user clicks a specific indicator close button (X)
  final void Function(String)? onRemoveIndicator;
  /// How chart price range will be adjusted when moving chart
  final ChartAdjust chartAdjust;
  /// Will zoom buttons be displayed in toolbar
  final bool displayZoomActions;
  /// Custom loading widget
  final Widget? loadingWidget;
  final CandleSticksStyle? style;
  final Function(double scale) onScaleUpdate;
  ValueNotifier<List<RectangleZone>> rectangleZones = ValueNotifier([]);
  final String chartTitle;
  final String iconPath;
  final int extraHours;
  final bool inactiveZone;
  final int finishedIcon;


  Candlesticks({
    super.key,
    required this.ticker,
    required this.candles,
    this.onLoadMoreCandles,
    this.actions = const [],
    this.chartAdjust = ChartAdjust.visibleRange,
    this.displayZoomActions = true,
    this.loadingWidget,
    this.indicators,
    this.onRemoveIndicator,
    this.style,
    required this.onScaleUpdate,
    required this.rectangleZones,
    required this.inactiveZone,
    required this.controller,
    required this.chartTitle,
    required this.iconPath,
    required this.extraHours,
    this.finishedIcon = 0

  });

  @override
  CandlesticksState createState() => CandlesticksState();
}

class CandlesticksState extends State<Candlesticks> {
  /// index of the newest candle to be displayed
  /// changes when user scrolls along the chart
  static int indexMarginRight = 0;
  int index = indexMarginRight;
  double lastX = 0;
  int lastIndex = indexMarginRight;
  String ticker = "";
  /// candleWidth controls the width of the single candles.
  ///  range: [2...10]
  double candleWidth = 6;

  /// true when widget.onLoadMoreCandles is fetching new candles.
  bool isCallingLoadMore = false;

  MainWindowDataContainer? mainWindowDataContainer;

  @override
  void initState() {
    super.initState();
    indexMarginRight = -widget.extraHours;
    index = indexMarginRight;
    lastIndex = indexMarginRight;
    if (widget.candles.isEmpty) {
      return;
    }
    mainWindowDataContainer ??=
        MainWindowDataContainer(widget.indicators ?? [], widget.candles);
  }

  @override
  void didUpdateWidget(covariant Candlesticks oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.candles.isEmpty) {
      return;
    }

    if (oldWidget.extraHours != widget.extraHours) {
      indexMarginRight = -widget.extraHours;
      index = indexMarginRight;
      lastIndex = indexMarginRight;
    }

    if (mainWindowDataContainer == null) {
      mainWindowDataContainer =
          MainWindowDataContainer(widget.indicators ?? [], widget.candles);
    } else {
      final currentIndicators = widget.indicators ?? [];
      final oldIndicators = oldWidget.indicators ?? [];
      if (currentIndicators.length == oldIndicators.length) {
        for (int i = 0; i < currentIndicators.length; i++) {
          if (currentIndicators[i] == oldIndicators[i]) {
            continue;
          } else {
            mainWindowDataContainer =
                MainWindowDataContainer(widget.indicators ?? [], widget.candles);
            return;
          }
        }
      } else {
        mainWindowDataContainer =
            MainWindowDataContainer(widget.indicators ?? [], widget.candles);
        return;
      }
      try {
        mainWindowDataContainer!.tickUpdate(widget.candles);
      } catch (_) {
        mainWindowDataContainer =
            MainWindowDataContainer(widget.indicators ?? [], widget.candles);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final style = widget.style ?? (CandleSticksStyle.dark());
    return Column(
      children: [
        if (widget.displayZoomActions == true || widget.actions.isNotEmpty) ...[
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Spacer(),
              ToolBar(
                color: style.toolBarColor,
                children: [
                  if (widget.displayZoomActions) ...[
                    ToolBarAction(
                      onPressed: () {
                        setState(() {
                          candleWidth -= 2;
                          candleWidth = max(candleWidth, 2);
                        });
                      },
                      child: Icon(
                        Icons.remove,
                        color: style.borderColor,
                      ),
                    ),
                    ToolBarAction(
                      onPressed: () {
                        setState(() {
                          candleWidth += 2;
                          candleWidth = min(candleWidth, 20);
                        });
                      },
                      child: Icon(
                        Icons.add,
                        color: style.borderColor,
                      ),
                    ),
                  ],
                  ...widget.actions
                ],
              ),
            ],
          )
        ],
        if (widget.candles.isEmpty || mainWindowDataContainer == null)
          Expanded(
            child: Center(
              child: widget.loadingWidget ??
                  CircularProgressIndicator(color: style.loadingColor),
            ),
          )
        else
          Expanded(
            child: TweenAnimationBuilder(
              tween: Tween(begin: 6.toDouble(), end: candleWidth),
              duration: const Duration(milliseconds: 120),
              builder: (_, double width, __) {
                if (kIsWeb ||
                    Platform.isMacOS ||
                    Platform.isWindows ||
                    Platform.isLinux) {
                  return DesktopChart(
                    style: style,
                    onRemoveIndicator: widget.onRemoveIndicator,
                    mainWindowDataContainer: mainWindowDataContainer!,
                    chartAdjust: widget.chartAdjust,
                    onScaleUpdate: (double scale) {
                      widget.onScaleUpdate(scale);
                      scale = max(0.90, scale);
                      scale = min(1.1, scale);

                      setState(() {
                        candleWidth *= scale;
                        candleWidth = min(candleWidth, 20);
                        candleWidth = max(candleWidth, 2);
                      });
                    },
                    onPanEnd: () {
                      lastIndex = index;
                    },
                    onHorizontalDragUpdate: (double x) {
                      setState(() {
                        x = x - lastX;
                        index = lastIndex + x ~/ candleWidth;
                        index = max(index, -10);
                        index = min(index, widget.candles.length - 1);
                      });
                    },
                    onPanDown: (double value) {
                      lastX = value;
                      lastIndex = index;
                    },
                    onReachEnd: () {
                      if (isCallingLoadMore == false &&
                          widget.onLoadMoreCandles != null) {
                        isCallingLoadMore = true;
                        widget.onLoadMoreCandles!().then((_) {
                          isCallingLoadMore = false;
                        });
                      }
                    },
                    candleWidth: width,
                    candles: widget.candles,
                    index: index,
                  );
                } else {
                  return MobileChart(
                      style: style,
                      ticker: widget.ticker,
                      onRemoveIndicator: widget.onRemoveIndicator,
                      mainWindowDataContainer: mainWindowDataContainer!,
                      chartAdjust: widget.chartAdjust,
                      onScaleUpdate: (double scale) {
                        scale = max(0.90, scale);
                        scale = min(1.1, scale);
                        widget.onScaleUpdate(scale);
                        setState(() {
                          /// if (blockZooming) BLOCK ZOOMING HERE
                          candleWidth *= scale;
                          candleWidth = min(candleWidth, 20);
                          candleWidth = max(candleWidth, 2);
                        });
                      },
                      onPanEnd: () {
                        lastIndex = index;
                      },
                      onHorizontalDragUpdate: (ScaleUpdateDetails details) {
                        setState(() {
                          var x = details.focalPoint.dx;
                          x = x - lastX;
                          index = lastIndex + x ~/ candleWidth;
                          index = max(index, indexMarginRight);
                          index = min(index, widget.candles.length - 1);
                        });
                      },
                      onPanDown: (double value) {
                        lastX = value;
                        lastIndex = index;
                      },
                      onReachEnd: () {
                        if (isCallingLoadMore == false &&
                            widget.onLoadMoreCandles != null) {
                          isCallingLoadMore = true;
                          widget.onLoadMoreCandles!().then((_) {
                            isCallingLoadMore = false;
                          });
                        }
                      },
                      candleWidth: width,
                      candles: widget.candles,
                      index: index,
                      rectangleZones: widget.rectangleZones,
                      inactiveZone: widget.inactiveZone,
                      chartTitle: widget.chartTitle,
                      iconPath: widget.iconPath,
                      finishedIcon: widget.finishedIcon);
                }
              },
            ),
          ),
      ],
    );
  }
}

//---- S K E L E T O N -----------------------------------

class _PriceBar extends StatelessWidget {
  const _PriceBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF191C20),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(6, (i) {
          return Text(
            '${255 - (i * 5)}.00',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
              fontFamily: 'RobotoMono',
            ),
          );
        }),
      ),
    );
  }
}

class CandlesticksSkeleton extends StatelessWidget {
  const CandlesticksSkeleton({super.key, this.seedPrice = 250});

  final double seedPrice;

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;

    return Container(
      color: const Color(0xFF111315),
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final h = constraints.maxHeight;
          final bool isCompact = h < screenH * 0.7;
          final double topPad = h * 0.08;
          final double bottomPad = isCompact ? h * 0.38 : h * 0.12;


          final candles = Common().generateRandomCandles(30, seedPrice);

          return Stack(
            children: [


              Positioned(
                left: 0,
                right: PRICE_BAR_WIDTH,
                top: topPad,
                bottom: bottomPad,
                child: CustomPaint(
                  painter: _CandleFromModelPainter(candles),
                ),
              ),

              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: PRICE_BAR_WIDTH,
                child: const _PriceBar(),
              ),

              Positioned(
                right: PRICE_BAR_WIDTH*1.5,
                top: topPad,
                bottom: bottomPad,
                child: Icon(Icons.wifi_find_outlined, size: 50, color: Colors.grey.shade800)
              ),

            ],
          );
        },
      ),
    );
  }
}

class _CandleFromModelPainter extends CustomPainter {
  _CandleFromModelPainter(this.candles);

  final List<Candle> candles;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFF111315);
    canvas.drawRect(Offset.zero & size, bg);

    final grid = Paint()
      ..color = const Color(0xFF1E2227)
      ..strokeWidth = 1;
    const cols = 6;
    for (int i = 1; i < cols; i++) {
      final x = size.width * i / cols;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }

    if (candles.isEmpty) return;

    double minLow = candles.map((c) => c.low).reduce(min);
    double maxHigh = candles.map((c) => c.high).reduce(max);

    final range = (maxHigh - minLow).abs();
    final double safeRange = max(range, candles.first.close * 0.02);
    final double center = (maxHigh + minLow) / 2;
    maxHigh = center + safeRange / 2;
    minLow = center - safeRange / 2;

    double yFor(double price) {
      final t = (price - minLow) / (maxHigh - minLow);
      return size.height * (1 - t);
    }

    const double candleW = 6;
    const double gap = 2;
    double x = 0;

    final wickPaint = Paint()
      ..color = Colors.grey.shade800
      ..strokeWidth = 1.2;

    for (int i = candles.length - 1; i >= 0; i--) {
      final c = candles[i];
      final yOpen = yFor(c.open);
      final yClose = yFor(c.close);
      final yHigh = yFor(c.high);
      final yLow = yFor(c.low);

      canvas.drawLine(
        Offset(x + candleW / 2, yHigh),
        Offset(x + candleW / 2, yLow),
        wickPaint,
      );

      final bodyPaint = Paint()
        ..color = ((candles.length - 1 - i) % 2 == 0)
            ? Colors.grey.shade800
            : Colors.grey.shade900;

      final top = min(yOpen, yClose);
      final height = max(2.0, (yOpen - yClose).abs());

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, top, candleW, height),
          const Radius.circular(1.5),
        ),
        bodyPaint,
      );

      x += candleW + gap;
      if (x > size.width) break;
    }
  }

  @override
  bool shouldRepaint(covariant _CandleFromModelPainter oldDelegate) =>
      !identical(oldDelegate.candles, candles);
}