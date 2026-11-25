import 'dart:math';
import 'package:betrader/candlesticks/src/widgets/vertical_grid_painter.dart';
import 'package:betrader/locale/localized_texts.dart';
import 'package:flutter/foundation.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/bets_service.dart';
import '../../../helpers/common.dart';
import '../../../helpers/range_painter.dart';
import '../../../models/rectangle_zone.dart';
import '../../../services/bet_zone_refresher.dart';
import '../../../ui/bets_page.dart';
import '../../../ui/exact_price_view.dart';
import '../../../ui/layout_page.dart';
import '../../candlesticks.dart';
import '../constant/view_constants.dart';
import '../models/main_window_indicator.dart';
import '../utils/helper_functions.dart';
import '../widgets/candle_stick_widget.dart';
import '../widgets/mainwindow_indicator_widget.dart';
import '../widgets/price_column.dart';
import '../widgets/top_panel.dart';
import '../widgets/volume_widget.dart';
import 'package:flutter/material.dart';

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
  final ValueNotifier<List<RectangleZone>> rectangleZones;
  final String chartTitle;
  final String ticker;
  final String iconPath;
  final bool inactiveZone;
  final int finishedIcon;
  final MainMenuPageController menuController;

  /// Cambia cada vez que hay que reencuadrar las zonas (zoom/desplazamiento).
  final int fitRequest;
  final VoidCallback? onRequestFit;

  const MobileChart(
      {super.key,
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
        required this.ticker,
        required this.iconPath,
        required this.inactiveZone,
        this.finishedIcon = 0,
        required this.menuController,
        this.fitRequest = 0,
        this.onRequestFit,
      });

  @override
  State<MobileChart> createState() => MobileChartState();
}

class MobileChartState extends State<MobileChart> with WidgetsBindingObserver {
  final GlobalKey _customPaintKey = GlobalKey();
  final options = ['1H', '2H', '4H', '1D'];
  late String _currentRangeTime = "1H";
  int _currentIndex = 0;
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
  int? lastCandleIndex;
  bool _dollarCurrency = false;
  bool _isZooming = false; // Rastrea si estamos haciendo zoom horizontal
  double _lastChartWidth = 0;

