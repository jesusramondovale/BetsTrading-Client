import 'package:betrader/models/betZone.dart';
import 'package:betrader/services/BetsService.dart';
import 'package:flutter/material.dart';
import '../candlesticks/src/main.dart';
import '../candlesticks/src/models/candle.dart';
import '../helpers/common.dart';
import '../models/rectangle_zone.dart';
import 'layout_page.dart';

class CandlesticksView extends StatefulWidget {
  final String ticker;
  final String name;
  final String iconPath;
  final MainMenuPageController controller;
  final int? betZoneId;

  CandlesticksView({
    super.key,
    required this.controller,
    required this.iconPath,
    required this.ticker,
    this.betZoneId,
    required this.name,
  });

  @override
  CandlesticksViewState createState() => CandlesticksViewState();
}

class CandlesticksViewState extends State<CandlesticksView> {
  final ValueNotifier<double> candleScaleNotifier = ValueNotifier<double>(1.0);
  List<RectangleZone> _zones = [];
  List<Candle> _candles = [];
  bool _isLoading = true;
  late bool _inactive_zone;

  @override
  void initState() {
    super.initState();
    _loadData();
    _inactive_zone = widget.betZoneId != null;
  }

  Future<void> _loadData() async {
    try {
      final List<Candle> candles;
      final List<BetZone> betZones =
          await BetsService().fetchBetZones(widget.ticker, widget.betZoneId);

      candles = await BetsService().fetchCandles(widget.ticker);

      List<RectangleZone> rectangleZones = Common()
          .getRectangleZonesFromBetZones(
              betZones, candles.isNotEmpty ? candles.first.close : 0.0);

      setState(() {
        _isLoading = false;
        _zones = rectangleZones;
        _candles = candles;

      });
    } catch (Exception) {
      setState(() {
        _isLoading = false;
      });
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
                            candles: _candles,
                            displayZoomActions: false,
                            onScaleUpdate: (double scale) {
                              candleScaleNotifier.value = scale;
                            },
                            rectangleZones: _zones,
                            inactiveZone: _inactive_zone,
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
