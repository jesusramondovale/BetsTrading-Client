import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:betrader/services/BetsService.dart';
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
  final double dailyGain;
  final double betAmount;
  final double originValue;
  final double currentValue;
  final double targetValue;
  final double targetMargin;
  final DateTime targetDate;
  final DateTime endDate;
  final double targetOdds;
  final int bet_zone;
  final bool? targetWon;
  final double? profitLoss;

  Bet(
    this.currentValue,
    this.targetWon,
    this.profitLoss, {
    required this.id,
    required this.ticker,
    required this.dailyGain,
    required this.name,
    required this.iconPath,
    required this.betAmount,
    required this.originValue,
    required this.targetValue,
    required this.targetMargin,
    required this.targetDate,
    required this.endDate,
    required this.targetOdds,
    required this.bet_zone,
  });

  Bet.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        ticker = json['ticker'],
        name = json['name'],
        iconPath = json['icon_path'],
        betAmount = json['bet_amount'].toDouble(),
        dailyGain = json['daily_gain'].toDouble(),
        originValue = json['origin_value'].toDouble(),
        currentValue = json['current_value'].toDouble(),
        targetValue = json['target_value'].toDouble(),
        targetMargin = json['target_margin'].toDouble(),
        targetDate = DateTime.parse(json['target_date']),
        endDate = DateTime.parse(json['end_date']),
        targetOdds = json['target_odds'].toDouble(),
        targetWon = json['target_won'],
        profitLoss = DateTime.parse(json['target_date']).isAfter(DateTime.now())
            ? json['bet_amount'].toDouble()
            : json['target_won'] == true
                ? (json['bet_amount'].toDouble()) *
                    (json['target_odds'].toDouble())
                : json['bet_amount'].toDouble() * (-1),
         bet_zone = json['bet_zone'];
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
  RecentBetDialog({
    super.key,
    required this.bet,
    required this.controller,
  });

  static get decodedBody => null;

  void showPopup(BuildContext context, String message, Offset position) {
    int xOffset;
    (message.length < 10) ? xOffset = -18 : xOffset = message.length - 15;

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
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black.withOpacity(1)
                  : Colors.grey[200]!,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Text(message,
                style: GoogleFonts.josefinSans(
                    fontSize: 12,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black)),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);

    Future.delayed(const Duration(milliseconds: 1200), () {
      overlayEntry?.remove();
    });
  }

  Widget _buildGridItem(
      BuildContext context, IconData icon, String value, String infoText,
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
                          '${bet.profitLoss!.toStringAsFixed(2)}฿',
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
                            '${bet.betAmount.toStringAsFixed(2)}฿',
                            strings!.betAmount ?? "Bet amount"),
                        _buildGridItem(
                            context,
                            Icons.update,
                            '${bet.originValue.toStringAsFixed(2)}€',
                            strings.originValue ?? "Origin value"),
                        _buildGridItem(
                            context,
                            Icons.crop_sharp,
                            '${bet.targetValue.toStringAsFixed(2)}€',
                            strings.targetValue ?? "Target value"),
                        _buildGridItem(
                            context,
                            Icons.date_range,
                            DateFormat('dd-MM-yyyy').format(bet.targetDate),
                            strings.targetDate ?? "Target date"),
                        _buildGridItem(
                            context,
                            Icons.data_object_sharp,
                            '${bet.targetMargin.toStringAsFixed(2)}%',
                            strings.targetMargin ?? "Target margin"),
                        _buildGridItem(
                            context,
                            Icons.attach_money,
                            'x${bet.targetOdds.toStringAsFixed(2)}',
                            strings.winBonus ?? "Win bonus"),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(
                            size: 42,
                            Icons.remove_red_eye_outlined,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
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
                                    color: Theme.of(context)
                                        .scaffoldBackgroundColor,
                                    height: MediaQuery.of(context).size.height *
                                        0.6,
                                    child: OverflowBox(
                                      alignment: Alignment.topCenter,
                                      maxHeight:
                                          MediaQuery.of(context).size.height,
                                      child: Column(
                                        children: [
                                          Expanded(
                                            child: CandlesticksView(
                                                ticker: bet.ticker.toString(),
                                                betZoneId: bet.bet_zone,
                                                name: bet.name,
                                                controller: this.controller,
                                                iconPath: bet.iconPath),
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
  final double dailyGain;
  final MainMenuPageController controller;
  const RecentBetContainer(
      {super.key,
      required this.bet,
      required this.onDelete,
      required this.dailyGain,
      required this.controller});

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

  void popBetDialog(
      BuildContext context, Bet bet, MainMenuPageController controller) {
    showGeneralDialog(
      context: context,
      pageBuilder: (BuildContext buildContext, Animation<double> animation,
          Animation<double> secondaryAnimation) {
        return RecentBetDialog(bet: bet, controller: controller);
      },
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
            )),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    int daysUntilTarget =  widget.bet.targetDate.difference(DateTime.now()).inDays;
    int daysUntilFinal =  widget.bet.endDate.difference(DateTime.now()).inDays;
    final strings = LocalizedStrings.of(context);
    String? trailingText =
        (widget.bet.profitLoss != null && widget.bet.profitLoss != 0.0)
            ? (widget.bet.profitLoss)?.toStringAsFixed(2)
            : '¿?';
    String currency = '฿';

    /* TO-DO
    String currency = (bet.currency != null) ?
                                     bet.currency as String :
                                     '-';  */
    return Column(
      children: <Widget>[
        ListTile(
            contentPadding:
                const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            onLongPress: _triggerBetButtons,
            onTap: () {
              (_showEditButtons)
                  ? _triggerBetButtons()
                  : popBetDialog(context, widget.bet, widget.controller);
            },
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(10.0),
              child: Image.memory(
                base64Decode(widget.bet.iconPath),
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              ),
            ),
            title: Text(
              maxLines: 1,
              widget.bet.name,
              style: GoogleFonts.mPlusRounded1c(
                fontSize: 20,
                fontWeight: FontWeight.w300,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black87,
              ),
            ),
            subtitle: _showEditButtons
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      Text(
                        maxLines: 1,
                        '(${widget.bet.betAmount.toStringAsFixed(2)}฿ @ ${widget.bet.originValue})',
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        maxLines: 1,
                        '${widget.bet.targetDate.year}-${widget.bet.targetDate.month}-${widget.bet.targetDate.day} @ ${widget.bet.targetValue} ± ${widget.bet.targetMargin}%',
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w300,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.cyanAccent
                              : Colors.deepPurple,
                        ),
                      ),
                    ],
                  )
                : Text(
                    (widget.dailyGain > 0.0)
                        ? '▲ ${(widget.dailyGain * 100).toStringAsFixed(2)}%'
                        : '▼ ${(widget.dailyGain.abs() * 100).toStringAsFixed(2)}%',
                    style: GoogleFonts.rajdhani(
                      fontSize: 16,
                      fontWeight:
                          Theme.of(context).brightness == Brightness.dark
                              ? FontWeight.w200
                              : FontWeight.w500,
                      color: widget.dailyGain > 0.0 ? Colors.green : Colors.red,
                    ),
                  ),
            trailing: _showEditButtons
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_red_eye_outlined,
                            color: Colors.grey),
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
                                  color:
                                      Theme.of(context).scaffoldBackgroundColor,
                                  height:
                                      MediaQuery.of(context).size.height * 0.6,
                                  child: OverflowBox(
                                    alignment: Alignment.topCenter,
                                    maxHeight:
                                        MediaQuery.of(context).size.height,
                                    child: Column(
                                      children: [
                                        Expanded(
                                          child: CandlesticksView(
                                              ticker: widget.bet.ticker,
                                              betZoneId : widget.bet.bet_zone,
                                              name: widget.bet.name,
                                              controller: widget.controller,
                                              iconPath: widget.bet.iconPath),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(maxHeight: 30, maxWidth: 30),
                        visualDensity: VisualDensity.compact,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.grey),
                        onPressed: () async {
                          final result = await BetsService()
                              .deleteRecentBet(widget.bet.id.toString());

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
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(maxHeight: 30, maxWidth: 30),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  )
                : Column(
              children: [
                Text(
                  maxLines: 1,
                  '$trailingText$currency',
                  style: GoogleFonts.montserrat(
                    fontSize: 20,
                    fontWeight: FontWeight.w300,
                    color: (widget.bet.targetDate.isAfter(DateTime.now()))
                        ? Colors.grey
                        : widget.bet.targetWon == true
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
                Container(width: 61, child:
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center, // Centra los elementos
                    children: [
                      Text(
                        (daysUntilTarget > 0 ?
                             "$daysUntilTarget ${strings!.day ?? "day/s" }" :
                              (daysUntilFinal >= 0 ?
                                      strings!.onPlay ?? "On play!" :
                                      strings!.finished ?? "Finished" )),
                        style: GoogleFonts.rajdhani(
                          fontSize: 11,
                          color: Colors.white
                        ),
                      ),
                      const SizedBox(width: 5),
                      Icon((daysUntilTarget > 0 ? Icons.watch_later : Icons.timer_off_outlined) , size: 16), // El icono


                    ],
                  ),
                )
              ],
            )
        ),
      ],
    );
  }
}
