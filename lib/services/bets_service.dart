import 'dart:async';
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
      { 'user_id': userId,
        'token': betId,
        'currency': currency
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
            'id': "$betId",
            'timeframe' : "$hoursTimeframe",
            'currency' : currency
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
          'id': ticker,
          'timeframe': "$hoursTimeframe",
          'currency' : currency
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
    await Common().postRequestWrapper('Bet', 'UserBets',
        {'id': userId,
        'timeframe': 1, //USELESS
        'currency': currency});
    final priceBetsResponse =
    await Common().postRequestWrapper('Bet', 'PriceBets', {'id': userId});

    final List<Bet> bets = (betsResponse['statusCode'] == 200 &&
        betsResponse['body']?['bets'] is List)
        ? (betsResponse['body']['bets'] as List)
        .map((json) => Bet.fromJson(json))
        .toList()
        : <Bet>[];

    final List<PriceBet> priceBets = (priceBetsResponse['statusCode'] == 200 &&
        priceBetsResponse['body']?['bets'] is List)
        ? (priceBetsResponse['body']['bets'] as List)
        .map((json) => PriceBet.fromJson(json))
        .toList()
        : <PriceBet>[];

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
    final response =
        await Common().postRequestWrapper('Info', 'Favorites',
            {'id': userId,
            'timeframe': 1, //USELESS
            'currency': currency});
    if (response['statusCode'] == 200) {
      List<Favorite> favorites = (response['body']['favorites'] as List)
          .map((json) => Favorite.fromJson(json))
          .toList();

      return Favorites(favorites, favorites.length);
    } else {
      return Favorites([], 0);
    }
  }

  Future<bool> postNewBet(String userId, String fcm, String ticker, double betAmount,double originValue, int betZone, String currency) async {
    final response = await Common().postRequestWrapper('Bet', 'NewBet', {
      'user_id': userId,
      'fcm': fcm,
      'ticker': ticker,
      'bet_amount': betAmount,
      'origin_value': originValue,
      'bet_zone': betZone,
      'currency': currency
    });

    return response['statusCode'] == 200;
  }

  Future<int> postNewExactPriceBet(String userId, String fcm, String ticker, double priceBet,
      double margin, DateTime endDate, String currency) async {

    final Map<String, dynamic> data = {
      'user_id': userId,
      'fcm' : fcm,
      'ticker': ticker,
      'currency' : currency,
      'price_bet': priceBet,
      'margin': margin,
      'end_date': endDate.toIso8601String()
    };
    final response = await Common().postRequestWrapper('Bet', 'NewPriceBet', data);
    return response['statusCode'];
  }

  Future<bool> postNewFavorite(String userId, String ticker) async {
    final response = await Common().postRequestWrapper(
        'Info', 'NewFavorite', {'user_id': userId, 'ticker': ticker});
    return response['statusCode'] == 200;
  }

  Future<bool> deleteRecentBet(String betId) async {
    final response = await Common()
        .postRequestWrapper('Bet', 'DeleteRecentBet', {'id': betId});
    return response['statusCode'] == 200;
  }

  Future<bool> deleteRecentPriceBet(String priceBetId, String currency) async {
    final response = await Common()
        .postRequestWrapper('Bet', 'DeleteRecentPriceBet',
        {'id': priceBetId,
         'timeframe' : 1, //USELESS,
          'currency': currency
        });
    return response['statusCode'] == 200;
  }

  Future<bool> deleteHistoricBets(String userId) async {
    final response = await Common()
        .postRequestWrapper('Bet', 'DeleteHistoricBet', {'id': userId});
    return response['statusCode'] == 200;
  }

  Future<Trends> fetchTrendsData(String userId, String currency) async {
    final response =
        await Common().postRequestWrapper('Info', 'Trends',
            {'id': userId,
            'timeframe': 1,
            'currency' : currency});

    if (response['statusCode'] == 200) {
      List<Trend> trends = (response['body']['trends'] as List)
          .map((json) => Trend.fromJson(json))
          .toList();

      return Trends(trends, trends.length);
    } else {
      return Trends([], 0);
    }
  }

  Future<Map<String, dynamic>> getUserInfo(String id) async {
    final response =
        await Common().postRequestWrapper('Info', 'UserInfo', {'id': id});

    if (response['statusCode'] == 200) {
      final Map<String, dynamic> decodedBody = response['body'];

      await _storage.write(key: 'fullname', value: decodedBody['fullname']);
      await _storage.write(key: 'username', value: decodedBody['username']);
      await _storage.write(key: 'isverified', value: decodedBody['isverified'].toString());
      await _storage.write(key: 'email', value: decodedBody['email']);
      await _storage.write(key: 'birthday', value: decodedBody['birthday']);
      await _storage.write(key: 'country', value: decodedBody['country']);
      await _storage.write(key: 'lastsession', value: decodedBody['lastsession']);
      await _storage.write(key: 'profilepic', value: decodedBody['profilepic']);
      await _storage.write(key: 'points', value: decodedBody['points'].toString());
      return {'success': true, 'message': decodedBody['message']};
    } else {
      return {'success': false, 'message': response['body']['message']};
    }
  }

  Future<bool> uploadProfilePic(String? id, String? profilepic) async {
    final response = await Common().postRequestWrapper(
        'Info', 'UploadPic', {'id': id, 'profilePic': profilepic});

    if (response['statusCode'] == 200) {
      await _storage.write(key: 'profilepic', value: profilepic);
      return true;
    } else {
      return false;
    }
  }

  Future<List<Candle>> fetchCandles(String symbol, int hoursTimeframe, String currency) async {
    final response = await Common().postRequestWrapper(
      'FinancialAssets',
      'FetchCandles',
      {
        'id': symbol,
        'timeframe': hoursTimeframe,
        // currency -> 'EUR' / 'USD'
        'currency': currency
      },
    );

    if (response['statusCode'] != 200) {
      return _fallbackCandles();
    }

    final List<dynamic> jsonList = response['body'];

    if (jsonList.isEmpty) {
      return _fallbackCandles();
    }

    final candlesList = jsonList.map((c) {
      return Candle(
        date: DateTime.parse(c['dateTime']),
        open: (c['open'] as num).toDouble(),
        high: (c['high'] as num).toDouble(),
        low: (c['low'] as num).toDouble(),
        close: (c['close'] as num).toDouble(),
        volume: 0,
      );
    }).toList();

    // Hack si solo hay una vela
    if (candlesList.length == 1) {
      final first = candlesList.first;
      candlesList.add(
        Candle(
          date: first.date.subtract(const Duration(hours: 1)),
          open: first.open,
          high: first.high,
          low: first.low,
          close: first.close,
          volume: first.volume,
        ),
      );
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
