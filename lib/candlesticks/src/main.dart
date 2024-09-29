// ignore_for_file: must_be_immutable

import 'dart:math';
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

  List<RectangleZone> rectangleZones = [];

  final String chartTitle;

  final String iconPath;

  final int extraDays;

  final bool inactiveZone;


  Candlesticks({
    super.key,
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
    required this.extraDays,

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

  /// candleWidth controls the width of the single candles.
  ///  range: [2...10]
  double candleWidth = 6;

  /// true when widget.onLoadMoreCandles is fetching new candles.
  bool isCallingLoadMore = false;

  MainWindowDataContainer? mainWindowDataContainer;

  @override
  void initState() {
    super.initState();
    indexMarginRight = -5-widget.extraDays;
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
            mainWindowDataContainer = MainWindowDataContainer(
                widget.indicators ?? [], widget.candles);
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
    final style = widget.style ??
        (Theme.of(context).brightness == Brightness.dark
            ? CandleSticksStyle.dark()
            : CandleSticksStyle.light());
    return Column(
      children: [
        if (widget.displayZoomActions == true || widget.actions.isNotEmpty) ...[
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
                      iconPath: widget.iconPath,);
                }
              },
            ),
          ),
      ],
    );
  }
}
