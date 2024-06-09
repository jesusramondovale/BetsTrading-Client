// ignore_for_file: constant_identifier_names, prefer_const_constructors

import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:client_0_0_1/locale/localized_texts.dart';
import 'package:client_0_0_1/services/BetsService.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../helpers/common.dart';
import 'candlesticks_view.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  //static const PRIVATE_IP = '192.168.1.37';
  static const PUBLIC_DOMAIN = '108.pool90-175-130.dynamic.orange.es';
  static const API_URL = 'https://$PUBLIC_DOMAIN:44346/api/Info';

  @override
  Widget build(BuildContext context) {
    final strings = LocalizedStrings.of(context);

    Future<String> getUserId() async {
      return await _storage.read(key: "sessionToken") ?? "none";
    }

    Locale locale = Localizations.localeOf(context);
    String formattedDate =
        DateFormat.yMMMMd(locale.toString()).format(DateTime.now());

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: [
                Spacer(),
                IconButton(
                  icon: Icon(Icons.remove_red_eye_sharp),
                  iconSize: 30,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                  onPressed: () { Common().unimplementedAction(context , '(View settings)'); },
                ),
                IconButton(
                  icon: Icon(Icons.local_grocery_store_rounded),
                  iconSize: 30,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                  onPressed: () { Common().unimplementedAction(context); },
                ),
              ],
            ),
            Row(
              children: <Widget>[
                Text(strings?.liveBets ?? 'Trends',
                    style: GoogleFonts.comfortaa(
                      fontSize: 24,
                      fontWeight: FontWeight.w400,
                    )),
                const Spacer(),
                const SizedBox(width: 5),
                AutoSizeText(
                  formattedDate,
                  style: GoogleFonts.dosis(
                    fontSize: 18,
                    fontWeight: Theme.of(context).brightness == Brightness.dark
                        ? FontWeight.w200
                        : FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
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
                      return FutureBuilder<Trends>(
                          future: BetsService().fetchTrendsData(userId),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            } else if (snapshot.hasError) {
                              return Text('Error: ${snapshot.error}');
                            } else if (snapshot.hasData &&
                                snapshot.data!.trends.isNotEmpty) {
                              final data = snapshot.data!;
                              return ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: data.length,
                                itemBuilder: (context, index) {
                                  List<Trend> sortedTrends =
                                      List.from(data.trends)
                                        ..sort((a, b) => a.id.compareTo(b.id));
                                  int sortedIndex = sortedTrends[index].id - 1;
                                  return TrendContainer(
                                      trend: sortedTrends[index],
                                      index: sortedIndex);
                                },
                              );
                            } else {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.wifi_off_sharp,
                                        size: 90,
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.white
                                            : Colors.black,
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
              style: GoogleFonts.comfortaa(
                  fontSize: 24, fontWeight: FontWeight.w400),
            ),
            Divider(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
                thickness: 0.5,
                height: 0.5),
            Expanded(
              flex: 5,
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
                                scrollDirection: Axis.vertical, //LMAO
                                itemCount: data.investList.length,
                                itemBuilder: (context, index) {
                                  return RecentBetContainer(
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
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 30),
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
          ],
        ),
      ),
    );
  }
}

class TrendContainer extends StatelessWidget {
  final Trend trend;
  final int index;

