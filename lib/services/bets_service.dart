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
        return Trends(trends, trends.length);
      } catch (e) {
        if (kDebugMode) {
          print('[BetsService] fetchTrendsData parse error: $e');
        }
        return Trends([], 0);
      }
    } else {
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
