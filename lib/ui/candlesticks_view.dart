import 'package:flutter/material.dart';
import '../candlesticks/src/main.dart';
import '../candlesticks/src/models/candle.dart';
import '../helpers/common.dart';

class CandlesticksView extends StatefulWidget {
  CandlesticksView(int id, {super.key});
  List<Candle> candles = Common().generateRandomCandles(520);
  @override
  CandlesticksViewState createState() => CandlesticksViewState();
}

class CandlesticksViewState extends State<CandlesticksView> {
  ValueNotifier<double> candleScaleNotifier = ValueNotifier<double>(1.0);

  @override
  Widget build(BuildContext context) {


    return SafeArea(
      child: Center(
        child: Stack(
          children: <Widget>[
            ValueListenableBuilder<double>(
              valueListenable: candleScaleNotifier,
              builder: (BuildContext context, double scale, Widget? child) {
                return SafeArea(
                  child: Center(
                    child: Stack(
                      children: <Widget>[
                        Candlesticks(
                          candles: widget.candles,
                          onScaleUpdate: (double scale) {
                            candleScaleNotifier.value = scale;
                          },
                          rectangleZones: Common().generateRectangleZones(),
                        ),
                      ],
                    ),
                  ),
                );
              },
            )
          ],
        ),
      ),
    );
  }
}
