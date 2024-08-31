import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../candlesticks/src/main.dart';
import '../candlesticks/src/models/candle.dart';
import '../helpers/common.dart';
import 'layout_page.dart';

class CandlesticksView extends StatefulWidget {
  final String id;
  final String name;
  final List<Candle> candles;
  final MainMenuPageController controller;
  
  CandlesticksView(this.id, this.name, {super.key, required this.controller})
      : candles = Common().generateRandomCandles(520);

  @override
  CandlesticksViewState createState() => CandlesticksViewState();
}

class CandlesticksViewState extends State<CandlesticksView> {
  late final ValueNotifier<double> candleScaleNotifier =
  ValueNotifier<double>(1.0);
  

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Stack(
          children: <Widget>[
            ValueListenableBuilder<double>(
              valueListenable: candleScaleNotifier,
              builder: (BuildContext context, double scale, Widget? child) {
                return Center(
                  child: Stack(
                    children: <Widget>[
                      Candlesticks(
                        candles: widget.candles,
                        displayZoomActions: false,
                        onScaleUpdate: (double scale) {
                          candleScaleNotifier.value = scale;
                        },
                        rectangleZones: Common().generateRectangleZones(), controller: widget.controller,
                      ),
                      Positioned(
                        top: 10.0,
                        left: 20.0,
                        right: 20.0,
                        child:
                            Text(
                              widget.name,
                              style: GoogleFonts.abel(
                                fontSize: 26.0,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                            )
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}