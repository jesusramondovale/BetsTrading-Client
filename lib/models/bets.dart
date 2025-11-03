import 'dart:convert';
import 'dart:ui';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:betrader/services/BetsService.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../candlesticks/src/models/candle.dart';
import '../helpers/common.dart';
import '../locale/localized_texts.dart';
import '../services/BetZoneRefresher.dart';
import '../ui/candlesticks_view.dart';
import '../ui/exact_price_view.dart';
import '../ui/layout_page.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class Bet {
  final int id;
  final String name;
  final String ticker;
  final String iconPath;
  final double necessaryGain;
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
  final bool? finished;
  final double? profitLoss;

  Bet(
    this.currentValue,
    this.targetWon,
    this.profitLoss, {
    required this.id,
    required this.ticker,
    required this.necessaryGain,
    required this.name,
    required this.iconPath,
    required this.betAmount,
    required this.originValue,
    required this.targetValue,
    required this.targetMargin,
    required this.targetDate,
    required this.endDate,
    required this.finished,
    required this.targetOdds,
    required this.bet_zone,
  });

  Bet.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        ticker = json['ticker'],
        name = json['name'],
        iconPath = json['icon_path'],
        betAmount = json['bet_amount'].toDouble(),
        necessaryGain = json['necessary_gain'].toDouble(),
        originValue = json['origin_value'].toDouble(),
        currentValue = json['current_value'].toDouble(),
        targetValue = json['target_value'].toDouble(),
        targetMargin = json['target_margin'].toDouble(),
        targetDate = DateTime.parse(json['target_date']),
        endDate = DateTime.parse(json['final_date']),
        targetOdds = json['target_odds'].toDouble(),
        targetWon = json['target_won'],
        finished = json['finished'],
        profitLoss =
            DateTime.parse(json['target_date']).isAfter(DateTime.now().toUtc())
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

class PriceBet {
  final int id;
  final String name;
  final String ticker;
  final double priceBet;
  final bool? paid;
  final int prize;
  final double margin;
  final String userId;
  final DateTime betDate;
  final DateTime endDate;
  final String iconPath;

  PriceBet({
    required this.id,
    required this.name,
    required this.ticker,
    required this.priceBet,
    required this.paid,
    required this.prize,
    required this.margin,
    required this.userId,
    required this.betDate,
    required this.endDate,
    required this.iconPath,
  });

  PriceBet.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        name = json['name'],
        ticker = json['ticker'],
        priceBet = json['price_bet'].toDouble(),
        paid = json['paid'],
        prize = json['prize'],
        margin = json['margin'].toDouble(),
        userId = json['user_id'],
        betDate = DateTime.parse(json['bet_date']),
        endDate = DateTime.parse(json['end_date']),
        iconPath = json['icon_path'];
}

class BetsAndPriceBets {
  final Bets bets;
  final List<PriceBet> priceBets;
  final double totalBetAmount;
  final double totalProfit;

  BetsAndPriceBets({
    required this.bets,
    required this.priceBets,
    required this.totalBetAmount,
    required this.totalProfit,
  });
}

