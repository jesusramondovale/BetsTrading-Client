import 'package:client_0_0_1/models/betZone.dart';
import 'package:client_0_0_1/services/BetsService.dart';
import 'package:flutter/material.dart';
import '../candlesticks/src/main.dart';
import '../candlesticks/src/models/candle.dart';
import '../helpers/common.dart';
import '../helpers/rectangle_zone.dart';
import 'layout_page.dart';

class CandlesticksView extends StatefulWidget {
  final String ticker;
  final String name;
  final String iconPath;
  final List<Candle> candles;
  final MainMenuPageController controller;

  CandlesticksView({
    super.key,
    required this.controller,
    required this.iconPath,
    required this.ticker,
    required this.name,
  }) : candles = Common().generateRandomCandles(520);

  @override
  CandlesticksViewState createState() => CandlesticksViewState();
}

class CandlesticksViewState extends State<CandlesticksView> {
  final ValueNotifier<double> candleScaleNotifier = ValueNotifier<double>(1.0);
  List<RectangleZone> _zones = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRectangleZones();
  }

  Future<void> _loadRectangleZones() async {
    try {
      final List<BetZone> betZones =
          await BetsService().fetchBetZones(widget.ticker);
      List<RectangleZone> rectangleZones =
          Common().getRectangleZonesFromBetZones(betZones);

      setState(() {
        _zones = rectangleZones;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Maneja errores si es necesario
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Stack(
            children: <Widget>[
              ValueListenableBuilder<double>(
                valueListenable: candleScaleNotifier,
                builder: (BuildContext context, double scale, Widget? child) {
                  return Center(
                    child: Stack(
                      children: <Widget>[
                        if (_isLoading)
                          Center(child: CircularProgressIndicator())
                        else
                          Candlesticks(
                            candles: widget.candles,
                            displayZoomActions: false,
                            onScaleUpdate: (double scale) {
                              candleScaleNotifier.value = scale;
                            },
                            rectangleZones: _zones,
                            controller: widget.controller,
                            chartTitle: widget.name,
                            iconPath: widget.iconPath,
                            extraDays: Common().daysUntilLatestEndDate(_zones),
                          ),
                        Positioned(
                          top: 10.0,
                          left: 10.0,
                          child: IconButton(
                            icon: Icon(Icons.arrow_back), // Ícono de ejemplo
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
