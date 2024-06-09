// ignore_for_file: constant_identifier_names, file_names

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../ui/home_page.dart';

class BetsService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  //static const PRIVATE_IP = '192.168.1.37';
  static const PUBLIC_DOMAIN = '108.pool90-175-130.dynamic.orange.es';
  static const API_URL = 'https://$PUBLIC_DOMAIN:44346/api/Info';

  Future<Bets> fetchInvestmentData(String userId) async {
    try {
      final Map<String, dynamic> data = {'id': userId};
      bool certificateCheck(X509Certificate cert, String host, int port) =>
          true;
      HttpClient client = HttpClient()
        ..badCertificateCallback = certificateCheck;

      final HttpClientRequest request =
          await client.postUrl(Uri.parse("$API_URL/UserBets"));
      request.headers.set('Content-Type', 'application/json');
      request.write(jsonEncode(data));

      final HttpClientResponse response = await request.close();

      if (response.statusCode == 200) {
        final String responseBody =
            await response.transform(utf8.decoder).join();
        final Map<String, dynamic> decodedBody = jsonDecode(responseBody);

        List<Bet> bets = (decodedBody['bets'] as List)
            .map((json) => Bet.fromJson(json))
            .toList();

        double totalBetAmount =
            bets.fold(0, (sum, item) => sum + item.betAmount);
        double totalProfit =
            bets.fold(0, (sum, item) => sum + item.profitLoss!);

        return Bets(totalBetAmount, totalProfit, bets.length, investList: bets);
      } else {
        return Bets(0, 0, 0, investList: []);
      }
    } on SocketException catch (e) {
      if (e.osError?.errorCode == 111) {
        return Bets(0, 0, 0, investList: []);
      }
      if (e.osError?.errorCode == 7) {
        return Bets(0, 0, 0, investList: []);
      }
      return Bets(0, 0, 0, investList: []);
    } catch (e) {
      return Bets(0, 0, 0, investList: []);
    }
  }

  Future<Trends> fetchTrendsData(String userId) async {

    try {
      final Map<String, dynamic> data = {'id': userId};
      bool certificateCheck(X509Certificate cert, String host, int port) =>
          true;
      HttpClient client = HttpClient()
        ..badCertificateCallback = certificateCheck;

      final HttpClientRequest request =
      await client.postUrl(Uri.parse("$API_URL/Trends"));
      request.headers.set('Content-Type', 'application/json');
      request.write(jsonEncode(data));

      final HttpClientResponse response = await request.close();

      if (response.statusCode == 200) {
        final String responseBody =
        await response.transform(utf8.decoder).join();
        final Map<String, dynamic> decodedBody = jsonDecode(responseBody);

        List<Trend> trends = (decodedBody['trends'] as List)
            .map((json) => Trend.fromJson(json))
            .toList();

        return Trends(trends, trends.length);
      } else {
        return Trends([], 0);
      }
    } on SocketException catch (e) {
      if (e.osError?.errorCode == 111) {
        return Trends([], 0);
      }
      if (e.osError?.errorCode == 7) {
        return Trends([], 0);
      }
      return Trends([], 0);
    } catch (e) {
      return Trends([], 0);
    }

  }

  Future<Bets> fakeFetchInvestmentData() async {
    await Future.delayed(const Duration(milliseconds: 50));

    List<Bet> investments = [
      Bet(
        48.0,
        false,
        -500.0,
        name: 'Core S&P 500 USD (Acc)',
        iconPath: 'assets/sp.png',
        originValue: 45,
        targetValue: 49.18,
        betAmount: 500,
        targetMargin: 0.05,
        targetDate: DateTime.now().add(const Duration(days: 5)),
        targetOdds: 1.75,
      ),
      Bet(
        1555,
        false,
        -1200,
        name: 'MSCI World',
        iconPath: 'assets/msci.png',
        originValue: 1650,
        targetValue: 1600,
        betAmount: 1200,
        targetMargin: 0.1,
        targetDate: DateTime.now().add(const Duration(days: 15)),
        targetOdds: 3.75,
      ),
      Bet(
        1.11,
        true,
        300,
        name: 'FOREX (EURUSD)',
        iconPath: 'assets/forex.png',
        originValue: 1.08,
        targetValue: 1.10,
        betAmount: 300,
        targetMargin: 0.1,
        targetDate: DateTime.now().add(const Duration(days: 3)),
        targetOdds: 1.65,
      ),
      Bet(
        751,
        false,
        -300,
        name: 'iShares NASDAQ',
        iconPath: 'assets/nasdaq.png',
        originValue: 750.56,
        targetValue: 755,
        betAmount: 300,
        targetMargin: 0.1,
        targetDate: DateTime.now().add(const Duration(days: 3)),
        targetOdds: 1.65,
      ),
      Bet(
        35500,
        true,
        4050,
        name: 'Bitcoin',
        iconPath: 'assets/bitcoin.png',
        originValue: 35000,
        targetValue: 35500,
        betAmount: 1200,
        targetMargin: 0.1,
        targetDate: DateTime.now().add(const Duration(days: 3)),
        targetOdds: 3.65,
      ),
      Bet(
        1.11,
        true,
        300,
        name: 'FOREX (EURUSD)',
        iconPath: 'assets/forex.png',
        originValue: 1.09,
        targetValue: 1.15,
        betAmount: 3000,
        targetMargin: 0.01,
        targetDate: DateTime.now().add(const Duration(days: 7)),
        targetOdds: 7.65,
      ),
      Bet(
        751,
        false,
        -300,
        name: 'Core S&P 500 USD (Acc)',
        iconPath: 'assets/sp.png',
        originValue: 45,
        targetValue: 49.18,
        betAmount: 500,
        targetMargin: 0.05,
        targetDate: DateTime.now().add(const Duration(days: 5)),
        targetOdds: 1.75,
      ),
      Bet(
        751,
        false,
        -300,
        name: 'MSCI World',
        iconPath: 'assets/msci.png',
        originValue: 1650,
        targetValue: 1600,
        betAmount: 1200,
        targetMargin: 0.1,
        targetDate: DateTime.now().add(const Duration(days: 15)),
        targetOdds: 3.75,
      ),
      Bet(
        1.11,
        true,
        300,
        name: 'FOREX (EURUSD)',
        iconPath: 'assets/forex.png',
        originValue: 1.09,
        targetValue: 1.15,
        betAmount: 3000,
        targetMargin: 0.01,
        targetDate: DateTime.now().add(const Duration(days: 7)),
        targetOdds: 7.65,
      ),
      Bet(
        751,
        false,
        -300,
        name: 'iShares NASDAQ',
        iconPath: 'assets/nasdaq.png',
        originValue: 1650,
        targetValue: 1600,
        betAmount: 300,
        targetMargin: 0.1,
        targetDate: DateTime.now().add(const Duration(days: 3)),
        targetOdds: 1.65,
      ),
    ];

    double totalBetAmount =
        investments.fold(0, (sum, item) => sum + item.betAmount);
    double totalProfit =
        investments.fold(0, (sum, item) => sum + item.profitLoss!);

    return Bets(totalBetAmount, totalProfit, investments.length,
        investList: investments);
  }

  Future<Map<String, dynamic>> getUserInfo(String id) async {
    try {
      final Map<String, dynamic> data = {'id': id};
      bool certificateCheck(X509Certificate cert, String host, int port) =>
          true;
      HttpClient client = HttpClient()
        ..badCertificateCallback = (certificateCheck);

      final HttpClientRequest request =
          await client.postUrl(Uri.parse("$API_URL/UserInfo"));
      request.headers.set('Content-Type', 'application/json');
      request.write(jsonEncode(data));

      final HttpClientResponse response = await request.close();

      if (response.statusCode == 200) {
        final String responseBody =
            await response.transform(utf8.decoder).join();
        final Map<String, dynamic> decodedBody = jsonDecode(responseBody);
        final String fullname = decodedBody['fullname'];
        final String username = decodedBody['username'];
        final String email = decodedBody['email'];
        final String birthday = decodedBody['birthday'];
        final String address = decodedBody['address'];
        final String country = decodedBody['country'];
        final String? profilepic = decodedBody['profilepic'];
        final String lastsession = decodedBody['lastsession'];

        await _storage.write(key: 'fullname', value: fullname);
        await _storage.write(key: 'username', value: username);
        await _storage.write(key: 'email', value: email);
        await _storage.write(key: 'birthday', value: birthday);
        await _storage.write(key: 'address', value: address);
        await _storage.write(key: 'country', value: country);
        await _storage.write(key: 'lastsession', value: lastsession);
        await _storage.write(key: 'profilepic', value: profilepic);

        return {'success': true, 'message': decodedBody['message']};
      } else {
        final String responseBody =
            await response.transform(utf8.decoder).join();
        final Map<String, dynamic> decodedBody = jsonDecode(responseBody);
        return {'success': false, 'message': decodedBody['message']};
      }
    } on SocketException catch (e) {
      if (e.osError?.errorCode == 111) {
        //Connection Refused
        return {
          'success': false,
          'message': "Server not responding. Try again later"
        };
      }
      if (e.osError?.errorCode == 7) {
        // Can't resolve -> No internet (DNS) access
        return {
          'success': false,
          'message': "Can't connect. Check your internet connection"
        };
      }
      return {
        'success': false,
        'message': "Server not responding. Try again later"
      };
    } catch (e) {
      return {'success': false, 'message': '$e'};
    }
  }

  Future<bool> uploadProfilePic(String? id, String? profilepic) async {
    try {
      final Map<String, dynamic> data = {'id': id, 'profilePic': profilepic};
      bool certificateCheck(X509Certificate cert, String host, int port) =>
          true;
      HttpClient client = HttpClient()
        ..badCertificateCallback = (certificateCheck);

      final HttpClientRequest request =
          await client.postUrl(Uri.parse("$API_URL/UploadPic"));
      request.headers.set('Content-Type', 'application/json');
      request.write(jsonEncode(data));

      final HttpClientResponse response = await request.close();

      if (response.statusCode == 200) {
        _storage.write(key: 'profilepic', value: profilepic);
        return true;
      } else {
        return false;
      }
    } on SocketException catch (e) {
      if (e.osError?.errorCode == 111) {
        //Connection Refused
        return false;
      }
      if (e.osError?.errorCode == 7) {
        // Can't resolve -> No internet (DNS) access
        return false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