  const TrendContainer({super.key, required this.trend, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return TrendDialog(
                  trend: trend,
                  index: trend.id,
                );
              },
            );
          },
          splashColor: Colors.white24,
          highlightColor: Colors.white12,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 120,
            decoration: BoxDecoration(
              color: Colors.white12,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 1,
                  offset: const Offset(0, 1),
                ),
              ],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              children: [
                // Background number
                Positioned(
                  top: 20,
                  right: (index == 0 || index >= 9) ? -20 : -5,
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      letterSpacing: 0,
                      fontSize: 100,
                      color: Colors.white.withOpacity(0.1),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                // Main content
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.memory(
                        base64Decode(trend.icon),
                        height: 40,
                        width: 40,
                      ),
                      const Spacer(),
                      AutoSizeText(
                        trend.name,
                        maxLines: 1,
                        style: GoogleFonts.robotoCondensed(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        (trend.dailyGain > 0.0)
                            ? '▲ ${(trend.dailyGain).toStringAsFixed(2)}%'
                            : '▼ ${(trend.dailyGain.abs()).toStringAsFixed(2)}%',
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight:
                              Theme.of(context).brightness == Brightness.dark
                                  ? FontWeight.w200
                                  : FontWeight.w500,
                          color:
                              trend.dailyGain > 0.0 ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RecentBetContainer extends StatelessWidget {
  final Bet bet;
  const RecentBetContainer({super.key, required this.bet});

  @override
  Widget build(BuildContext context) {
    String? trailingText = (bet.profitLoss != null && bet.profitLoss != 0.0)
        ? (bet.profitLoss)?.toStringAsFixed(2)
        : '¿?';
    String currency = '€';

    /* TO-DO
    String currency = (bet.currency != null) ?
                                     bet.currency as String :
                                     '-';  */
    return Column(
      children: <Widget>[
        ListTile(
          onTap: () => Common().unimplementedAction(context , '(Recent bet info)'),
          minVerticalPadding: 12,
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(5.0),
            child: Image.memory(
              base64Decode(bet.iconPath),
              width: 50,
              height: 50,
              fit: BoxFit.cover,
            ),
          ),
          title: RichText(
            text: TextSpan(
              style: DefaultTextStyle.of(context).style,
              children: <TextSpan>[
                TextSpan(
                  text: '${bet.name} ',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '(${bet.betAmount.toStringAsFixed(2)}€ @ ${bet.originValue})',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 15,
                ),
              ),
              Text(
                '${bet.targetDate.year}-${bet.targetDate.month}-${bet.targetDate.day} @ ${bet.targetValue} ± ${bet.targetMargin}%',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: Theme.of(context).brightness == Brightness.dark
                      ? FontWeight.w100
                      : FontWeight.w300,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.cyanAccent
                      : Colors.deepPurple,
                ),
              ),
            ],
          ),
          trailing: Text(
            '$trailingText$currency',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w300,
              color: bet.targetWon == true ? Colors.green : Colors.red,
            ),
          ),
        ),
        Divider(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.black,
          height: 1,
          thickness: 0.25,
          indent: 80,
          endIndent: 80,
        ),
      ],
    );
  }
}

class Trend {
  final int id;
  final String name;
  final String icon;
  final double dailyGain;
  final double close;
  final double current;

  Trend(
      this.id, this.icon, this.dailyGain, this.name, this.close, this.current);

  Trend.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        name = json['name'],
        icon = json['icon'],
        dailyGain = json['daily_gain'],
        close = json['close'],
        current = json['current'];
}

class Trends {
  final List<Trend> trends;
  final int length;

  Trends(this.trends, this.length);
}

class TrendDialog extends StatelessWidget {
  final Trend trend;
  final int index;

  const TrendDialog({super.key, required this.trend, required this.index});

  @override
  Widget build(BuildContext context) {
    final strings = LocalizedStrings.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(52),
      ),
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.black
          : Colors.grey,
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Colors.white12.withOpacity(0.05),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black.withOpacity(1)
                  : Colors.grey,
              spreadRadius: 1,
              blurRadius: 2,
              offset: const Offset(0, 0),
            ),
          ],
          borderRadius: BorderRadius.circular(52),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Positioned(
                  top: 0,
                  right: (index == 0 || index >= 9) ? -40 : -25,
                  child: Text(
                    '$index',
                    style: TextStyle(
                      letterSpacing: 0,
                      fontSize: 240,
                      color: Colors.white.withOpacity(0.1),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: <Widget>[
                          Image.memory(
                            base64Decode(trend.icon),
                            height: 160,
                            width: 160,
                          ),
                          Spacer(),
                        ],
                      ),
                      const SizedBox(height: 16),
                      AutoSizeText(
                        trend.name,
                        maxLines: 1,
                        style: GoogleFonts.robotoCondensed(
                          fontSize: 40,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        (trend.dailyGain > 0.0)
                            ? '▲ ${(trend.dailyGain).toStringAsFixed(2)}%'
                            : '▼ ${(trend.dailyGain.abs()).toStringAsFixed(2)}%',
                        style: GoogleFonts.montserrat(
                          fontSize: 25,
                          fontWeight: FontWeight.w400,
                          color:
                              trend.dailyGain > 0.0 ? Colors.green : Colors.red,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${strings?.close ?? 'Close'}: ${trend.close.toStringAsFixed(2)}€',
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            '${strings?.current ?? 'Current'}: ${trend.current.toStringAsFixed(2)}€',
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: trend.dailyGain >= 0.0
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                          Spacer(),
                          IconButton(
                            icon: Icon(
                                size: 42,
                                Icons.auto_graph_sharp,
                                color: Colors.white),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SafeArea(
                                    child: CandlesticksView(1),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
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

class Bets {
  final List<Bet> investList;
  final double totalBetAmount;
  final double totalProfit;
  final int length;

  Bets(this.totalBetAmount, this.totalProfit, this.length,
      {required this.investList});
}
