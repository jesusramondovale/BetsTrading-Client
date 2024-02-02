import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../candlesticks/src/main.dart';
import '../helpers/common.dart';
import '../helpers/range_painter.dart';

class CandlesticksView extends StatefulWidget {
  const CandlesticksView({super.key});

  @override
  CandlesticksViewState createState() => CandlesticksViewState();
}

class CandlesticksViewState extends State<CandlesticksView> {
  ValueNotifier<double> candleScaleNotifier = ValueNotifier<double>(1.0);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        children: <Widget>[
          ValueListenableBuilder<double>(
            valueListenable: candleScaleNotifier,
            builder: (BuildContext context, double scale, Widget? child) {
              return Center(
                child: Stack(
                  children: <Widget>[
                    Candlesticks(
                      candles: Common().generateRandomCandles(150),
                      onScaleUpdate: (double scale) {
                        candleScaleNotifier.value = scale;
                        if (kDebugMode) {
                          print("Actualization scaleY = $scale");
                        }
                      },
                    ),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          key: UniqueKey(),
                          painter: RangePainter(
                            startX: 180,
                            endX: 350,
                            startY: 50,
                            endY: 140,
                            oddsLabel: 'x2.75',
                            fillColor: Colors.green.withOpacity(0.5),
                            strokeColor: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                            scaleY: scale,
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          key: UniqueKey(),
                          painter: RangePainter(
                            startX: 180,
                            endX: 350,
                            startY: 250,
                            endY: 340,
                            oddsLabel: 'x2.75',
                            fillColor: Colors.green.withOpacity(0.5),
                            strokeColor: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                            scaleY: scale,
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          key: UniqueKey(),
                          painter: RangePainter(
                            startX: 180,
                            endX: 350,
                            startY: 341,
                            endY: 500,
                            oddsLabel: 'x2.75',
                            fillColor: Colors.green.withOpacity(0.5),
                            strokeColor: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                            scaleY: scale,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          )
        ],
      ),
    );
  }
}
