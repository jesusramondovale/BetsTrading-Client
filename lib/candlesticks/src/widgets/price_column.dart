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
  });

  final double low;
  final double high;
  final double width;
  final double chartHeight;
  final Candle lastCandle;
  final void Function(double) onScale;
  final CandleSticksStyle style;
  final int paintCurrency;

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
    final double priceScale = HelperFunctions.calculatePriceScale(
        widget.chartHeight, widget.high, widget.low);
    final double priceTileHeight =
        widget.chartHeight / ((widget.high - widget.low) / priceScale);
    final double newHigh = (widget.high ~/ priceScale + 1) * priceScale;
    final double top = -priceTileHeight / priceScale * (newHigh - widget.high) +
        mainChartVerticalPadding -
        priceTileHeight / 2 ;
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
              height:
                  widget.chartHeight + 2 * mainChartVerticalPadding - top,
              width: widget.width,
              child: ListView(
                controller: scrollController,
                children: List<Widget>.generate(20, (i) {
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
                                  currency: widget.paintCurrency),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: widget.style.primaryTextColor,
                                fontSize: HelperFunctions.priceToString(newHigh - priceScale * i,
                                    currency: widget.paintCurrency).length > 9 ? 9 : 11,
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
                widget.chartHeight,
                widget.low,
                widget.high,
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
                        HelperFunctions.priceToString(widget.lastCandle.close, currency: widget.paintCurrency),
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
