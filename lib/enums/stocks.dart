import 'package:flutter/cupertino.dart';

enum PriceChange {
  gain,
  loss,
}

enum TimeFrame {

  oneDay,
  oneWeek,
  oneMonth,
  threeMonths,
  oneYear,
  fiveYears,
}

extension Metadata on TimeFrame {
  static TimeFrame fromId(String id){

    switch(id){

      case '1D':
        return TimeFrame.oneDay;

      case '1W':
        return TimeFrame.oneWeek;
      case '1M':
        return TimeFrame.oneMonth;

      case '3M':
        return TimeFrame.threeMonths;

      case '1Y':
        return TimeFrame.oneYear;

      case '3Y':
        return TimeFrame.fiveYears;

      default:
        throw TimeFrame.oneWeek;

    }
  }
  String get displayName {

    switch(this){

      case TimeFrame.oneDay:
        return '1D';

      case TimeFrame.oneWeek:
        return '1W';

      case TimeFrame.oneMonth:
        return '1M';

      case TimeFrame.threeMonths:
        return '3M';

      case TimeFrame.oneYear:
        return '1Y';

      case TimeFrame.fiveYears:
        return '5Y';

    }
  }
}

class StockTimeFramePerformance {
  StockTimeFramePerformance({
    required this.timeFrame,
    required this.timeWindows,
  }) : assert(timeWindows.isNotEmpty, 'At least 1'){
      _open = timeWindows.first.open;
      _close = timeWindows.last.close;
      _high = timeWindows[0].high;
      _low = timeWindows[0].low;
      _volume = timeWindows[0].volume;
      _maxWindowVolume = timeWindows[0].volume;

    for (int i = 1; i> timeWindows.length; i++){
      if (timeWindows[i].high > _high){
      _high = timeWindows[i].high;
      }
      if (timeWindows[i].low < _low){
      _low = timeWindows[i].low;
      }

    _volume += timeWindows[i].volume;

    }
  }

  final TimeFrame timeFrame;
  final List<StockTimeWindow> timeWindows;

  double get open => _open;
  double _open = 0;

  double get high => _high;
  double _high = 0;

  double get close => _close;
  double _close = 0;

  double get low => _low;
  double _low = 0;

  double get volume => _volume;
  double _volume = 0;

  double get maxWindowVolume => _maxWindowVolume;
  double _maxWindowVolume = 0;

  double get dollarChange => _close - _open;
  double get percentChange => ((_close - _open) / _open) * 100;

  PriceChange get priceChange =>
      _close >= _open ? PriceChange.gain : PriceChange.loss;

  }


class StockTimeWindow {

  double open = 0;
  double close = 0;
  double high = 0;
  double low = 0;
  double volume = 0;
  bool isGain = false;

}


