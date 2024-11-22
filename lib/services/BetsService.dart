import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../candlesticks/src/models/candle.dart';
import '../helpers/common.dart';
import '../models/betZone.dart';
import '../models/bets.dart';
import '../models/favorites.dart';
import '../models/trends.dart';

class BetsService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<List<BetZone>> fetchBetZones(String ticker, int? betId) async {
    if (null != betId) {
      final response =
          await Common().postRequestWrapper('Bet', 'GetBetZone', {'id': betId});

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
        await Common().postRequestWrapper('Bet', 'GetBetZones', {'id': ticker});

    if (response['statusCode'] == 200) {
      List<BetZone> zones = (response['body']['bets'] as List)
          .map((json) => BetZone.fromJson(json))
          .toList();

      return zones;
    } else {
      return [];
    }
  }

  Future<Bets> fetchInvestmentData(String userId) async {
    final response =
        await Common().postRequestWrapper('Bet', 'UserBets', {'id': userId});

    if (response['statusCode'] == 200) {
      List<Bet> bets = (response['body']['bets'] as List)
          .map((json) => Bet.fromJson(json))
          .toList();

      double totalBetAmount = bets.fold(0, (sum, item) => sum + item.betAmount);
      double totalProfit = bets.fold(0, (sum, item) => sum + item.profitLoss!);

      return Bets(totalBetAmount, totalProfit, bets.length, investList: bets);
    } else {
      return Bets(0, 0, 0, investList: []);
    }
  }

  Future<Favorites> fetchFavouritesData(String userId) async {
    final response =
        await Common().postRequestWrapper('Info', 'Favorites', {'id': userId});
    if (response['statusCode'] == 200) {
      List<Favorite> favorites = (response['body']['favorites'] as List)
          .map((json) => Favorite.fromJson(json))
          .toList();

      return Favorites(favorites, favorites.length);
    } else {
      return Favorites([], 0);
    }
  }

  Future<bool> postNewBet(String userId, String ticker, double betAmount,
      double originValue, int betZone) async {
    final response = await Common().postRequestWrapper('Bet', 'NewBet', {
      'user_id': userId,
      'ticker': ticker,
      'bet_amount': betAmount,
      'origin_value': originValue,
      'bet_zone': betZone
    });

    return response['statusCode'] == 200;
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

  Future<bool> deleteHistoricBets(String userId) async {
    final response = await Common()
        .postRequestWrapper('Bet', 'DeleteHistoricBet', {'id': userId});
    return response['statusCode'] == 200;
  }

  Future<Trends> fetchTrendsData(String userId) async {
    final response =
        await Common().postRequestWrapper('Info', 'Trends', {'id': userId});

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
      await _storage.write(key: 'idCard', value: decodedBody['idcard']);
      await _storage.write(key: 'email', value: decodedBody['email']);
      await _storage.write(key: 'birthday', value: decodedBody['birthday']);
      await _storage.write(key: 'country', value: decodedBody['country']);
      await _storage.write(
          key: 'lastsession', value: decodedBody['lastsession']);
      await _storage.write(key: 'profilepic', value: decodedBody['profilepic']);
      await _storage.write(
          key: 'points', value: decodedBody['points'].toString());
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

  Future<List<Candle>> fetchCandles(String symbol) async {
    final response = await Common().postRequestWrapper(
      'FinancialAssets',
      'FetchCandles',
      {'id': symbol},
    );

    if (response['statusCode'] == 200) {
      final Map<String, dynamic> jsonData =
          response['body']; // Aquí asumes que ya es un Map

      final List<dynamic> closeList = jsonData['close'];
      final List<dynamic>? openList = jsonData['open'];
      final List<dynamic>? highList = jsonData['daily_max'];
      final List<dynamic>? lowList = jsonData['daily_min'];

      List<double> close = closeList.map((e) => (e as num).toDouble()).toList();
      List<double>? open = openList?.map((e) => (e as num).toDouble()).toList();
      List<double>? high = highList?.map((e) => (e as num).toDouble()).toList();
      List<double>? low = lowList?.map((e) => (e as num).toDouble()).toList();

      int length = close.length;
      if (open != null && open.length != length) {
        throw Exception('Mismatch in lengths of close and open lists');
      }
      if (high != null && high.length != length) {
        throw Exception('Mismatch in lengths of close and daily_max lists');
      }
      if (low != null && low.length != length) {
        throw Exception('Mismatch in lengths of close and daily_min lists');
      }

      List<Candle> candlesList = List.generate(length, (index) {
        final DateTime date = DateTime.now().subtract(Duration(
            days:
                index)); // Usar fechas dinámicas (ajustar si tienes fechas reales)
        return Candle(
          date: date,
          open: open?[index] ?? close[index], // Fallback si open es nulo
          high: high?[index] ?? close[index], // Fallback si high es nulo
          low: low?[index] ?? close[index], // Fallback si low es nulo
          close: close[index],
          volume: 0,
        );
      });

      if (candlesList.length == 1) {
        candlesList.add(Candle(
          date: DateTime.now(),
          open: 1.0,
          close: 1.0,
          high: 1.0,
          low: 1.0,
          volume: 1.0,
        ));
      }
      return candlesList;
    } else {
      // RETURN TWO FAKE CANDLES TO PREVENT GRAPH CRASHING
      List<Candle> candleList = [
        Candle(
          date: DateTime.now(),
          open: 1.0,
          close: 1.0,
          high: 1.0,
          low: 1.0,
          volume: 1.0,
        ),
        Candle(
          date: DateTime.now(),
          open: 1.0,
          close: 1.0,
          high: 1.0,
          low: 1.0,
          volume: 1.0,
        )
      ];
      return candleList;
    }
  }
}