  void _syncUiTimeframeFromManager() {
    final v = TimeframeManager.current.value;
    switch (v) {
      case 2:
        _currentIndex = 1;
        _currentRangeTime = '2H';
        break;
      case 4:
        _currentIndex = 2;
        _currentRangeTime = '4H';
        break;
      case 24:
        _currentIndex = 3;
        _currentRangeTime = '1D';
        break;
      default:
        _currentIndex = 0;
        _currentRangeTime = '1H';
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _syncUiTimeframeFromManager();
    _initAsync();
  }

  Future<void> _initAsync() async {
    final prefs = await SharedPreferences.getInstance();
    final bool dollarCurrency = prefs.getBool('dollarCurrency') ?? false;
    _dollarCurrency = dollarCurrency;

    if (!widget.inactiveZone) {
      _fetchZones(_dollarCurrency ? 'USD' : 'EUR');
      BetZoneRefresher().start(
        widget.ticker,
        (_dollarCurrency ? 'USD' : 'EUR'),
        widget.rectangleZones,
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _fitVertical());
  }

  @override
  void didUpdateWidget(covariant MobileChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fitRequest != widget.fitRequest) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitVertical());
    }
  }

  void _openZone(RectangleZone zone) {
    if (widget.inactiveZone) return;

    Common().vibrate();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => BetConfirmationPage(
          name: widget.chartTitle,
          menuController: widget.menuController,
          chartTimeframeHours: _mapTimeframe(_currentRangeTime),
          zone: zone,
          currentValue: widget.candles.first.close,
          iconPath: widget.iconPath,
        ),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  /// Encaja el eje de precios en las zonas y las velas que quedan a la vista,
  /// dejando margen para que los rectángulos no queden estirados.
  void _fitVertical() {
    if (!mounted || widget.candles.isEmpty) return;

    final zones = widget.rectangleZones.value;
    final double chartWidth = _lastChartWidth > 0
        ? _lastChartWidth
        : MediaQuery.of(context).size.width - priceBarWidth;

    final int start = min(max(widget.index, 0), widget.candles.length - 1);
    final int visibleSlots =
        max(1, (chartWidth / widget.candleWidth).floor() + widget.index.clamp(-100000, 0));
    final int end = min(start + visibleSlots, widget.candles.length - 1);
    final visible = widget.candles.getRange(start, end + 1);

    double high = visible.map((c) => c.high).reduce(max);
    double low = visible.map((c) => c.low).reduce(min);
    final DateTime lastCandleDate = widget.candles
        .map((c) => c.date)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    final int timeframe = _mapTimeframe(_currentRangeTime);
    final double futureOriginX =
        chartWidth + (widget.index - 2) * widget.candleWidth;
    double? zonesHigh;
    double? zonesLow;
    for (final zone in zones) {
      final double startX = futureOriginX +
          zone.startDate.difference(lastCandleDate).inHours /
              timeframe *
              widget.candleWidth;
      final double durationSlots =
          max(1.0, zone.endDate.difference(zone.startDate).inHours.abs() / timeframe);
      final double endX = startX + durationSlots * widget.candleWidth;
      if (endX <= 0 || startX >= chartWidth) continue;
      zonesHigh = max(zonesHigh ?? zone.highPrice, zone.highPrice);
      zonesLow = min(zonesLow ?? zone.lowPrice, zone.lowPrice);
    }

    if (zonesHigh != null && zonesLow != null) {
      final double currentPrice = widget.candles.first.close;
      final double bandHigh = max(zonesHigh, currentPrice);
      final double bandLow = min(zonesLow, currentPrice);
      final double bandRange = max(bandHigh - bandLow, 1e-9);
      // Las zonas deben ocupar al menos ~1/3 de la altura tras el margen.
      final double maxRange = bandRange * 1.6;

      high = max(high, bandHigh);
      low = min(low, bandLow);
      if (high - low > maxRange) {
        final double extraUp = high - bandHigh;
        final double extraDown = bandLow - low;
        final double budget = maxRange - bandRange;
        final double totalExtra = extraUp + extraDown;
        high = bandHigh + budget * extraUp / totalExtra;
        low = bandLow - budget * extraDown / totalExtra;
      }
    }

    final double reference = widget.candles.first.close.abs();
    final double minRange = max(reference * 0.004, 1e-9);
    if (high - low < minRange) {
      final double center = (high + low) / 2;
      high = center + minRange / 2;
      low = center - minRange / 2;
    }
    final double range = high - low;
    final double fittedHigh = high + range * 0.45;
    final double fittedLow = low - range * 0.4;
    // 20% menos de zoom vertical al abrir: el rango visible es 1/0.80 del ajustado.
    const double openVerticalZoom = 0.80;
    final double center = (fittedHigh + fittedLow) / 2;
    final double halfSpan =
        (fittedHigh - fittedLow) / 2 / openVerticalZoom;

    setState(() {
      manualScaleHigh = center + halfSpan;
      manualScaleLow = center - halfSpan;
    });
  }

  void _fetchZones(String currency) async {
    try {
      final tf = _mapTimeframe(_currentRangeTime);
      final zones = await BetsService()
          .fetchBetZones(widget.ticker, tf, null, currency: currency);
      final candles =
      await BetsService().fetchCandles(widget.ticker, tf, currency);
      final rectangleZones = Common().getRectangleZonesFromBetZones(
          zones, candles.isNotEmpty ? candles.first.close : 0.0);
      widget.rectangleZones.value = rectangleZones;
    } catch (e) {
      if (kDebugMode) {
        print("Error loading initial bet zones: $e");
      }
    }
  }

  int _mapTimeframe(String tf) {
    switch (tf) {
      case '1H':
        return 1;
      case '2H':
        return 2;
      case '4H':
        return 4;
      case '1D':
        return 24;
      default:
        return 1;
    }
  }

  Future<void> _reloadData(int timeframe, String currency) async {
    try {
      final zones =
      await BetsService().fetchBetZones(widget.ticker, timeframe, null, currency: currency);
      final candles =
      await BetsService().fetchCandles(widget.ticker, timeframe, currency);
      final rectangleZones = Common().getRectangleZonesFromBetZones(
        zones,
        candles.isNotEmpty ? candles.first.close : 0.0,
      );

      setState(() {
        widget.rectangleZones.value = rectangleZones;
        widget.candles
          ..clear()
          ..addAll(candles);
      });
    } catch (e) {
      if (kDebugMode) {
        print("Error recharging candles with timeframe=$timeframe: $e");
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final noBetsText = LocalizedStrings.of(context)!.get('noBetsAvailable') ?? "No Bets available!";
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth =
            constraints.maxWidth - priceBarWidth + widget.candleWidth * 2;
        final double chartWidth = constraints.maxWidth - priceBarWidth;
        _lastChartWidth = chartWidth;
        final double maxHeight = constraints.maxHeight - dateBarHeight;

        final int candlesStartIndex = widget.candles.isEmpty
            ? 0
            : min(max(widget.index, 0), widget.candles.length - 1);

        final int candlesEndIndex = widget.candles.isEmpty
            ? 0
            : min(
          (maxWidth ~/ widget.candleWidth) + candlesStartIndex,
          widget.candles.length - 1,
        );

        List<Candle> inRangeCandles = widget.candles.isEmpty
            ? []
            : widget.candles
            .getRange(candlesStartIndex, candlesEndIndex + 1)
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

        if (manualScaleHigh == null) {
          final double priceRange = candlesHighPrice - candlesLowPrice;
          candlesHighPrice += priceRange * 0.1;
          candlesLowPrice -= priceRange * 0.1;
        }

        if (!candlesHighPrice.isFinite ||
            !candlesLowPrice.isFinite ||
            candlesHighPrice <= candlesLowPrice) {
          final double basis = candlesHighPrice.isFinite
              ? candlesHighPrice.abs()
              : 1;
          final double pad = max(basis * 0.01, 1e-6);
          final double mid = (candlesHighPrice.isFinite && candlesLowPrice.isFinite)
              ? (candlesHighPrice + candlesLowPrice) / 2
              : 0;
          candlesHighPrice = mid + pad;
          candlesLowPrice = mid - pad;
        }

        double chartHeight = maxHeight * 0.75 - mainChartVerticalPadding;

        double volumeHigh = inRangeCandles.isEmpty
            ? 1
            : inRangeCandles.map((e) => e.volume).reduce(max);
        if (!volumeHigh.isFinite || volumeHigh <= 0) volumeHigh = 1;

        if (longPressX != null && longPressY != null) {
          longPressX = max(longPressX!, 0);
          longPressX = min(longPressX!, maxWidth);
          longPressY = max(longPressY!, 0);
          longPressY = min(longPressY!, maxHeight);
        }

        if (manualScaleHigh != null) {
          tweenBegin = candlesLowPrice;
          tweenEnd = candlesHighPrice;
        } else if (widget.rectangleZones.value.isNotEmpty) {
          tweenBegin = min(
              widget.rectangleZones.value.map((zone) => zone.lowPrice).reduce(
                      (value, element) => value < element ? value : element),
              candlesLowPrice);
          tweenEnd = max(
              widget.rectangleZones.value.map((zone) => zone.highPrice).reduce(
                      (value, element) => value > element ? value : element),
              candlesHighPrice);
          final double zonesPad = (tweenEnd - tweenBegin) * 0.04;
          tweenBegin -= zonesPad;
          tweenEnd += zonesPad;
        } else {
          tweenBegin = candlesLowPrice;
          tweenEnd = candlesHighPrice;
        }
        if (!tweenEnd.isFinite ||
            !tweenBegin.isFinite ||
            tweenEnd <= tweenBegin) {
          final double pad = 1e-6;
          tweenEnd = (tweenEnd.isFinite ? tweenEnd : 0) + pad;
          tweenBegin = (tweenBegin.isFinite ? tweenBegin : 0) - pad;
        }
        final double painterBottomPrice = tweenBegin;
        final double painterTopPrice = tweenEnd;
        RangePainter buildHitTestPainter() => RangePainter(
            zones: widget.rectangleZones,
            candles: widget.candles,
            candleWidth: widget.candleWidth,
            topPrice: painterTopPrice,
            bottomPrice: painterBottomPrice,
            index: widget.index,
            timeframe: _mapTimeframe(_currentRangeTime),
            priceColumnWidth: priceBarWidth,
            noBetsText: noBetsText,
            noIcon: widget.iconPath == "null",
            finishedIcon: widget.finishedIcon
        );

        RectangleZone? hitTestZone(Offset localPosition, Size size) {
          return buildHitTestPainter()
              .hit(localPosition.dx, localPosition.dy, size);
        }

        return TweenAnimationBuilder(
          tween: Tween(begin: tweenEnd, end: tweenEnd),
          duration: const Duration(milliseconds: 0),
          builder: (context, double high, _) {
            return TweenAnimationBuilder(
              tween: Tween(begin: tweenBegin, end: tweenBegin),
              duration: const Duration(milliseconds: 0),
              builder: (context, double low, _) {
                final currentCandle =
                (longPressX == null || widget.candles.isEmpty)
                    ? null
                    : widget.candles[min(
                  max(
                    (chartWidth - longPressX!) ~/ widget.candleWidth +
                        widget.index,
                    0,
                  ),
                  widget.candles.length - 1,
                )];

                return Container(
                  color: widget.style.background,
                  child: Stack(children: [
                    Column(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Stack(
                            children: [
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
                                        padding: const EdgeInsets.only(
                                            bottom: mainChartVerticalPadding),
                                        child: RepaintBoundary(
                                          child: Stack(
                                            children: [
                                              Positioned.fill(
                                                child: CustomPaint(
                                                  painter: GreyFixedGridPainter(
                                                    targetSpacingPx:
                                                    MediaQuery.of(context)
                                                        .size
                                                        .width /
                                                        9,
                                                    candleWidth:
                                                    widget.candleWidth,
                                                    index: widget.index,
                                                    high: high,
                                                    low: low,
                                                  ),
                                                ),
                                              ),
                                              MainWindowIndicatorWidget(
                                                indicatorDatas: widget
                                                    .mainWindowDataContainer
                                                    .indicatorComponentData,
                                                index: widget.index,
                                                candleWidth: widget.candleWidth,
                                                low: low,
                                                high: high,
                                              ),
                                              CandleStickWidget(
                                                candles: widget.candles,
                                                candleWidth: widget.candleWidth,
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
                                    width: priceBarWidth,
                                  ),
                                ],
                              ),
                              Positioned.fill(
                                child: LayoutBuilder(
                                  builder: (context, boxConstraints) {
                                    final double painterTop = high;
                                    final double painterBottom = low;
                                    final int painterTimeframe =
                                    _mapTimeframe(_currentRangeTime);

                                    return CustomPaint(
                                      key: _customPaintKey,
                                      painter: RangePainter(
                                          zones: widget.rectangleZones,
                                          candles: widget.candles,
                                          candleWidth: widget.candleWidth,
                                          topPrice: painterTop,
                                          bottomPrice: painterBottom,
                                          index: widget.index - 1,
                                          timeframe: painterTimeframe,
                                          priceColumnWidth: priceBarWidth,
                                          noBetsText: noBetsText,
                                          noIcon: widget.iconPath == "null",
                                          finishedIcon: widget.finishedIcon
                                      ),
                                    );
                                  },
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: SizedBox(
                                  width: priceBarWidth,
                                  child: PriceColumn(
                                    style: widget.style,
                                    low: low,
                                    high: high,
                                    width: priceBarWidth,
                                    paintCurrency: (
                                        Common().isTickerForex(widget.ticker)
                                            ? 0
                                            : (_dollarCurrency ? 2 : 1) ),
                                    chartHeight: chartHeight,
                                    plotTopPadding: 0,
                                    lastCandle: widget.candles[min(
                                        max(widget.index, 0),
                                        widget.candles.length - 1)],
                                    onScale: (delta) {
                                      if (manualScaleHigh == null ||
                                          manualScaleLow == null) {
                                        manualScaleHigh = tweenEnd;
                                        manualScaleLow = tweenBegin;
                                      }
                                      setState(() {
                                        double deltaPrice = delta /
                                            chartHeight *
                                            (manualScaleHigh! -
                                                manualScaleLow!);

                                        double newManualScaleHigh =
                                            manualScaleHigh! + deltaPrice;
                                        double newManualScaleLow =
                                            manualScaleLow! - deltaPrice;

                                        manualScaleHigh = newManualScaleHigh;
                                        manualScaleLow = newManualScaleLow;
                                      });
                                    },
                                  ),
                                ),
                              )
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
                                      high: HelperFunctions.getRoof(volumeHigh),
                                      bearColor: widget.style.secondaryBear,
                                      bullColor: widget.style.secondaryBull,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: priceBarWidth,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      height: dateBarHeight,
                                      child: Center(
                                        child: Row(
                                          children: [
                                            Text(
                                              "-${HelperFunctions.addMetricPrefix(HelperFunctions.getRoof(volumeHigh))}",
                                              style: TextStyle(
                                                color: widget.style.borderColor,
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
                          height: dateBarHeight,
                        ),
                      ],
                    ),
                    if (longPressX != null)
                      Positioned(
                        left: chartWidth -
                            (((chartWidth - longPressX!) ~/
                                        widget.candleWidth +
                                    1) *
                                widget.candleWidth) -
                            widget.candleWidth / 2,
                        child: Container(
                          width: widget.candleWidth,
                          height: maxHeight,
                          color: Colors.purple.withValues(alpha: 0.2),
                        ),
                      ),
                    Padding(
                      padding: EdgeInsets.only(
                        right: priceBarWidth,
                        bottom: 20,
                      ),
                      child: GestureDetector(
                        onScaleUpdate: (details) {
                          // Usar umbral para distinguir zoom de pan (evita fluctuaciones)
                          const double scaleThreshold = 0.01; // 1% de tolerancia
                          final bool isZoomGesture = (details.scale - 1.0).abs() > scaleThreshold;
                          
                          if (!isZoomGesture) {
                            // Pan horizontal - no hacer zoom vertical
                            _isZooming = false;
                            widget.onHorizontalDragUpdate(details);
                            // Solo ajustar rango vertical al final del pan, no durante cada actualización
                          } else {
                            // Zoom horizontal - marcar que estamos haciendo zoom
                            _isZooming = true;
                            widget
                                .onScaleUpdate(1 + (details.scale - 1) * 0.05);
                          }
                        },
                        onScaleStart: (details) {
                          // Inicializar como pan (se actualizará en onScaleUpdate si es zoom)
                          _isZooming = false;
                          widget.onPanDown(details.localFocalPoint.dx);
                        },
                        onScaleEnd: (details) {
                          widget.onPanEnd();
                          // Ajustar desplazamiento vertical solo si fue pan (no zoom)
                          // para mantener las velas visibles sin cambiar el nivel de zoom
                          if (!_isZooming) {
                            _fitVertical();
                          }
                          _isZooming = false;
                        },
                        onLongPressStart: (LongPressStartDetails details) {
                          final RenderBox? renderBox =
                          _customPaintKey.currentContext?.findRenderObject()
                          as RenderBox?;
                          if (renderBox == null) {
                            return;
                          }

                          final Size size = renderBox.size;
                          final RectangleZone? zoneLongPressed = hitTestZone(
                            details.localPosition,
                            size,
                          );

                          if (zoneLongPressed != null) {
                            Common().vibrate();
                            final originRect = Rect.fromLTWH(
                                details.globalPosition.dx,
                                details.globalPosition.dy,
                                50,
                                50);
                            if (widget.inactiveZone) {
                              showZoneDialogAnimated(
                                  context,
                                  zoneLongPressed,
                                  widget.chartTitle,
                                  widget.candles.first.close,
                                  widget.iconPath,
                                  originRect,
                                  _dollarCurrency,
                                  widget.menuController,
                                  _mapTimeframe(_currentRangeTime),
                                  fromInactive: true);
                            } else {
                              showZoneDialogAnimated(
                                  context,
                                  zoneLongPressed,
                                  widget.chartTitle,
                                  widget.candles.first.close,
                                  widget.iconPath,
                                  originRect,
                                  _dollarCurrency,
                                  widget.menuController,
                                  _mapTimeframe(_currentRangeTime));
                            }
                            return;
                          }

                          setState(() {
                            Common().vibrate();
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

                            int currentCandleIndex = min(
                              max(
                                (chartWidth - longPressX!) ~/
                                        widget.candleWidth +
                                    widget.index,
                                0,
                              ),
                              widget.candles.length - 1,
                            );

                            if (currentCandleIndex != lastCandleIndex) {
                              Common().vibrate();
                              lastCandleIndex = currentCandleIndex;
                            }
                          });
                        },
                      ),
                    ),
                    Positioned(
                      top: 56,
                      left: 0,
                      right: priceBarWidth,
                      child: Align(
                        alignment: Alignment.topCenter,
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
                    ),
                    const Divider(thickness: 0.1),
                    GestureDetector(
                      onTapUp: (TapUpDetails details) {
                        final RenderBox renderBox =
                        _customPaintKey.currentContext?.findRenderObject()
                        as RenderBox;
                        final size = renderBox.size;

                        final RectangleZone? zoneClicked = hitTestZone(
                          details.localPosition,
                          size,
                        );

                        if (zoneClicked != null) {
                          if (!widget.inactiveZone) {
                            _openZone(zoneClicked);
                          } else {
                            Common().vibrate();
                            showZoneDialogAnimated(
                                context,
                                zoneClicked,
                                widget.chartTitle,
                                widget.candles.first.close,
                                widget.iconPath,
                                Rect.fromLTWH(details.globalPosition.dx,
                                    details.globalPosition.dy, 50, 50),
                                _dollarCurrency,
                                widget.menuController,
                                _mapTimeframe(_currentRangeTime),
                                fromInactive: true);
                          }
                        }
                      },
                    ),
                    Positioned(
                      top: 0.0,
                      right: 0.0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: widget.style.background,
                        ),
                        height: 60.0,
                        width: priceBarWidth,
                        child: IconButton(
                          icon: Icon(
                            FontAwesomeIcons.bullseye,
                            size: 32,
                            color: Colors.white70,
                            shadows: [
                              Shadow(
                                blurRadius: 1.5,
                                color: Colors.black45,
                                offset: Offset(8.0, 4.0),
                              ),
                            ],
                          ),
                          onPressed: () {
                            Common().vibrate();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ExactPricePage(
                                  name: widget.chartTitle,
                                  ticker: widget.ticker,
                                  currentValue: widget.candles.first.close,
                                  iconPath: widget.iconPath,
                                  isForex:
                                  Common().isTickerForex(widget.ticker),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    Positioned(
                      top: (constraints.maxHeight / 2) * 0.97 - 36,
                      left: 4.0,
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.transparent,
                        ),
                        height: 50.0,
                        width: 50.0,
                        child: TextButton(
                          child: Text(
                            _currentRangeTime,
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          onPressed: () async {
                            if (!widget.inactiveZone) {
                              Common().vibrate();
                              setState(() {
                                _currentIndex =
                                    (_currentIndex + 1) % options.length;
                                _currentRangeTime = options[_currentIndex];
                              });
                              final timeframe =
                              _mapTimeframe(_currentRangeTime);
                              TimeframeManager.set(timeframe);
                              await _reloadData(
                                  timeframe, _dollarCurrency ? 'USD' : 'EUR');
                              if (!mounted) return;
                              widget.onRequestFit?.call();
                            }
                          },
                        ),
                      ),
                    ),
                  ]),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    BetZoneRefresher().stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      BetZoneRefresher().stop();
    } else if (state == AppLifecycleState.resumed) {
      BetZoneRefresher()
          .start(widget.ticker, (_dollarCurrency ? 'USD' : 'EUR'), widget.rectangleZones);
    }
  }
}
