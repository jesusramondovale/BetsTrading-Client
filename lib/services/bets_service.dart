import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../candlesticks/src/models/candle.dart';
import '../helpers/common.dart';
import '../models/bet_zone.dart';
import '../models/bets.dart';
import '../models/favorites.dart';
import '../models/trends.dart';

class BetsService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<Bet?> fetchBet(String betId, String currency) async {
    String? userId = await _storage.read(key: "sessionToken");
    final response = await Common().postRequestWrapper(
      'Bet', 'UserBet',
      {
        'userId': userId,
        'betId': int.tryParse(betId) ?? 0,
        'currency': currency,
      },
    );

    if (response['statusCode'] == 200) {
      Bet bet = (response['body']['bet'] as List).map((json) => Bet.fromJson(json)).first;
      return bet;
    } else {
      return null;
    }

  }


  Future<List<BetZone>> fetchBetZones(String ticker, int hoursTimeframe, int? betId, {required String currency}) async {


    if (null != betId) {
      final response =
          await Common().postRequestWrapper('Bet', 'GetBetZone', {
            'betId': betId,
            'currency': currency,
          });

      if (response['statusCode'] == 200) {
        List<BetZone> zones = (response['body']['bets'] as List)
            .map((json) => BetZone.fromJson(json))
            .toList();

        return zones;
      } else {
        return [];
      }
    }
    final response =
        await Common().postRequestWrapper('Bet', 'GetBetZones', {
          'ticker': ticker,
          'timeframe': hoursTimeframe,
          'currency': currency,
        });

    if (response['statusCode'] == 200) {
      List<BetZone> zones = (response['body']['bets'] as List)
          .map((json) => BetZone.fromJson(json))
          .toList();

      return zones;
    } else {
      return [];
    }
  }

  Future<BetsAndPriceBets> fetchInvestmentData(String userId, String currency) async {
    final betsResponse =
        await Common().postRequestWrapper('Bet', 'UserBets', {
          'userId': userId,
          'includeArchived': false,
        });
    final priceBetsResponse =
        await Common().postRequestWrapper('Bet', 'PriceBets', {
          'userId': userId,
          'currency': currency,
        });

    List<Bet> bets = <Bet>[];
    if (betsResponse['statusCode'] == 200) {
      try {
        final betsRaw = betsResponse['body'];
        final list = betsRaw is List
            ? betsRaw
            : (betsRaw is Map ? (betsRaw['bets'] ?? betsRaw['Bets']) : null);
        final items = list is List ? list : <dynamic>[];
        bets = items
            .map((json) => Bet.fromJson(json as Map<String, dynamic>))
            .toList();
      } catch (e) {
        if (kDebugMode) {
          print('[BetsService] fetchInvestmentData bets parse error: $e');
        }
      }
    }

    List<PriceBet> priceBets = <PriceBet>[];
    if (priceBetsResponse['statusCode'] == 200) {
      try {
        final body = priceBetsResponse['body'];
        final list = body is Map ? (body['bets'] ?? body['Bets']) : null;
        final items = list is List ? list : <dynamic>[];
        priceBets = items
            .map((json) => PriceBet.fromJson(json as Map<String, dynamic>))
            .toList();
      } catch (e) {
        if (kDebugMode) {
          print('[BetsService] fetchInvestmentData priceBets parse error: $e');
        }
      }
    }

    final double totalBetAmount =
        bets.fold<double>(0, (sum, b) => sum + (b.betAmount));
    final double totalProfit =
        bets.fold<double>(0, (sum, b) => sum + (b.profitLoss ?? 0));

    return BetsAndPriceBets(
      bets: Bets(totalBetAmount, totalProfit, bets.length, investList: bets),
      priceBets: priceBets,
      totalBetAmount: totalBetAmount,
      totalProfit: totalProfit,
    );
  }

  Future<Favorites> fetchFavouritesData(String userId, String currency) async {
    final response = await Common().postRequestWrapper(
        'Info', 'Favorites', {'currency': currency});
    if (response['statusCode'] == 200) {
      List<Favorite> favorites = (response['body']['favorites'] as List)
          .map((json) => Favorite.fromJson(json))
          .toList();

      return Favorites(favorites, favorites.length);
    } else {
      return Favorites([], 0);
    }
  }

  Future<bool> postNewBet(String userId, String fcm, String ticker, double betAmount, double originValue, int betZone, String currency) async {
    final response = await Common().postRequestWrapper('Bet', 'NewBet', {
      'userId': userId,
      'fcm': fcm,
      'ticker': ticker,
      'betAmount': betAmount,
      'originValue': originValue,
      'betZoneId': betZone,
      'currency': currency,
    });

    return response['statusCode'] == 200;
  }

  Future<int> postNewExactPriceBet(String userId, String fcm, String ticker, double priceBet,
      double margin, DateTime endDate, String currency) async {

    final Map<String, dynamic> data = {
      'userId': userId,
      'fcm': fcm,
      'ticker': ticker,
      'currency': currency,
      'priceBet': priceBet,
      'margin': margin,
      'endDate': endDate.toIso8601String(),
    };
    final response = await Common().postRequestWrapper('Bet', 'NewPriceBet', data);
    return response['statusCode'];
  }

  Future<bool> postNewFavorite(String userId, String ticker) async {
    // Normalizar ticker para coincidir con el backend (evitar duplicados por mayúsculas/minúsculas)
    final normalizedTicker = (ticker).trim().toUpperCase();
    final response = await Common().postRequestWrapper(
        'Info', 'NewFavorite', {'userId': userId, 'ticker': normalizedTicker});
    return response['statusCode'] == 200;
  }

  Future<bool> deleteRecentBet(String betId) async {
    final bid = int.tryParse(betId) ?? 0;
    final response = await Common()
        .postRequestWrapper('Bet', 'DeleteRecentBet', {'betId': bid});
    return response['statusCode'] == 200;
  }

  Future<bool> deleteRecentPriceBet(String priceBetId, String currency) async {
    final pid = int.tryParse(priceBetId) ?? 0;
    final response = await Common()
        .postRequestWrapper('Bet', 'DeleteRecentPriceBet', {
          'priceBetId': pid,
          'currency': currency,
        });
    return response['statusCode'] == 200;
  }

  Future<bool> deleteHistoricBets(String userId) async {
    final response = await Common()
        .postRequestWrapper('Bet', 'DeleteHistoricBet', {'userId': userId});
    return response['statusCode'] == 200;
  }

  /// Max odds por ticker y timeframe (1, 2, 4, 24). Requiere sesión. Incluye zoneId para abrir confirmación directa.
  Future<Map<String, Map<int, ({double maxOdd, int direction, int zoneId})>>> fetchMaxOdds(String currency) async {
    final response = await Common().postRequestWrapper('Info', 'MaxOdds', {
      'currency': currency.toUpperCase(),
    });
    if (response['statusCode'] != 200) {
      return {};
    }
    try {
      final raw = response['body'];
      final maxOddsMap = raw is Map ? (raw['maxOdds'] ?? raw['MaxOdds']) : null;
      if (maxOddsMap is! Map) return {};
      final result = <String, Map<int, ({double maxOdd, int direction, int zoneId})>>{};
      for (final entry in maxOddsMap.entries) {
        final ticker = entry.key as String;
        final byTf = entry.value;
        if (byTf is! Map) continue;
        final inner = <int, ({double maxOdd, int direction, int zoneId})>{};
        for (final tfEntry in byTf.entries) {
          final tf = int.tryParse(tfEntry.key.toString());
          if (tf == null) continue;
          final v = tfEntry.value;
          if (v is Map) {
            final maxOddVal = v['maxOdd'] ?? v['MaxOdd'];
            final maxOdd = maxOddVal is num ? maxOddVal.toDouble() : 1.0;
            final dirVal = v['direction'] ?? v['Direction'];
            final direction = dirVal is num ? dirVal.toInt() : 0;
            final zoneIdVal = v['zoneId'] ?? v['ZoneId'];
            final zoneId = zoneIdVal is num ? zoneIdVal.toInt() : 0;
            inner[tf] = (maxOdd: maxOdd, direction: direction, zoneId: zoneId);
          }
        }
        if (inner.isNotEmpty) result[ticker] = inner;
      }
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('[BetsService] fetchMaxOdds parse error: $e');
      }
      return {};
    }
  }

  Future<Trends> fetchTrendsData(String userId, String currency) async {
    final response =
        await Common().postRequestWrapper('Info', 'Trends', {
          'userId': userId,
          'currency': currency,
        });

    if (response['statusCode'] == 200) {
      try {
        final raw = response['body'];
        final list = raw is Map ? (raw['trends'] ?? raw['Trends']) : null;
        final items = list is List ? list : <dynamic>[];
        final trends = items
            .map((json) => Trend.fromJson(json as Map<String, dynamic>))
            .toList();
        if (kDebugMode) {
          print('[BetsService] fetchTrendsData OK: ${trends.length} trends');
        }
        return Trends(trends, trends.length);
      } catch (e) {
        if (kDebugMode) {
          print('[BetsService] fetchTrendsData parse error: $e');
        }
        return Trends([], 0);
      }
    } else {
      if (kDebugMode) {
        print('[BetsService] fetchTrendsData HTTP ${response['statusCode']}: ${response['body']}');
      }
      return Trends([], 0);
    }
  }

  Future<Map<String, dynamic>> getUserInfo(String id) async {
    final response =
        await Common().postRequestWrapper('Info', 'UserInfo', {'userId': id});

    if (response['statusCode'] == 200) {
      final Map<String, dynamic> decodedBody = response['body'];

      await _storage.write(key: 'fullname', value: decodedBody['fullname'] ?? '');
      await _storage.write(key: 'username', value: decodedBody['username'] ?? '');
      await _storage.write(key: 'isverified', value: decodedBody['isverified']?.toString() ?? 'false');
      await _storage.write(key: 'email', value: decodedBody['email'] ?? '');
      await _storage.write(key: 'birthday', value: decodedBody['birthday']?.toString() ?? '');
      await _storage.write(key: 'country', value: decodedBody['country'] ?? '');
      await _storage.write(key: 'lastsession', value: decodedBody['lastsession']?.toString() ?? '');
      
      // Manejar profilepic: si es null o vacío, eliminar del storage en lugar de guardar "null"
      final profilePic = decodedBody['profilepic'];
      if (profilePic != null && 
          profilePic.toString().isNotEmpty && 
          profilePic.toString().trim().isNotEmpty &&
          profilePic.toString().toLowerCase() != 'null') {
        await _storage.write(key: 'profilepic', value: profilePic.toString());
        if (kDebugMode) {
          print('[BetsService] Profile pic saved to storage. Length: ${profilePic.toString().length}');
        }
      } else {
        await _storage.delete(key: 'profilepic');
        if (kDebugMode) {
          print('[BetsService] Profile pic is null or empty. Deleted from storage.');
        }
      }
      
      await _storage.write(key: 'points', value: decodedBody['points']?.toString() ?? '0');
      return {'success': true, 'message': decodedBody['message']};
    } else {
      return {'success': false, 'message': response['body']['message']};
    }
  }

  /// Fetches daily login reward status. Returns map with showDialog, currentDay, canClaim, coinsForCurrentDay, rewardsByDay.
  Future<Map<String, dynamic>?> getDailyRewardStatus(String userId) async {
    if (kDebugMode) debugPrint('[DAILY_REWARD API] getDailyRewardStatus REQUEST userId=$userId -> Info/DailyRewardStatus');
    final response = await Common().postRequestWrapper('Info', 'DailyRewardStatus', {'userId': userId});
    if (kDebugMode) debugPrint('[DAILY_REWARD API] getDailyRewardStatus RESPONSE statusCode=${response['statusCode']} body=${response['body']}');
    if (response['statusCode'] == 200 && response['body'] is Map) {
      final body = response['body'] as Map<String, dynamic>;
      final result = {
        'showDialog': body['showDialog'] == true,
        'currentDay': (body['currentDay'] is int) ? body['currentDay'] as int : (body['currentDay'] as num?)?.toInt() ?? 1,
        'canClaim': body['canClaim'] == true,
        'coinsForCurrentDay': (body['coinsForCurrentDay'] is int) ? body['coinsForCurrentDay'] as int : (body['coinsForCurrentDay'] as num?)?.toInt() ?? 5,
        'nextAvailableAtUtc': body['nextAvailableAtUtc']?.toString(),
        'rewardsByDay': (body['rewardsByDay'] as List?)?.map((e) => (e is int) ? e : (e as num).toInt()).toList() ?? [5, 10, 15, 25, 40, 50],
      };
      if (kDebugMode) debugPrint('[DAILY_REWARD API] getDailyRewardStatus PARSED result=$result');
      return result;
    }
    if (kDebugMode) debugPrint('[DAILY_REWARD API] getDailyRewardStatus returning null (bad status or body)');
    return null;
  }

  /// Claims the daily login reward. Returns map with success, coinsAwarded, newStreakDay, message.
  Future<Map<String, dynamic>> claimDailyReward(String userId) async {
    if (kDebugMode) debugPrint('[DAILY_REWARD API] claimDailyReward REQUEST userId=$userId -> Info/ClaimDailyReward');
    final response = await Common().postRequestWrapper('Info', 'ClaimDailyReward', {'userId': userId});
    if (kDebugMode) debugPrint('[DAILY_REWARD API] claimDailyReward RESPONSE statusCode=${response['statusCode']} body=${response['body']}');
    if (response['statusCode'] == 200 && response['body'] is Map) {
      final body = response['body'] as Map<String, dynamic>;
      final result = {
        'success': body['success'] == true,
        'coinsAwarded': (body['coinsAwarded'] is int) ? body['coinsAwarded'] as int : (body['coinsAwarded'] as num?)?.toInt() ?? 0,
        'newStreakDay': (body['newStreakDay'] is int) ? body['newStreakDay'] as int : (body['newStreakDay'] as num?)?.toInt() ?? 1,
        'message': body['message']?.toString() ?? '',
      };
      if (kDebugMode) debugPrint('[DAILY_REWARD API] claimDailyReward PARSED result=$result');
      return result;
    }
    final fallback = {
      'success': false,
      'coinsAwarded': 0,
      'newStreakDay': 0,
      'message': (response['body'] is Map ? (response['body'] as Map)['message'] : null)?.toString() ?? 'Claim failed',
    };
    if (kDebugMode) debugPrint('[DAILY_REWARD API] claimDailyReward returning fallback (not 200 or not Map): $fallback');
    return fallback;
  }

  Future<bool> uploadProfilePic(String? id, String? profilepic) async {
    final response = await Common().postRequestWrapper(
        'Info', 'UploadPic', {'userId': id, 'profilePic': profilepic});

    if (response['statusCode'] == 200) {
      await _storage.write(key: 'profilepic', value: profilepic);
      return true;
    } else {
      return false;
    }
  }

  /// Actualiza el modo privado del usuario en el servidor (columna private del modelo users).
  Future<bool> setUserPrivate(String? userId, bool isPrivate) async {
    final response = await Common().postRequestWrapper(
      'Info',
      'SetUserPrivate',
      {'userId': userId, 'isPrivate': isPrivate},
    );
    return response['statusCode'] == 200;
  }

  Future<List<Candle>> fetchCandles(String symbol, int hoursTimeframe, String currency) async {
    final finalCurrency = Common().isTickerForex(symbol) ? 'EUR' : currency;

    final response = await Common().postRequestWrapper(
      'FinancialAssets',
      'FetchCandles',
      {
        'ticker': symbol,
        'timeframe': hoursTimeframe,
        'currency': finalCurrency,
      },
    );

    if (response['statusCode'] != 200) {
      return _fallbackCandles();
    }

    final body = response['body'];
    final List<dynamic> jsonList = body is List
        ? body
        : (body is Map && body['candles'] is List)
            ? body['candles'] as List
            : <dynamic>[];

    if (jsonList.isEmpty) {
      return _fallbackCandles();
    }

    double toDouble(dynamic v) => (v == null) ? 0.0 : (v as num).toDouble();

    final candlesList = <Candle>[];
    final nowFallback = DateTime.now().toUtc();
    for (final c in jsonList) {
      if (c is! Map<String, dynamic>) continue;
      final m = c;
      DateTime date;
      try {
        final dt = m['dateTime'];
        date = (dt != null && dt.toString().trim().isNotEmpty)
            ? DateTime.parse(dt.toString())
            : nowFallback;
      } catch (_) {
        date = nowFallback;
      }
      candlesList.add(Candle(
        date: date,
        open: toDouble(m['open']),
        high: toDouble(m['high']),
        low: toDouble(m['low']),
        close: toDouble(m['close']),
        volume: 0,
      ));
    }

    if (candlesList.isEmpty) {
      return _fallbackCandles();
    }
    if (candlesList.length == 1) {
      final first = candlesList.first;
      candlesList.add(Candle(
        date: first.date.subtract(const Duration(hours: 1)),
        open: first.open,
        high: first.high,
        low: first.low,
        close: first.close,
        volume: first.volume,
      ));
    }

    return candlesList;
  }

  List<Candle> _fallbackCandles() {
    final now = DateTime.now();
    return [
      Candle(date: now, open: 1, close: 1, high: 1, low: 1, volume: 1),
      Candle(date: now.subtract(const Duration(hours: 1)), open: 1, close: 1, high: 1, low: 1, volume: 1),
    ];
  }

}
