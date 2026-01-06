import 'dart:async';
import 'package:flutter/foundation.dart';
import '../helpers/common.dart';
import '../models/rectangle_zone.dart';

import 'bets_service.dart';

class BetZoneRefresher {
  static final BetZoneRefresher _instance = BetZoneRefresher._internal();
  factory BetZoneRefresher() => _instance;

  BetZoneRefresher._internal();

  Timer? _timer;
  ValueNotifier<List<RectangleZone>>? _notifier;

  void start(String ticker, String currency, ValueNotifier<List<RectangleZone>> notifier) {
    _notifier = notifier;

    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 2), (_) async {
      try {
        final candles = await BetsService().fetchCandles(ticker, TimeframeManager.current.value, currency);
        final zones = await BetsService().fetchBetZones(ticker, TimeframeManager.current.value, null, currency: currency);
        if (_notifier != null) {
          _notifier!.value = Common().getRectangleZonesFromBetZones(zones, candles.isNotEmpty ? candles.first.close : 0.0);
        }
      } catch (e) {
        if (kDebugMode) {
          print("Error fetching bet zones: $e");
        }
      }
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _notifier = null;
  }

  bool get isRunning => _timer != null;
}

class TimeframeManager {
  static final ValueNotifier<int> current = ValueNotifier<int>(1);

  static void set(int value) {
    current.value = value;
  }
}