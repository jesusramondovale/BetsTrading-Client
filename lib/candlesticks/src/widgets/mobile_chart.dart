import 'dart:convert';
import 'dart:math';
import 'package:betrader/candlesticks/src/widgets/vertical_grid_painter.dart';
import 'package:betrader/locale/localized_texts.dart';
import 'package:flutter/foundation.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../Services/bets_service.dart';
import '../../../helpers/common.dart';
import '../../../helpers/range_painter.dart';
import '../../../models/rectangle_zone.dart';
import '../../../services/bet_zone_refresher.dart';
import '../../../ui/bets_page.dart';
import '../../../ui/exact_price_view.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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

    _ensureZonesVisible();
  }

  void _openZone(RectangleZone zone) {
    if (widget.inactiveZone) return;

    Common().vibrate();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => BetConfirmationPage(
          name: widget.chartTitle,
          zone: zone,
          currentValue: widget.candles.first.close,
          iconPath: widget.iconPath,
          onCancel: () {
            Common().vibrate();
            Navigator.pop(context);
          },
        ),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  void _ensureZonesVisible() {
    if (widget.rectangleZones.value.isEmpty) return;

    List<Candle> last30Candles = widget.candles.length > 30
        ? widget.candles.sublist(0, 30)
        : widget.candles;

    double minPrice = min(
        widget.rectangleZones.value
            .map((zone) => zone.lowPrice)
            .reduce((value, element) => value < element ? value : element),
        last30Candles
            .map((candle) => candle.low)
            .reduce((value, element) => value < element ? value : element));

    double maxPrice = max(
        widget.rectangleZones.value
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


  /// Ajusta el desplazamiento vertical para mantener las velas visibles
  /// sin cambiar el nivel de zoom si ya hay uno establecido
  void _ensureVisibleRange() {
    if (widget.candles.isEmpty) return;

    final RenderBox? renderBox =
    _customPaintKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final double maxWidth =
        renderBox.size.width - priceBarWidth + widget.candleWidth * 2;

    final int candlesStartIndex = widget.candles.isEmpty
        ? 0
        : min(max(widget.index, 0), widget.candles.length - 1);

    final int candlesEndIndex = widget.candles.isEmpty
        ? 0
        : min(
      (maxWidth ~/ widget.candleWidth) + candlesStartIndex,
      widget.candles.length - 1,
    );

    if (candlesEndIndex <= candlesStartIndex) return;

    List<Candle> visibleCandles = widget.candles
        .getRange(candlesStartIndex, candlesEndIndex - 10)
        .toList();

    double candlesHigh = visibleCandles.map((c) => c.high).reduce(max);
    double candlesLow = visibleCandles.map((c) => c.low).reduce(min);

    // Si hay zoom manual, solo ajustar si las velas se salen del rango visible
    if (manualScaleHigh != null && manualScaleLow != null) {
      // Verificar si las velas están completamente fuera del rango visible
      bool needsAdjustment = false;
      double newHigh = manualScaleHigh!;
      double newLow = manualScaleLow!;
      double currentRange = newHigh - newLow;

      // Si las velas se salen por arriba o por abajo, ajustar manteniendo el rango
      if (candlesHigh > newHigh) {
        needsAdjustment = true;
        newHigh = candlesHigh;
        newLow = newHigh - currentRange;
      }
      if (candlesLow < newLow) {
        needsAdjustment = true;
        newLow = candlesLow;
        newHigh = newLow + currentRange;
      }

      // Si las velas están completamente fuera en ambas direcciones, ajustar al centro
      if (candlesHigh > newHigh && candlesLow < newLow) {
        double candlesRange = candlesHigh - candlesLow;
        double center = (candlesHigh + candlesLow) / 2;
        newHigh = center + currentRange / 2;
        newLow = center - currentRange / 2;
        // Asegurar que el rango mínimo sea suficiente
        if (currentRange < candlesRange) {
          newHigh = candlesHigh;
          newLow = candlesLow;
        }
        needsAdjustment = true;
      }

      if (needsAdjustment) {
        setState(() {
          manualScaleHigh = newHigh;
          manualScaleLow = newLow;
        });
      }
    } else {
      // Si no hay zoom manual, ajustar normalmente (como _autoAdjustVerticalRange)
      setState(() {
        manualScaleHigh = candlesHigh;
        manualScaleLow = candlesLow;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final noBetsText = LocalizedStrings.of(context)!.get('noBetsAvailable') ?? "No Bets available!";
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth =
            constraints.maxWidth - priceBarWidth + widget.candleWidth * 2;
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

        double priceRange = candlesHighPrice - candlesLowPrice;
        candlesHighPrice += priceRange;
        candlesLowPrice -= priceRange;

        if (candlesHighPrice == candlesLowPrice) {
          candlesHighPrice += 10;
          candlesLowPrice -= 10;
        }

        double chartHeight = maxHeight * 0.75 - 2 * mainChartVerticalPadding;

        double volumeHigh = inRangeCandles.map((e) => e.volume).reduce(max);

        if (longPressX != null && longPressY != null) {
          longPressX = max(longPressX!, 0);
          longPressX = min(longPressX!, maxWidth);
          longPressY = max(longPressY!, 0);
          longPressY = min(longPressY!, maxHeight);
        }

        if (widget.rectangleZones.value.isNotEmpty) {
          tweenBegin = min(
              widget.rectangleZones.value.map((zone) => zone.lowPrice).reduce(
                      (value, element) => value < element ? value : element),
              candlesLowPrice);
          tweenEnd = max(
              widget.rectangleZones.value.map((zone) => zone.highPrice).reduce(
                      (value, element) => value > element ? value : element),
              candlesHighPrice);
        } else {
          tweenBegin = candlesLowPrice;
          tweenEnd = candlesHighPrice;
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
          tween: Tween(begin: tweenBegin, end: tweenEnd),
          duration: Duration(milliseconds: manualScaleHigh == null ? 300 : 0),
          builder: (context, double high, _) {
            return TweenAnimationBuilder(
              tween: Tween(begin: candlesLowPrice, end: candlesLowPrice),
              duration:
              Duration(milliseconds: manualScaleHigh == null ? 300 : 0),
              builder: (context, double low, _) {
                final currentCandle =
                (longPressX == null || widget.candles.isEmpty)
                    ? null
                    : widget.candles[min(
                  max(
                    (maxWidth - longPressX!) ~/ widget.candleWidth +
                        widget.index - 1,
                    0,
                  ),
                  widget.candles.length - 1,
                )];

                return Container(
                  color: widget.style.background,
                  child: Stack(children: [
                    Positioned(
                      top: 10.0,
                      left: 20.0,
                      right: 20.0,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: 10),
                          if (widget.iconPath != "null" &&
                              !widget.iconPath.contains("http")) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Image.memory(
                                base64Decode(widget.iconPath),
                                height: 120,
                                width: 120,
                                gaplessPlayback: true,
                                errorBuilder: (context, error, stackTrace) =>
                                    Text(
                                      widget.chartTitle,
                                      maxLines: 1,
                                      style: GoogleFonts.roboto(
                                          fontSize: 36,
                                          fontWeight: FontWeight.w100),
                                      textAlign: TextAlign.center,
                                    ),
                              ),
                            )
                          ] else if (widget.iconPath.contains("http")) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Image.network(
                                widget.iconPath,
                                height: 120,
                                width: 120,
                                gaplessPlayback: true,
                                errorBuilder: (context, error, stackTrace) =>
                                    Text(
                                      widget.chartTitle,
                                      maxLines: 1,
                                      style: GoogleFonts.roboto(
                                          fontSize: 36,
                                          fontWeight: FontWeight.w100),
                                      textAlign: TextAlign.center,
                                    ),
                              ),
                            )
                          ] else ...[
                            Text(
                              widget.chartTitle.length > 15
                                  ? '${widget.chartTitle.substring(0, 15)}...'
                                  : widget.chartTitle,
                              style: GoogleFonts.openSans(
                                fontSize: 26.0,
                                fontWeight: FontWeight.w300,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                            ),
                          ],
                        ],
                      ),
                    ),
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
                                        padding: const EdgeInsets.symmetric(
                                            vertical:
                                            mainChartVerticalPadding),
                                        child: RepaintBoundary(
                                          child: Stack(
                                            children: [
                                              Positioned.fill(
                                                child: CustomPaint(
                                                  painter: GreyFixedGridPainter(
                                                    spacingPx:
                                                    MediaQuery.of(context)
                                                        .size
                                                        .width /
                                                        9,
                                                    priceBarWidth: 0,
                                                    topPadding: 0,
                                                    bottomPadding: 0,
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
                                    final double painterTop =
                                        tweenEnd;
                                    final double painterBottom =
                                        tweenBegin;
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
                                    low: tweenBegin,
                                    high: tweenEnd,
                                    width: priceBarWidth,
                                    paintCurrency: (
                                        widget.ticker.contains('/')
                                            ? 0
                                            : (_dollarCurrency ? 2 : 1) ),
                                    chartHeight: chartHeight,
                                    lastCandle: widget.candles[min(
                                        max(widget.index, 0),
                                        widget.candles.length - 1)],
                                    onScale: (delta) {
                                      if (manualScaleHigh == null ||
                                          manualScaleLow == null) {
                                        manualScaleHigh = candlesHighPrice;
                                        manualScaleLow = candlesLowPrice;
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
                        right: (maxWidth - longPressX!) ~/
                            widget.candleWidth *
                            widget.candleWidth +
                            priceBarWidth,
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
                            _ensureVisibleRange();
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
                                  widget.candles.last.close,
                                  widget.iconPath,
                                  originRect,
                                  _dollarCurrency,
                                  fromInactive: true);
                            } else {
                              showZoneDialogAnimated(
                                  context,
                                  zoneLongPressed,
                                  widget.chartTitle,
                                  widget.candles.last.close,
                                  widget.iconPath,
                                  originRect,
                                  _dollarCurrency);
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
                                (maxWidth - longPressX!) ~/ widget.candleWidth +
                                    widget.index - 1,
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
                      top: (constraints.maxHeight / 2),
                      left: 40.0,
                      child: Padding(
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
                                widget.candles.last.close,
                                widget.iconPath,
                                Rect.fromLTWH(details.globalPosition.dx,
                                    details.globalPosition.dy, 50, 50),
                                _dollarCurrency,
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
                      top: (constraints.maxHeight / 2) * 0.97,
                      left: 4.0,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.style.background,
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
                              if (widget.candles.isNotEmpty) {
                                final highs =
                                widget.candles.map((c) => c.high).toList();
                                final lows =
                                widget.candles.map((c) => c.low).toList();

                                final double newHigh = highs.reduce(max);
                                final double newLow = lows.reduce(min);

                                setState(() {
                                  manualScaleHigh = newHigh;
                                  manualScaleLow = newLow;
                                  scaleX = 1.0;
                                  scaleY = 1.0;
                                  offsetX = 0.0;
                                  offsetY = 0.0;
                                });
                                _ensureZonesVisible();
                              }
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                final extra = (Common()
                                    .hoursUntilLatestEndDate(
                                    widget.rectangleZones.value,
                                    widget.candles.first.date,
                                    timeframe));

                                final nuevoIndex = extra;
                                widget.onHorizontalDragUpdate(
                                  ScaleUpdateDetails(
                                    focalPoint: Offset(
                                        -nuevoIndex * widget.candleWidth, 0),
                                    localFocalPoint: Offset.zero,
                                    scale: 1.0,
                                  ),
                                );
                              });
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
