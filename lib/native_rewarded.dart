import 'package:flutter/services.dart';

class NativeRewarded {
  static const _channel = MethodChannel('custom_rewarded_ad');

  static Future<void> loadRewarded(String adUnitId, String userId) async {
    await _channel.invokeMethod('loadRewarded', {
      'adUnitId': adUnitId,
      'userId': userId,
    });
  }

  static Future<int?> showRewarded() async {
    final result = await _channel.invokeMethod('showRewarded');
    return result as int?;
  }
}
