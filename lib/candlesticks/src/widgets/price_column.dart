import 'dart:math';

import '../constant/view_constants.dart';
import '../models/candle.dart';
import '../models/candle_sticks_style.dart';
import '../utils/helper_functions.dart';
import 'package:flutter/material.dart';

class PriceColumn extends StatefulWidget {
  const PriceColumn({
    super.key,
    this.paintCurrency = 0,
    required this.low,
    required this.high,
    required this.width,
    required this.chartHeight,
    required this.lastCandle,
    required this.onScale,
    required this.style,
    this.plotTopPadding = mainChartVerticalPadding,
  });

  final double low;
  final double high;
  final double width;
  final double chartHeight;
  final Candle lastCandle;
  final void Function(double) onScale;
  final CandleSticksStyle style;
  final int paintCurrency;
  final double plotTopPadding;

  @override
  State<PriceColumn> createState() => _PriceColumnState();
}

class _PriceColumnState extends State<PriceColumn> {
  ScrollController scrollController = ScrollController();

  double calculatePriceIndicatorTopPadding(
      double chartHeight, double low, double high) {
    return chartHeight +
        10 -
        (widget.lastCandle.close - low) / (high - low) * chartHeight -
        mainChartVerticalPadding;
  }

  @override
  Widget build(BuildContext context) {
    double high = widget.high;
    double low = widget.low;
    if (!high.isFinite || !low.isFinite || high <= low) {
      final double basis = high.isFinite
          ? high.abs()
          : (low.isFinite ? low.abs() : 1);
      final double pad = max(basis * 0.01, 1e-6);
      final double mid =
          (high.isFinite && low.isFinite) ? (high + low) / 2 : 0;
      high = mid + pad;
      low = mid - pad;
    }
    final double chartHeight = widget.chartHeight.isFinite && widget.chartHeight > 1
        ? widget.chartHeight
        : minPricetileHeight * 4;

    final double priceScale =
        HelperFunctions.calculatePriceScale(chartHeight, high, low);
    double priceTileHeight = chartHeight / ((high - low) / priceScale);
    if (!priceTileHeight.isFinite || priceTileHeight <= 0) {
      priceTileHeight = minPricetileHeight;
    }
    final double newHigh = (high / priceScale).floor() * priceScale + priceScale;
    double top = -priceTileHeight / priceScale * (newHigh - high) +
        widget.plotTopPadding -
        priceTileHeight / 2;
    if (!top.isFinite) top = 0;
    final double columnHeight =
        max(0, chartHeight + 2 * mainChartVerticalPadding - top);
    final int tileCount = max(8, (columnHeight / priceTileHeight).ceil() + 2);
    final int extraDecimals =
        HelperFunctions.extraDecimalsForStep(newHigh, priceScale);
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        /// DISPARA SOLO AL PELLIZCAR BARRA LATERAL
        //print("VERTICAL SCALE ->->-> ${details.delta.dy}");
        widget.onScale(details.delta.dy);

      },
      child: AbsorbPointer(
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              top: top,
              height: max(
                  0,
                  chartHeight + 2 * mainChartVerticalPadding - top,
                ),
              width: widget.width,
              child: ListView(
                controller: scrollController,
                children: List<Widget>.generate(tileCount, (i) {
                  return AnimatedContainer(

                    duration: const Duration(milliseconds: 300),
                    height: priceTileHeight,
                    width: double.infinity,

                    child: Center(

                      child: Row(
                        children: [
                          Container(
                            width: widget.width - priceBarWidth,
                            height: 0.05,
                            color: widget.style.borderColor,
                          ),
                          Expanded(
                            child: Text(
                              HelperFunctions.priceToString(newHigh - priceScale * i,
                                  currency: widget.paintCurrency,
                                  extraDecimals: extraDecimals),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: HelperFunctions.priceToString(newHigh - priceScale * i,
                                    currency: widget.paintCurrency,
                                    extraDecimals: extraDecimals).length > 9 ? 9 : 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            AnimatedPositioned(

              duration: const Duration(milliseconds: 300),
              right: 0,
              top: calculatePriceIndicatorTopPadding(
                chartHeight,
                low,
                high,
              ),
              child: Row(
                children: [
                  Container(
                    color: widget.lastCandle.isBull
                        ? widget.style.primaryBull
                        : widget.style.primaryBear,
                    width: priceBarWidth,
                    height: priceIndicatorHeight,
                    child: Center(
                      child: Text(
                        HelperFunctions.priceToString(widget.lastCandle.close,
                            currency: widget.paintCurrency,
                            extraDecimals: extraDecimals),
                        style: TextStyle(
                          color: widget.style.secondaryTextColor,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
