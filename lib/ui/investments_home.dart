// ignore_for_file: constant_identifier_names

import 'dart:ui';

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
    var myWallet = 1647.25;
    var totalStaked = 128.45;

    Future<String> getUserId() async {
      return await _storage.read(key: "sessionToken") ?? "none";
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              strings?.totalBet ?? 'My account',
              style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 180,
                      height: 60,
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 20),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                            width: 1),
                        borderRadius: BorderRadius.circular(8),
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.black
                            : Colors.white,
                      ),
                      child: AutoSizeText(
                        '${myWallet.toString()}€',
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                      ),
                    ),
                    Positioned(
                      left: 10,
                      top: -16,
                      child: Container(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.black
                            : Colors.white,
                        padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                        child: Text(
                          strings?.wallet ?? 'My wallet',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 180,
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 20),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                            width: 1),
                        borderRadius: BorderRadius.circular(8),
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.black
                            : Colors.white,
                      ),
                      child: AutoSizeText(
                        '${totalStaked.toString()}€',
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Positioned(
                      left: 10,
                      top: -16,
                      child: Container(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.black
                            : Colors.white,
                        padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                        child: Text(
                          strings?.staked ?? 'Staked',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              strings?.liveBets ?? 'Live bets',
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
              flex: 4,
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
                                itemCount: data.investList.length,
                                itemBuilder: (context, index) {
                                  return Column(
                                    children: <Widget>[
                                      ListTile(
                                        leading: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(20.0),
                                          child: Image.asset(
                                            data.investList[index].iconPath,
                                            width: 42,
                                            height: 42,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        title: RichText(
                                          text: TextSpan(
                                            style: DefaultTextStyle.of(context)
                                                .style,
                                            children: <TextSpan>[
                                              TextSpan(
                                                text:
                                                    '${data.investList[index].name} ',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        subtitle: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '(${data.investList[index].betAmount.toStringAsFixed(2)}€ @ ${data.investList[index].originValue})',
                                                style: const TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 15,
                                                ),
                                              ),
                                              Text(
                                                '${data.investList[index].targetDate.year}-'
                                                '${data.investList[index].targetDate.month}-'
                                                '${data.investList[index].targetDate.day} @ ${data.investList[index].targetValue} ± ${data.investList[index].targetMargin}%',
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: Theme.of(context)
                                                                .brightness ==
                                                            Brightness.dark
                                                        ? const Color.fromRGBO(
                                                            4, 216, 195, 1)
                                                        : Colors.deepPurple,
                                                    fontStyle:
                                                        FontStyle.italic),
                                              ),
                                            ]),
                                        trailing: Container(
                                          padding: const EdgeInsets.fromLTRB(
                                              6.0, 2.0, 6.0, 2.0),
                                          decoration: BoxDecoration(
                                            color:
                                                Theme.of(context).brightness ==
                                                        Brightness.dark
                                                    ? Colors.black
                                                    : Colors.white,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.grey
                                                    .withOpacity(0.5),
                                                spreadRadius: 1,
                                                blurRadius: 1,
                                                offset: const Offset(0, 0),
                                              ),
                                            ],
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                data.investList[index]
                                                        .targetWon!
                                                    ? '✔ ${data.investList[index].currentValue}€'
                                                    : '❌ ${data.investList[index].currentValue}€',
                                                style: TextStyle(
                                                  color: data.investList[index]
                                                          .targetWon!
                                                      ? Colors.green
                                                      : Colors.red,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              Text(
                                                data.investList[index]
                                                            .profitLoss! >
                                                        0
                                                    ? '+${data.investList[index].profitLoss}€'
                                                    : '${data.investList[index].profitLoss}€',
                                                style: TextStyle(
                                                  color: data.investList[index]
                                                              .profitLoss! >
                                                          0
                                                      ? Colors.green
                                                      : Colors.red,
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );
                            } else {
                              return Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20.0),
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
              strings?.recentBets ?? 'Recent bets',
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
              flex: 2,
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
                                itemCount: data.investList.length,
                                itemBuilder: (context, index) {
                                  return Column(
                                    children: <Widget>[
                                      ListTile(
                                        leading: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(20.0),
                                          child: Image.asset(
                                            data.investList[index].iconPath,
                                            width: 42,
                                            height: 42,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        title: RichText(
                                          text: TextSpan(
                                            style: DefaultTextStyle.of(context)
                                                .style,
                                            children: <TextSpan>[
                                              TextSpan(
                                                text:
                                                    '${data.investList[index].name} ',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        subtitle: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '(${data.investList[index].betAmount.toStringAsFixed(2)}€ @ ${data.investList[index].originValue})',
                                                style: const TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 15,
                                                ),
                                              ),
                                              Text(
                                                '${data.investList[index].targetDate.year}-'
                                                '${data.investList[index].targetDate.month}-'
                                                '${data.investList[index].targetDate.day} @ ${data.investList[index].targetValue} ± ${data.investList[index].targetMargin}%',
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: Theme.of(context)
                                                                .brightness ==
                                                            Brightness.dark
                                                        ? const Color.fromRGBO(
                                                            4, 216, 195, 1)
                                                        : Colors.deepPurple,
                                                    fontStyle:
                                                        FontStyle.italic),
                                              ),
                                            ]),
                                        trailing: Container(
                                          padding: const EdgeInsets.fromLTRB(
                                              6.0, 2.0, 6.0, 2.0),
                                          decoration: BoxDecoration(
                                            color:
                                                Theme.of(context).brightness ==
                                                        Brightness.dark
                                                    ? Colors.black
                                                    : Colors.white,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.grey
                                                    .withOpacity(0.5),
                                                spreadRadius: 1,
                                                blurRadius: 1,
                                                offset: const Offset(0, 0),
                                              ),
                                            ],
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                data.investList[index]
                                                        .targetWon!
                                                    ? '✔ ${data.investList[index].currentValue}€'
                                                    : '❌ ${data.investList[index].currentValue}€',
                                                style: TextStyle(
                                                  color: data.investList[index]
                                                          .targetWon!
                                                      ? Colors.green
                                                      : Colors.red,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              Text(
                                                data.investList[index]
                                                            .profitLoss! >
                                                        0
                                                    ? '+${data.investList[index].profitLoss}€'
                                                    : '${data.investList[index].profitLoss}€',
                                                style: TextStyle(
                                                  color: data.investList[index]
                                                              .profitLoss! >
                                                          0
                                                      ? Colors.green
                                                      : Colors.red,
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );
                            } else {
                              return Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 30),
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

class Dynamic {}

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
