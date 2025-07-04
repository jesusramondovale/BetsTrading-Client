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
  final int? betId;

  CandlesticksView({
    super.key,
    required this.controller,
    required this.iconPath,
    required this.ticker,
    this.betId,
    required this.name,
  });

  @override
  CandlesticksViewState createState() => CandlesticksViewState();
}

class CandlesticksViewState extends State<CandlesticksView> {
  final ValueNotifier<double> candleScaleNotifier = ValueNotifier<double>(1.0);
  final ValueNotifier<List<RectangleZone>> _zonesNotifier = ValueNotifier([]);
  late final List<RectangleZone> _initialZones;
  late final ValueNotifier<List<RectangleZone>> _frozenZonesNotifier;
  List<Candle> _candles = [];
  bool _isLoading = true;
  late bool _inactive_zone;

  @override
  void initState() {
    super.initState();
    _loadData();
    _inactive_zone = widget.betId != null;
  }

  Future<void> _loadData() async {
    try {
      final List<Candle> candles;

     final List<BetZone> betZones =
        await BetsService().fetchBetZones(widget.ticker, widget.betId);

      candles = await BetsService().fetchCandles(widget.ticker);

      List<RectangleZone> rectangleZones = Common()
          .getRectangleZonesFromBetZones(
              betZones, candles.isNotEmpty ? candles.first.close : 0.0);
      _initialZones = rectangleZones;
      _frozenZonesNotifier = ValueNotifier(_initialZones);
      setState(() {
        _isLoading = false;
        if (!_inactive_zone) {
          _zonesNotifier.value = _initialZones;
        }
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
                              rectangleZones: _inactive_zone ? _frozenZonesNotifier : _zonesNotifier,
                              inactiveZone: _inactive_zone,
                              controller: widget.controller,
                              chartTitle: widget.name,
                              ticker: widget.ticker,
                              iconPath: widget.iconPath,
                              extraDays: Common().daysUntilLatestEndDate(_zonesNotifier.value),
                            ),
                        Positioned(
                          top: 10.0,
                          left: 10.0,
                          child: IconButton(
                            icon: Icon(
                                Icons.arrow_back,
                              shadows: [
                                Shadow(
                                  blurRadius: 3.0,
                                  color: Colors.black45,
                                  offset: Offset(2.5, 2.5),
                                ),
                              ],
                            ),
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