class RecentBetDialog extends StatelessWidget {
  final Bet bet;
  final MainMenuPageController controller;
  final currency;
  RecentBetDialog({
    super.key,
    required this.bet,
    required this.controller,
    required this.currency,
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
              color: Colors.black.withValues(alpha: 1),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Text(message,
                style:
                    GoogleFonts.josefinSans(fontSize: 12, color: Colors.white)),
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
        Common().vibrate();
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
            icon != Icons.casino
                ? Text(
                    value,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        value,
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Image.asset(
                        'assets/coin.png',
                        width: 16,
                        height: 16,
                      ),
                    ],
                  )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = LocalizedStrings.of(context);

    return Dialog(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      backgroundColor: Colors.transparent.withValues(alpha: 0.1),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
          child: SingleChildScrollView(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.transparent.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white70.withValues(alpha: 0.12),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .6),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: <Widget>[
                        if (bet.iconPath != "null" &&
                            !bet.iconPath.contains("http")) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.memory(
                              base64Decode(bet.iconPath),
                              height: 100,
                              width: 100,
                              errorBuilder: (context, error, stackTrace) =>
                                  Text(
                                bet.name,
                                maxLines: 1,
                                style: GoogleFonts.roboto(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w100,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ] else if (bet.iconPath != "null") ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16.0),
                            child: Image.network(
                              bet.iconPath,
                              height: 100,
                              width: 100,
                              errorBuilder: (context, error, stackTrace) {
                                return AutoSizeText(
                                  bet.name,
                                  maxLines: 1,
                                  style: GoogleFonts.josefinSans(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                );
                              },
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
                        fontWeight: FontWeight.w200,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              bet.profitLoss!.toStringAsFixed(2),
                              style: GoogleFonts.montserrat(
                                fontSize: 25,
                                fontWeight: FontWeight.w400,
                                color: bet.profitLoss! > 0.0
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Image.asset(
                              'assets/coin.png',
                              width: 24,
                              height: 24,
                              fit: BoxFit.contain,
                            ),
                          ],
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
                          '${bet.betAmount.toStringAsFixed(2)}',
                          strings?.get('betAmount') ?? "Bet amount",
                        ),
                        _buildGridItem(
                          context,
                          Icons.update,
                          '${bet.originValue.toStringAsFixed(2)}' + currency,
                          strings?.get('originValue') ?? "Origin value",
                        ),
                        _buildGridItem(
                          context,
                          Icons.crop_sharp,
                          '${bet.targetValue.toStringAsFixed(2)}' + currency,
                          strings?.get('targetValue') ?? "Target value",
                        ),
                        _buildGridItem(
                          context,
                          Icons.date_range,
                          DateFormat('dd-MM-yyyy').format(bet.targetDate),
                          strings?.get('targetDate') ?? "Target date",
                        ),
                        _buildGridItem(
                          context,
                          FontAwesomeIcons.arrowsLeftRightToLine,
                          '${bet.targetMargin.toStringAsFixed(2)}%',
                          strings?.get('targetMargin') ?? "Target margin",
                        ),
                        _buildGridItem(
                          context,
                          Icons.attach_money,
                          'x${bet.targetOdds.toStringAsFixed(2)}',
                          strings?.get('winBonus') ?? "Win bonus",
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
                            Icons.remove_red_eye_outlined,
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
                                    color: Theme.of(context)
                                        .scaffoldBackgroundColor,
                                    height: MediaQuery.of(context).size.height *
                                        0.56,
                                    child: OverflowBox(
                                      alignment: Alignment.topCenter,
                                      maxHeight:
                                          MediaQuery.of(context).size.height,
                                      child: Column(
                                        children: [
                                          Expanded(
                                            child: CandlesticksView(
                                              ticker: bet.ticker,
                                              betId: bet.id,
                                              name: bet.name,
                                              controller: controller,
                                              iconPath: bet.iconPath,
                                            ),
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
            ),
          ),
        ),
      ),
    );
  }
}

class RecentPriceBetDialog extends StatelessWidget {
  final PriceBet priceBet;
  final MainMenuPageController controller;
  final String currency;
  RecentPriceBetDialog({
    super.key,
    required this.priceBet,
    required this.controller,
    required this.currency,
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
              color: Colors.black.withValues(alpha: 1),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Text(
              message,
              style: GoogleFonts.josefinSans(fontSize: 12, color: Colors.white),
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

  Widget _buildGridItem(
      BuildContext context, IconData icon, String value, String infoText,
      {Color color = Colors.white}) {
    GlobalKey key = GlobalKey();
    return GestureDetector(
      key: key,
      onTap: () {
        Common().vibrate();
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
            Icon(icon, size: 34, color: Colors.white70),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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

    final amountText = priceBet.priceBet.toStringAsFixed(2);
    final marginText = '${priceBet.margin.toStringAsFixed(2)}%';
    final betDateStr = DateFormat('dd-MM-yyyy').format(priceBet.betDate);
    final endDateStr = DateFormat('dd-MM-yyyy').format(priceBet.endDate);

    return Dialog(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      backgroundColor: Colors.transparent.withValues(alpha: 0.1),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
          child: SingleChildScrollView(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.transparent.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white70.withValues(alpha: 0.12),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .6),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: <Widget>[
                        if (priceBet.iconPath != "null" &&
                            !priceBet.iconPath.contains("http")) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.memory(
                              base64Decode(priceBet.iconPath),
                              height: 100,
                              width: 100,
                              errorBuilder: (context, error, stackTrace) =>
                                  Text(
                                priceBet.name,
                                maxLines: 1,
                                style: GoogleFonts.roboto(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w100,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ] else if (priceBet.iconPath != "null") ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.network(
                              priceBet.iconPath,
                              height: 100,
                              width: 100,
                              errorBuilder: (context, error, stackTrace) {
                                return AutoSizeText(
                                  priceBet.name,
                                  maxLines: 1,
                                  style: GoogleFonts.josefinSans(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                );
                              },
                            ),
                          ),
                        ] else ...[
                          AutoSizeText(
                            priceBet.name,
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
                      priceBet.name,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.robotoCondensed(
                        fontSize: 30,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            amountText,
                            style: GoogleFonts.montserrat(
                              fontSize: 22,
                              fontWeight: FontWeight.w400,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Image.asset(
                            currency == 'eur'
                                ? 'assets/euro.png'
                                : 'assets/dollar.png',
                            width: 24,
                            height: 24,
                            fit: BoxFit.contain,
                          ),
                        ],
                      ),
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
                          amountText,
                          strings?.get('betAmount') ?? 'Bet amount',
                        ),
                        _buildGridItem(
                          context,
                          FontAwesomeIcons.arrowsLeftRightToLine,
                          marginText,
                          strings?.get('targetMargin') ?? 'Target margin',
                        ),
                        _buildGridItem(
                          context,
                          Icons.label_outline,
                          priceBet.ticker,
                          'Ticker',
                        ),
                        _buildGridItem(
                          context,
                          Icons.event,
                          betDateStr,
                          strings?.get('betDate') ?? 'Bet date',
                        ),
                        _buildGridItem(
                          context,
                          Icons.event_available,
                          endDateStr,
                          strings?.get('targetDate') ?? 'Target date',
                        ),
                        _buildGridItem(
                          context,
                          Icons.numbers,
                          priceBet.id.toString(),
                          'ID',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Column(
                          children: [
                            IconButton(
                              icon: const Icon(
                                FontAwesomeIcons.crosshairs,
                                size: 42,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    blurRadius: 1.5,
                                    color: Colors.black45,
                                    offset: Offset(8.0, 4.0),
                                  )
                                ],
                              ),
                              onPressed: () async {
                                List<Candle> candles = await BetsService()
                                    .fetchCandles(priceBet.ticker,
                                        TimeframeManager.current.value);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ExactPricePage(
                                        name: priceBet.name,
                                        ticker: priceBet.ticker,
                                        currentValue: candles.first.close,
                                        iconPath: priceBet.iconPath,
                                        isForex: Common()
                                            .isTickerForex(priceBet.ticker)),
                                  ),
                                );
                              },
                            ),
                            Text(
                              strings?.get('exactPrice') ?? "Exact price",
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                fontWeight: FontWeight.w200,
                                color: Colors.white70,
                              ),
                            )
                          ],
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RecentBetContainer extends StatefulWidget {
  final Bet bet;
  final Function onDelete;
  final double necessaryGain;
  final MainMenuPageController controller;
  const RecentBetContainer(
      {super.key,
      required this.bet,
      required this.onDelete,
      required this.necessaryGain,
      required this.controller});

  @override
  RecentBetContainerState createState() => RecentBetContainerState();
}

class RecentBetContainerState extends State<RecentBetContainer> {
  bool _showEditButtons = false;
  String _currencyChar = '€';

  void _triggerBetButtons() {
    setState(() {
      _showEditButtons = !_showEditButtons;
    });
  }

  Future<void> loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('dollarCurrency') ?? false) {
      _currencyChar = '\$';
    }
  }

  void popBetDialog(
      BuildContext context, Bet bet, MainMenuPageController controller) {
    loadCurrency();
    showGeneralDialog(
      context: context,
      pageBuilder: (BuildContext buildContext, Animation<double> animation,
          Animation<double> secondaryAnimation) {
        return RecentBetDialog(
            bet: bet, controller: controller, currency: _currencyChar);
      },
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withValues(alpha: 0.5),
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
    final strings = LocalizedStrings.of(context);
    int hoursUntilTarget = widget.bet.targetDate.difference(DateTime.now().toUtc()).inHours;
    int minutesUntilTarget = widget.bet.targetDate.difference(DateTime.now().toUtc()).inMinutes;
    int hoursUntilFinal = widget.bet.endDate.difference(DateTime.now().toUtc()).inHours;
    int minutesUntilFinal = widget.bet.endDate.difference(DateTime.now().toUtc()).inMinutes;
    bool isActive = widget.bet.targetDate.isBefore(DateTime.now().toUtc());
    bool isFinished = widget.bet.endDate.isBefore(DateTime.now().toUtc());
    bool isAlreadyLost = (isActive && widget.bet.finished == true) || (isActive && widget.bet.necessaryGain != 0.0);
    double? betAmount = widget.bet.betAmount;
    String betAmountText = NumberFormat('0.##', 'en').format(betAmount);
    String? betMultiplierText = " x${widget.bet.targetOdds}";
    final num prizeNum = widget.bet.betAmount * widget.bet.targetOdds;
    String prizeText = NumberFormat('0.##', 'en').format(prizeNum);

    return Column(
      children: <Widget>[
        Slidable(
          key: Key(widget.bet.id.toString()),
          endActionPane: (isAlreadyLost || DateTime.now().toUtc().isAfter(widget.bet.endDate))
              ? ActionPane(
                  motion: const ScrollMotion(),
                  extentRatio: 0.3,
                  dismissible: DismissiblePane(
                    dismissThreshold: 0.3,
                    closeOnCancel: false,
                    onDismissed: () async {
                      Common().vibrate();
                      widget.onDelete();
                      try {
                        final ok = await BetsService().deleteRecentBet(widget.bet.id.toString());
                        if (!ok) {
                          Common().showFloatingSnack(context, "Error!", backgroundColor: Colors.red);
                        }
                      } catch (_) {
                        Common().showFloatingSnack(context, "Error!", backgroundColor: Colors.red);
                      }
                    },
                  ),
                  children: [
                    CustomSlidableAction(
                      onPressed: (_) {},
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: const FaIcon(FontAwesomeIcons.trash, size: 30),
                    ),
                  ],
                )
              : null,
          child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
              onLongPress: _triggerBetButtons,
              onTap: () {
                (_showEditButtons) ? _triggerBetButtons() : Common().vibrate();
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
                        height: MediaQuery.of(context).size.height * 0.56,
                        child: OverflowBox(
                          alignment: Alignment.topCenter,
                          maxHeight: MediaQuery.of(context).size.height,
                          child: Column(
                            children: [
                              Expanded(
                                child: CandlesticksView(
                                  ticker: widget.bet.ticker,
                                  betId: widget.bet.id,
                                  name: widget.bet.name,
                                  controller: widget.controller,
                                  iconPath: widget.bet.iconPath,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: (widget.bet.iconPath.contains("http")
                    ? Image.network(
                        widget.bet.iconPath,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return AutoSizeText(
                              Common()
                                  .createTrendViewNameFromName(widget.bet.name),
                              maxLines: 1,
                              style: GoogleFonts.josefinSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ));
                        },
                      )
                    : (widget.bet.iconPath != "null"
                        ? Image.memory(base64Decode(widget.bet.iconPath),
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Text(
                                  widget.bet.name,
                                  maxLines: 1,
                                  style: GoogleFonts.roboto(
                                      fontSize: 36,
                                      fontWeight: FontWeight.w100),
                                  textAlign: TextAlign.center,
                                ))
                        : AutoSizeText(
                            Common()
                                .createTrendViewNameFromName(widget.bet.name),
                            maxLines: 1,
                            style: GoogleFonts.josefinSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ))),
              ),
              title: Text(
                maxLines: 1,
                widget.bet.name,
                style: GoogleFonts.mPlusRounded1c(
                  fontSize: 20,
                  fontWeight: FontWeight.w300,
                  color: Colors.white,
                ),
              ),
              subtitle: _showEditButtons
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        Text(
                          maxLines: 1,
                          '(${widget.bet.betAmount.toStringAsFixed(2)}🪙 @ ${widget.bet.originValue})',
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
                            color: Colors.cyanAccent,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        if (isAlreadyLost) ...[
                          Text(
                            strings?.get('betLost') ?? "Bet failed",
                            style: GoogleFonts.rajdhani(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: Colors.red,
                            ),
                          ),
                        ] else if (isFinished &&
                            widget.bet.targetWon == true) ...[
                          Text(
                            "${strings?.get('betWon')?.toUpperCase() ?? "BET WON"}!",
                            style: GoogleFonts.rajdhani(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: Colors.green,
                            ),
                          ),
                        ]
                        // NOT LOST YET
                        else ...[
                          if (widget.necessaryGain == 0.0)
                            Row(
                              children: [
                                Icon(FontAwesomeIcons.crosshairs,
                                    color: Colors.green, size: 14),
                                SizedBox(width: 2),
                                Icon(FontAwesomeIcons.check,
                                    color: Colors.green, size: 12),
                                SizedBox(width: 2)
                              ],
                            )
                          else if (widget.necessaryGain >= 2.0)
                            Row(
                              children: [
                                Icon(FontAwesomeIcons.crosshairs,
                                    color: Colors.grey, size: 14),
                                SizedBox(width: 2),
                                Icon(FontAwesomeIcons.arrowTrendUp,
                                    color: Colors.red, size: 10)
                              ],
                            )
                          else if (widget.necessaryGain <= -2.0)
                            Row(
                              children: [
                                Icon(FontAwesomeIcons.crosshairs,
                                    color: Colors.grey, size: 14),
                                SizedBox(width: 2),
                                Icon(FontAwesomeIcons.arrowTrendDown,
                                    color: Colors.red, size: 10)
                              ],
                            )
                          else if (widget.necessaryGain > 0.0)
                            Row(
                              children: [
                                Icon(FontAwesomeIcons.crosshairs,
                                    color: Colors.grey, size: 14),
                                SizedBox(width: 2),
                                Icon(FontAwesomeIcons.arrowTrendUp,
                                    color: Colors.yellow, size: 10)
                              ],
                            )
                          else
                            Row(
                              children: [
                                Icon(FontAwesomeIcons.crosshairs,
                                    color: Colors.grey, size: 14),
                                SizedBox(width: 2),
                                Icon(FontAwesomeIcons.arrowTrendDown,
                                    color: Colors.yellow, size: 10)
                              ],
                            ),
                          Text(
                            (widget.necessaryGain != 0.0)
                                ? ' ${(widget.necessaryGain).abs().toStringAsFixed(2)}% '
                                : '',
                            style: GoogleFonts.rajdhani(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: widget.necessaryGain == 0.0
                                  ? Colors.green
                                  : (widget.necessaryGain.abs() >= 2
                                      ? Colors.red
                                      : Colors.yellow),
                            ),
                          ),
                          if (!isActive) ...[
                            Icon(FontAwesomeIcons.hourglassHalf, size: 12),
                          ],
                          Text(
                            (!isActive
                                ? (hoursUntilTarget >= 1
                                    ? '($hoursUntilTarget h)'
                                    : '($minutesUntilTarget m)')
                                : (!isFinished
                                    ? " ${strings?.get('onPlay') ?? "On play!"} "
                                    : "")),
                            style: GoogleFonts.rajdhani(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: widget.necessaryGain == 0.0
                                  ? Colors.green
                                  : (widget.necessaryGain.abs() >= 2
                                      ? Colors.red
                                      : Colors.yellow),
                            ),
                          ),
                          if (isActive) ...[
                            Icon(FontAwesomeIcons.eye, size: 12)
                          ]
                        ]
                      ],
                    ),
              trailing: _showEditButtons
                  ? null
                  : Column(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isFinished && widget.bet.targetWon == true) ...[
                              Text(
                                prizeText,
                                maxLines: 1,
                                style: GoogleFonts.montserrat(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.green),
                              ),
                              const SizedBox(width: 6),
                              Image.asset(
                                'assets/coin.png',
                                width: 20,
                                height: 20,
                                fit: BoxFit.contain,
                              ),
                            ] else ...[
                              Text(
                                "${(isAlreadyLost ? "-" : "")}${betAmountText}${((isAlreadyLost) ? "" : betMultiplierText)}",
                                maxLines: 1,
                                style: GoogleFonts.montserrat(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w300,
                                  color: !isFinished && !isAlreadyLost
                                      ? Colors.grey
                                      : widget.bet.targetWon == true
                                          ? Colors.green
                                          : Colors.red,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Image.asset(
                                'assets/coin.png',
                                width: 20,
                                height: 20,
                                fit: BoxFit.contain,
                              ),
                            ]
                          ],
                        ),
                        Container(
                          width: MediaQuery.of(context).size.height * 0.1,
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (!(isFinished &&
                                    widget.bet.targetWon == true)) ...[
                                  Text(
                                    (!isFinished && !isAlreadyLost
                                        ? (hoursUntilFinal > 0
                                            ? "$hoursUntilFinal ${strings?.get('hours') ?? "hour/s"}"
                                            : "${minutesUntilFinal}min.")
                                        : strings?.get('finished') ??
                                            "Finished"),
                                    style: GoogleFonts.rajdhani(
                                      fontSize: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Icon(
                                    (!isFinished && !isAlreadyLost
                                        ? FontAwesomeIcons.hourglassHalf
                                        : Icons.timer_off_outlined),
                                    size: 16,
                                  ),
                                ],
                              ]),
                        ),
                      ],
                    )),
        ),
      ],
    );
  }
}

class RecentPriceBetContainer extends StatefulWidget {
  final PriceBet priceBet;
  final Function onDelete;
  final bool isForex;
  final MainMenuPageController controller;
  const RecentPriceBetContainer(
      {super.key,
      required this.priceBet,
      required this.onDelete,
      required this.controller,
      required this.isForex});

  @override
  RecentPriceBetContainerState createState() => RecentPriceBetContainerState();
}

class RecentPriceBetContainerState extends State<RecentPriceBetContainer> {
  bool _showEditButtons = false;
  String _currency = 'eur';

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final useDollar = prefs.getBool('dollarCurrency') ?? false;
    if (!mounted) return;
    setState(() {
      _currency = useDollar ? 'usd' : 'eur';
    });
  }

  void _triggerBetButtons() {
    setState(() {
      _showEditButtons = !_showEditButtons;
    });
  }

  Widget _buildTopBadge(IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.5),
        shape: BoxShape.circle,
      ),
      padding: const EdgeInsets.all(4),
      child: Icon(icon, color: Colors.white70, size: 20),
    );
  }

  void popPriceBetDialog(BuildContext context, PriceBet priceBet,
      MainMenuPageController controller) {
    showGeneralDialog(
      context: context,
      pageBuilder: (BuildContext buildContext, Animation<double> animation,
          Animation<double> secondaryAnimation) {
        return RecentPriceBetDialog(
            controller: controller, priceBet: priceBet, currency: _currency);
      },
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withValues(alpha: 0.5),
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
  void initState() {
    super.initState();
    _loadPreferences();
  }

  @override
  Widget build(BuildContext context) {
    final strings = LocalizedStrings.of(context);
    final now = DateTime.now().toUtc();
    final hoursUntilFinal = widget.priceBet.endDate.difference(now).inHours;
    final minutesUntilFinal = widget.priceBet.endDate.difference(now).inMinutes;
    final prizeText = NumberFormat('#,##0', 'es').format(widget.priceBet.prize);
    final marginText = '${widget.priceBet.margin}%';
    final betDateStr = DateFormat('dd-MM-yyyy').format(widget.priceBet.betDate);
    final endDateStr = DateFormat('dd-MM-yyyy').format(widget.priceBet.endDate);
    final paidStr = widget.priceBet.paid == true
        ? (strings?.get('paid') ?? 'Paid')
        : (strings?.get('unpaid') ?? 'Unpaid');

    final statusColor = now.isBefore(widget.priceBet.endDate)
        ? Colors.amber
        : (widget.priceBet.paid == true ? Colors.green : Colors.red);

    return Column(
      children: <Widget>[
        Slidable(
          key: Key(widget.priceBet.id.toString()),
          endActionPane: DateTime.now().toUtc().isAfter(widget.priceBet.endDate)
              ? ActionPane(
                  motion: const ScrollMotion(),
                  extentRatio: 0.3,
                  dismissible: DismissiblePane(
                    dismissThreshold: 0.3,
                    closeOnCancel: true,
                    onDismissed: () async {
                      Common().vibrate();
                      widget.onDelete();
                      try {
                        final ok = await BetsService().deleteRecentPriceBet(widget.priceBet.id.toString());
                        if (!ok) {
                          Common().showFloatingSnack(context, "Error!", backgroundColor: Colors.red);
                        }
                      } catch (_) {
                        Common().showFloatingSnack(context, "Error!", backgroundColor: Colors.red);
                      }
                    },
                  ),
                  children: [
                    SlidableAction(
                      onPressed: (_) {},
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      icon: Icons.delete,
                    ),
                  ],
                )
              : null,
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
            onLongPress: _triggerBetButtons,
            onTap: () {
              (_showEditButtons) ? _triggerBetButtons() : Common().vibrate();
              popPriceBetDialog(context, widget.priceBet, widget.controller);
            },
            leading: SizedBox(
              width: 50,
              height: 50,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10.0),
                    child: (widget.priceBet.iconPath.startsWith("http")
                        ? Image.network(
                            widget.priceBet.iconPath,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return AutoSizeText(
                                Common().createTrendViewNameFromName(
                                    widget.priceBet.name),
                                maxLines: 1,
                                style: GoogleFonts.josefinSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              );
                            },
                          )
                        : (widget.priceBet.iconPath != "null"
                            ? Image.memory(
                                base64Decode(widget.priceBet.iconPath),
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Text(
                                  widget.priceBet.name,
                                  maxLines: 1,
                                  style: GoogleFonts.roboto(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w100,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            : AutoSizeText(
                                Common().createTrendViewNameFromName(
                                    widget.priceBet.name),
                                maxLines: 1,
                                style: GoogleFonts.josefinSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ))),
                  ),
                  Positioned(
                    top: -8,
                    left: -10,
                    child: _buildTopBadge(
                        FontAwesomeIcons.crosshairs, Colors.black),
                  ),
                ],
              ),
            ),
            title: Text(
              widget.priceBet.name,
              maxLines: 1,
              style: GoogleFonts.mPlusRounded1c(
                fontSize: 20,
                fontWeight: FontWeight.w300,
                color: Colors.white,
              ),
            ),
            subtitle: _showEditButtons
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      Text(
                        '${widget.priceBet.ticker} • ${prizeText}🪙 • ± $marginText',
                        maxLines: 1,
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${strings?.get('betDate') ?? "Bet date"}: $betDateStr  •  ${strings?.get('targetDate') ?? "Target date"}: $endDateStr  •  $paidStr',
                        maxLines: 1,
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w300,
                          color: Colors.cyanAccent,
                        ),
                      ),
                    ],
                  )
                : Text(
                    '${widget.priceBet.priceBet}${(_currency == 'eur' ? "€" : "\$")} ± $marginText',
                    maxLines: 1,
                    style: GoogleFonts.rajdhani(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.white70,
                    ),
                  ),
            trailing: _showEditButtons
                ? null
                : Column(
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            prizeText,
                            maxLines: 1,
                            style: GoogleFonts.montserrat(
                              fontSize: 22,
                              fontWeight: FontWeight.w300,
                              color: statusColor,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Image.asset(
                            'assets/coin.png',
                            width: 20,
                            height: 20,
                          ),
                        ],
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.1,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              (hoursUntilFinal > 0
                                  ? "$hoursUntilFinal ${strings?.get('hours') ?? "hour/s"}"
                                  : (hoursUntilFinal >= 0
                                      ? "$minutesUntilFinal min."
                                      : strings?.get('finished') ??
                                          "Finished")),
                              style: GoogleFonts.rajdhani(
                                fontSize: 12,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Icon(
                              (hoursUntilFinal > 0
                                  ? FontAwesomeIcons.hourglassHalf
                                  : Icons.timer_off_outlined),
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

//-------- SKELETON

class SkeletonRecentBetContainer extends StatelessWidget {
  const SkeletonRecentBetContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 10.0),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
        title: Container(
          width: 120,
          height: 18,
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 60,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
        ),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              width: 50,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
