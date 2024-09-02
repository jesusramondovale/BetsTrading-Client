import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:client_0_0_1/services/BetsService.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../helpers/common.dart';
import '../locale/localized_texts.dart';
import '../ui/candlesticks_view.dart';
import '../ui/layout_page.dart';

class Bet {
  final int id;
  final String name;
  final String ticker;
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
    required this.ticker,
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
        ticker = json['ticker'],
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

class RecentBetDialog extends StatelessWidget {
  final Bet bet;
  final MainMenuPageController controller;

  RecentBetDialog({super.key, required this.bet, required this.controller});

  static get decodedBody => null;

  void showPopup(BuildContext context, String message, Offset position) {
    int xOffset;
    (message.length < 10) ?
      xOffset = -18 :
      xOffset = message.length - 15;

    OverlayEntry? overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: position.dx - xOffset,
        top: position.dy + 35,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.black.withOpacity(1) : Colors.grey[200]!,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Text(
              message,
              style: GoogleFonts.josefinSans(
                fontSize: 12,
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black
              )
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);

    Future.delayed(const Duration(milliseconds: 1200), () {
      overlayEntry?.remove();
    });
  }

  Widget _buildGridItem(BuildContext context, IconData icon, String value, String infoText,
      {Color color = Colors.white}) {
    GlobalKey key = GlobalKey();
    return GestureDetector(
      key: key,
      onTap: () {
        final renderBox = key.currentContext?.findRenderObject() as RenderBox;
        final position = renderBox.localToGlobal(Offset.zero);
        showPopup(context, infoText, position);
      },
      child: Tooltip(
        message: infoText,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 34,
              color: Colors.white70,
            ),
            Text(
              value,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = LocalizedStrings.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.black87
          : Colors.grey[800],
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.black
                    : Colors.white70,
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[900]!
                    : Colors.deepPurple
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),

            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: <Widget>[
                        if (bet.iconPath != "null") ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.memory(
                              base64Decode(bet.iconPath),
                              height: 100,
                              width: 100,
                            ),
                          ),
                        ] else ...[
                          AutoSizeText(
                            bet.name,
                            maxLines: 1,
                            style: GoogleFonts.josefinSans(
                              fontSize: 30,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ],
                        const Spacer(),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AutoSizeText(
                      bet.name,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.robotoCondensed(
                        fontSize: 30,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${bet.profitLoss!.toStringAsFixed(2)}€',
                          style: GoogleFonts.montserrat(
                            fontSize: 25,
                            fontWeight: FontWeight.w400,
                            color: bet.profitLoss! > 0.0
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    GridView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 15.0,
                        mainAxisSpacing: 15.0,
                        childAspectRatio: 2,
                      ),
                      children: [
                        _buildGridItem(
                          context,
                          Icons.casino,
                          '${bet.betAmount.toStringAsFixed(2)}€',
                            strings!.betAmount ?? "Bet amount"
                        ),
                        _buildGridItem(
                          context,
                          Icons.update,
                          '${bet.originValue.toStringAsFixed(2)}€',
                            strings.originValue ?? "Origin value"
                        ),
                        _buildGridItem(
                          context,
                          Icons.crop_sharp,
                          '${bet.targetValue.toStringAsFixed(2)}€',
                            strings.targetValue ?? "Target value"
                        ),
                        _buildGridItem(
                          context,
                          Icons.date_range,
                          DateFormat('dd-MM-yyyy').format(bet.targetDate),
                            strings.targetDate ?? "Target date"
                        ),
                        _buildGridItem(
                          context,
                          Icons.data_object_sharp,
                          '${bet.targetMargin.toStringAsFixed(2)}%',
                          strings.targetMargin ?? "Target margin"
                        ),
                        _buildGridItem(
                          context,
                          Icons.attach_money,
                          'x${bet.targetOdds.toStringAsFixed(2)}',
                          strings.winBonus ?? "Win bonus"
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(
                            size: 42,
                            Icons.auto_graph_sharp,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (BuildContext context) {
                                return ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(25.0),
                                  ),
                                  child: Container(
                                    color: Theme.of(context).scaffoldBackgroundColor,
                                    height: MediaQuery.of(context).size.height * 0.6,
                                    child: OverflowBox(
                                      alignment: Alignment.topCenter,
                                      maxHeight: MediaQuery.of(context).size.height,
                                      child: Column(
                                        children: [

                                          Expanded(
                                            child: CandlesticksView(ticker: bet.ticker.toString(), name: bet.name, controller: this.controller, iconPath: bet.iconPath),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RecentBetContainer extends StatefulWidget {
  final Bet bet;
  final Function onDelete;
  final MainMenuPageController controller;
  const RecentBetContainer(
      {super.key, required this.bet, required this.onDelete, required this.controller});

  @override
  RecentBetContainerState createState() => RecentBetContainerState();
}

class RecentBetContainerState extends State<RecentBetContainer> {
  bool _showEditButtons = false;

  void _triggerBetButtons() {
    setState(() {
      _showEditButtons = !_showEditButtons;
    });
  }

  void _showBetDialog() async {
    await showDialog<bool>(
      context: this.context,
      builder: (BuildContext context) {
        return RecentBetDialog(
          bet: widget.bet, controller: widget.controller,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = LocalizedStrings.of(context);
    String? trailingText =
        (widget.bet.profitLoss != null && widget.bet.profitLoss != 0.0)
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
            (_showEditButtons) ? _triggerBetButtons() : _showBetDialog();
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
                          final result = await BetsService()
                              .deleteRecentBet((widget.bet.id).toString());

                          if (result) {
                            Common().actionDialog(
                                context,
                                strings?.removedSuccesfully ??
                                    "Borrado con éxito!");
                            widget.onDelete();
                          } else {
                            Common().actionDialog(context, "Error!");
                          }
                        },
                        padding: const EdgeInsets.all(0),
                        constraints:
                            const BoxConstraints(maxHeight: 30, maxWidth: 30),
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
                    color: widget.bet.targetWon == true
                        ? Colors.green
                        : Colors.red,
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
