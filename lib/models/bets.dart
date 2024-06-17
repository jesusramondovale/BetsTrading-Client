import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../helpers/common.dart';

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
          onTap: () =>
              Common().unimplementedAction(context, '(Recent bet info)'),
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