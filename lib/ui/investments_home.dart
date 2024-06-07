// ignore_for_file: constant_identifier_names


import 'dart:convert';
import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:client_0_0_1/locale/localized_texts.dart';
import 'package:client_0_0_1/services/BetsService.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class InvestmentScreen extends StatelessWidget {
  const InvestmentScreen({super.key});

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  //static const PRIVATE_IP = '192.168.1.37';
  static const PUBLIC_DOMAIN = '108.pool90-175-130.dynamic.orange.es';
  static const API_URL = 'https://$PUBLIC_DOMAIN:44346/api/Info';

  @override
  Widget build(BuildContext context) {
    final strings = LocalizedStrings.of(context);
    var myWallet = 16.847;

    Future<String> getUserId() async {
      return await _storage.read(key: "sessionToken") ?? "none";
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text(
                  strings?.totalBet ?? 'My account',
                  style: const TextStyle(
                      fontSize: 25, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Image.asset(
                  'assets/coin_icon.png',
                  width: 28,
                  height: 28,
                ),
                const SizedBox(width: 5),
                AutoSizeText(
                  myWallet.toString(),
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                ),
              ],
            ),
            const SizedBox(height: 20),

            Text(
              strings?.liveBets ?? 'Trends',
              style: const TextStyle(
                fontSize: 22,
              ),
            ),
            Divider(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
                thickness: 0.5,
                height: 0.5),
            Expanded(
              flex: 1,
              child: FutureBuilder<String>(
                  future: getUserId(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError || !snapshot.hasData) {
                      return const Center(child: Text("Error or no user ID"));
                    } else {
                      final userId = snapshot.data!;
                      return FutureBuilder<Bets>(
                          future: BetsService().fetchInvestmentData(userId),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            } else if (snapshot.hasError) {
                              return Text('Error: ${snapshot.error}');
                            } else if (snapshot.hasData &&
                                snapshot.data!.investList.isNotEmpty) {
                              final data = snapshot.data!;
                              return ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: data.investList.length,
                                itemBuilder: (context, index) {
                                  return BetContainer(
                                      bet: data.investList[index]);
                                },
                              );
                            } else {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        strings?.noLiveBets ??
                                            'You have no live bets at the moment, go to the markets tab to create a new one.',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 19,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 40),
                                      const Icon(
                                        Icons.auto_graph,
                                        size: 40,
                                        color: Colors.white,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                          });
                    }
                  }),
            ),
            const SizedBox(height: 15),
            Text(
              strings?.recentBets ?? 'Recent Bets',
              style: const TextStyle(
                fontSize: 22,
              ),
            ),
            Divider(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
                thickness: 0.5,
                height: 0.5),
            Expanded(
              flex: 1,
              child: FutureBuilder<String>(
                  future: getUserId(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError || !snapshot.hasData) {
                      return const Center(child: Text("Error or no user ID"));
                    } else {
                      final userId = snapshot.data!;
                      return FutureBuilder<Bets>(
                          future: BetsService().fetchInvestmentData(userId),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            } else if (snapshot.hasError) {
                              return Text('Error: ${snapshot.error}');
                            } else if (snapshot.hasData &&
                                snapshot.data!.investList.isNotEmpty) {
                              final data = snapshot.data!;
                              return ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: data.investList.length,
                                itemBuilder: (context, index) {
                                  List<Bet> shuffledList = List.from(data.investList);
                                  shuffledList.shuffle(Random());
                                  return BetContainer(bet:shuffledList[index]);
                                },
                              );
                            } else {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 30),
                                  child: Text(
                                    strings?.noClosedBets ??
                                        'No closed bets (for now ...) 😏',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 16.0,
                                      color: Colors.grey,
                                      letterSpacing: 0.5,
                                      wordSpacing: 1.0,
                                    ),
                                  ),
                                ),
                              );
                            }
                          });
                    }
                  }),
            ),
            const Row(
              children: [
                Text(
                  'Apuestas en DIRECTO',
                  style: TextStyle(
                    fontSize: 22,
                  ),
                ),
                SizedBox(width: 7,),
                Text(
                  '🔴',
                  style: TextStyle(
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            Divider(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
                thickness: 0.5,
                height: 0.5),
            Expanded(
              flex: 1,
              child: FutureBuilder<String>(
                  future: getUserId(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError || !snapshot.hasData) {
                      return const Center(child: Text("Error or no user ID"));
                    } else {
                      final userId = snapshot.data!;
                      return FutureBuilder<Bets>(
                          future: BetsService().fetchInvestmentData(userId),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            } else if (snapshot.hasError) {
                              return Text('Error: ${snapshot.error}');
                            } else if (snapshot.hasData &&
                                snapshot.data!.investList.isNotEmpty) {
                              final data = snapshot.data!;
                              return ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: data.investList.length,
                                itemBuilder: (context, index) {
                                 data.investList.shuffle(Random());
                                  return BetContainer(

                                      bet:data.investList[index]);
                                },
                              );
                            } else {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 30),
                                  child: Text(
                                    strings?.noClosedBets ??
                                        'No closed bets (for now ...) 😏',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 16.0,
                                      color: Colors.grey,
                                      letterSpacing: 0.5,
                                      wordSpacing: 1.0,
                                    ),
                                  ),
                                ),
                              );
                            }
                          });
                    }
                  }),
            ),
          ],
        ),
      ),
    );
  }
}

class BetContainer extends StatelessWidget {
  final Bet bet;

  const BetContainer({super.key, required this.bet});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.memory(base64Decode(bet.iconPath),
              height: 40,
              width: 40,
                         ),
            const SizedBox(height: 10),
            Text(
              bet.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              bet.profitLoss != null
                  ?
              bet.targetWon! ? '▲${bet.profitLoss!.toStringAsFixed(2)}%'
              : '▼${bet.profitLoss!.toStringAsFixed(2)}%'

                  : 'N/A',
              style: TextStyle(
                color: bet.targetWon == true ? Colors.green : Colors.red,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class Bets {
  final List<Bet> investList;
  final double totalBetAmount;
  final double totalProfit;
  final int length;

  Bets(this.totalBetAmount, this.totalProfit, this.length,
      {required this.investList});
}

class Bet {
  final String name;
  final String iconPath;

  final double betAmount;
  final double originValue;
  final double currentValue;
  final double targetValue;
  final double targetMargin;
  final DateTime targetDate;
  final double targetOdds;

  final bool? targetWon;
  final double? profitLoss;

  Bet(
    this.currentValue,
    this.targetWon,
    this.profitLoss, {
    required this.name,
    required this.iconPath,
    required this.betAmount,
    required this.originValue,
    required this.targetValue,
    required this.targetMargin,
    required this.targetDate,
    required this.targetOdds,
  });

  Bet.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        iconPath = json['icon_path'],
        betAmount = json['bet_amount'].toDouble(),
        originValue = json['origin_value'].toDouble(),
        currentValue = json['current_value'].toDouble(),
        targetValue = json['target_value'].toDouble(),
        targetMargin = json['target_margin'].toDouble(),
        targetDate = DateTime.parse(json['target_date']),
        targetOdds = json['target_odds'].toDouble(),
        targetWon = json['target_won'],
        profitLoss = json['target_won'] == true
            ? (json['bet_amount'].toDouble()) * (json['target_odds'].toDouble())
            : json['bet_amount'].toDouble() * (-1);
}
