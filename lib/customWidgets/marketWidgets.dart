import '../helpers/common.dart';
import '../services/AuthService.dart';
import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:candlesticks/candlesticks.dart';

import '../enums/stocks.dart';

class WidgetWorkshopScaffold extends StatefulWidget {

  final Widget Function(BuildContext, StockTimeFramePerformance) chartBuilder;
  const WidgetWorkshopScaffold({super.key, required this.chartBuilder});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(

    );
  }

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    throw UnimplementedError();

  }
}

class _WidgetWorkshopState extends State<WidgetWorkshopScaffold> {

  @override
  Widget build(BuildContext context) {
    return WidgetWorkshopScaffold(
      chartBuilder: (
          BuildContext context,
          StockTimeFramePerformance stockData,
          ) {
        return Column(
          children: [
            SizedBox(
              height: 160,
              child: CustomPaint(
                size: Size.infinite,
                painter: StockCandleStickPainter(
                  stockData: stockData,

                ),
              ),
            ), // Container
            const SizedBox(height: 5),
            SizedBox(
              height: 30,
              child: CustomPaint(
                size: Size.infinite,
                painter: StockVolumePainter(
                  stockData: stockData,
                ), // StockVolumePainter
              ), // CustomPaint
            ), // SizedBox
          ],
        ); // Column
      },
    ); // WidgetWorkshopScaffold
  }

}

class StockCandleStickPainter extends CustomPainter{

  StockCandleStickPainter({
    required this.stockData,

  }) : _wickPaint = Paint()..color = Colors.grey,
        _gainPaint = Paint()..color = Colors.green,
        _lossPaint = Paint()..color = Colors.red;

  final StockTimeFramePerformance stockData;
  final Paint _wickPaint;
  final Paint _gainPaint;
  final Paint _lossPaint;
  final double _wickWidth = 1.0;
  final double _candleWidth = 1.0;

  @override
  void paint(Canvas canvas, Size size){
    List<Candlestick> candlesticks = _generateCandleSticks(size);
    for (Candlestick candlestick in candlesticks){
      canvas.drawRect(
        Rect.fromLTRB(candlestick.centerX - (_wickWidth/2) ,
          size.height - candlestick.wickHighY,
          candlestick.centerX + (_wickWidth/2),
          size.height - candlestick.wickLowY,
        ),
        _wickPaint,
      );

      canvas.drawRect(
        Rect.fromLTRB(
          candlestick.centerX - (_candleWidth/2),
          size.height - candlestick.candleHighY,
          candlestick.centerX - (_candleWidth/2),
          size.height - candlestick.candleLowY,
        ),
        candlestick.candlePaint,
      );
    }
  }

  List<Candlestick> _generateCandleSticks(Size availableSpace){
    final pixelsPerWindow = availableSpace.width / (stockData.timeWindows.length+1);
    final pixelsPerDollar = availableSpace.height/ (stockData.high - stockData.low);

    final List<Candlestick> candlesticks = [];
    for (int i = 0; i < stockData.timeWindows.length; i++){
      final StockTimeWindow window = stockData.timeWindows[i];
      candlesticks.add(
        Candlestick(centerX: (i+1) * pixelsPerWindow,
          wickHighY: (window.high - stockData.low) * pixelsPerDollar,
          wickLowY: (window.low - stockData.low) * pixelsPerDollar,
          candleHighY: (window.open - stockData.low) * pixelsPerDollar,
          candleLowY: (window.close - stockData.low) * pixelsPerDollar,
          candlePaint: window.isGain ? _gainPaint : _lossPaint,
        ),
      );
    }
    return candlesticks;
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;

  }

}

class Candlestick {
  Candlestick({
    required this.centerX,
    required this.wickHighY,
    required this.wickLowY,
    required this.candleHighY,
    required this.candleLowY,
    required this.candlePaint
  });

  final double centerX;
  final double wickHighY;
  final double wickLowY;
  final double candleHighY;
  final double candleLowY;
  final Paint candlePaint;

}

class StockVolumePainter extends CustomPainter{
  StockVolumePainter({
    required this.stockData,
  })  :  _gainPaint = Paint()..color = Colors.green.withOpacity(0.5),
        _lossPaint = Paint()..color = Colors.red.withOpacity(0.5);

  final StockTimeFramePerformance stockData;
  final Paint _gainPaint;
  final Paint _lossPaint;

  @override
  void paint(Canvas canvas, Size size) {

    List<Bar> bars = _generateBars(size);
    for(Bar bar in bars){
      canvas.drawRect(
        Rect.fromLTWH(
          bar.centerX - (bar.width/2),
          size.height - bar.height,
          bar.width,
          bar.height,
        ),
        bar.paint,
      );

    }
  }


  List<Bar> _generateBars(Size availableSpace){
    final pixelsPerTimeWindow = availableSpace.width / (stockData.timeWindows.length + 1);
    final pixelsPerStockOrder = availableSpace.height / stockData.maxWindowVolume;

    List<Bar> bars = [];
    for (int i= 0; i<stockData.timeWindows.length; i++) {
      final StockTimeWindow window = stockData.timeWindows[i];

      bars.add(
        Bar(
            width: 3.0,
            height: window.volume * pixelsPerStockOrder,
            centerX: (i + 1) * pixelsPerTimeWindow,
            paint: window.isGain ? _gainPaint : _lossPaint

        ),
      );
    }
    return bars;
  }


  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;

  }

}
