import 'dart:convert';

import 'package:client_0_0_1/services/BetsService.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../helpers/common.dart';
import '../locale/localized_texts.dart';

class Bet {
  final int id;
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
        required this.id,
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
      : id = json['id'],
        name = json['name'],
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

class RecentBetContainer extends StatefulWidget {
  final Bet bet;
  final Function onDelete;
  const RecentBetContainer({super.key, required this.bet, required this.onDelete});

  @override
  RecentBetContainerState createState() => RecentBetContainerState();
}

class RecentBetContainerState extends State<RecentBetContainer>{

  bool _showEditButtons = false;

  void _triggerBetButtons() {
    setState(() {
      _showEditButtons = !_showEditButtons;
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = LocalizedStrings.of(context);
    String? trailingText = (widget.bet.profitLoss != null && widget.bet.profitLoss != 0.0)
        ? (widget.bet.profitLoss)?.toStringAsFixed(2)
        : '¿?';
    String currency = '€';

    /* TO-DO
    String currency = (bet.currency != null) ?
                                     bet.currency as String :
                                     '-';  */
    return Column(
      children: <Widget>[
        ListTile(
          onLongPress: _triggerBetButtons,
          onTap: () {
            (_showEditButtons) ?  _triggerBetButtons() : Common().unimplementedAction(context, '(Recent bet info)');
          },
          minVerticalPadding: 12,
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(5.0),
            child: Image.memory(
              base64Decode(widget.bet.iconPath),
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
                  text: '${widget.bet.name} ',
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
                '(${widget.bet.betAmount.toStringAsFixed(2)}€ @ ${widget.bet.originValue})',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 15,
                ),
              ),
              Text(
                '${widget.bet.targetDate.year}-${widget.bet.targetDate.month}-${widget.bet.targetDate.day} @ ${widget.bet.targetValue} ± ${widget.bet.targetMargin}%',
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
          trailing: _showEditButtons
              ? IntrinsicWidth(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.grey),
                  onPressed: () async {

                    final result = await  BetsService().deleteRecentBet((widget.bet.id).toString());

                    if (result) {
                      Common().actionDialog(context, strings?.removedSuccesfully ?? "Borrado con éxito!");
                      widget.onDelete();
                    } else {
                      Common().actionDialog(context, "Error!");
                    }
                  },
                  padding: const EdgeInsets.all(0),
                  constraints: const BoxConstraints(maxHeight: 30, maxWidth: 30),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          )
              : Text(
            '$trailingText$currency',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w300,
              color: widget.bet.targetWon == true ? Colors.green : Colors.red,
            ),
          ),
        ),
        Divider(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.black,
          height: 1,
          thickness: 0.1,
        ),
      ],
    );
  }
}