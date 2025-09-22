import 'dart:convert';
import 'dart:ui';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:betrader/services/BetsService.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/common.dart';
import '../locale/localized_texts.dart';
import '../ui/candlesticks_view.dart';
import '../ui/layout_page.dart';

class Trend {
  final int id;
  final String name;
  final String icon;
  final double dailyGain;
  final double close;
  final double current;
  final String ticker;

  Trend(this.id, this.icon, this.dailyGain, this.name, this.close, this.current,
      this.ticker);

  Trend.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        name = json['name'],
        icon = json['icon'],
        dailyGain = (json['daily_gain'] as num).toDouble(),
        close = (json['close'] as num).toDouble(),
        current = (json['current'] as num).toDouble(),
        ticker = json['ticker'];
}

class Trends {
  final List<Trend> trends;
  final int length;

  Trends(this.trends, this.length);
}

class TrendDialog extends StatelessWidget {
  final Trend trend;
  final int index;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final MainMenuPageController controller;
  final String currency;
  const TrendDialog(
      {super.key,
      required this.trend,
      required this.index,
      required this.controller, required this.currency});

  @override
  Widget build(BuildContext context) {
    final strings = LocalizedStrings.of(context);

    return Dialog(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(40),
      ),
      backgroundColor: Colors.transparent.withValues(alpha: 0.1),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.transparent.withValues(alpha: 0.01),
              borderRadius: BorderRadius.circular(40),
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  children: [
                    Positioned(
                      top: -30,
                      right: (index == 0 || index >= 9) ? -40 : -25,
                      child: Text(
                        (index + 1).toString(),
                        style: TextStyle(
                          fontSize: 400,
                          color: Colors.white.withValues(alpha: 0.05),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              if (trend.icon != "null") ...[
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.memory(
                                    base64Decode(trend.icon),
                                    height: 120,
                                    width: 120,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) => Text(
                                      trend.name,
                                      maxLines: 1,
                                      style: GoogleFonts.josefinSans(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w200,
                                        color: Colors.white,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ] else ...[
                                AutoSizeText(
                                  Common().createTrendViewName(trend),
                                  maxLines: 1,
                                  style: GoogleFonts.josefinSans(
                                    fontSize: 60,
                                    fontWeight: FontWeight.w100,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                              const Spacer(),
                              Column(
                                children: [
                                  IconButton(
                                    iconSize: 44,
                                    splashRadius: 28,
                                    onPressed: () async {
                                      bool ok =
                                          await BetsService().postNewFavorite(
                                        await _storage.read(
                                                key: "sessionToken") ??
                                            "none",
                                        trend.ticker,
                                      );
                                      if (ok) {
                                        Common().showFloatingSnack(
                                          context,
                                          LocalizedStrings.of(context)!
                                                  .get('updatedFavs') ??
                                              "Updated favs!",
                                          showIcon: false,
                                        );
                                        homeScreenKey.currentState
                                            ?.refreshFavorites();
                                        marketsPageKey.currentState
                                            ?.toggleFavorite(trend.ticker,
                                                onlyLocal: true);
                                        Navigator.of(context).pop(true);
                                      }
                                    },
                                    icon: const Icon(FontAwesomeIcons.star,
                                        size: 32, color: Colors.white),
                                  ),
                                  const SizedBox(height: 80),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          AutoSizeText(
                            trend.name,
                            maxLines: 2,
                            style: GoogleFonts.robotoCondensed(
                              fontSize: 42,
                              fontWeight: FontWeight.w100,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              (trend.dailyGain >= 0)
                                  ? const Icon(FontAwesomeIcons.arrowTrendUp,
                                      color: Colors.green, size: 22)
                                  : const Icon(FontAwesomeIcons.arrowTrendDown,
                                      color: Colors.red, size: 22),
                              const SizedBox(width: 6),
                              Text(
                                ' ${trend.dailyGain.abs().toStringAsFixed(2)}%',
                                style: GoogleFonts.montserrat(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w500,
                                  color: trend.dailyGain >= 0
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${strings?.get('close') ?? 'Close'}: ${trend.close.toStringAsFixed(2)}' + currency,
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                '${strings?.get('current') ?? 'Current'}: ${trend.current.toStringAsFixed(2)}' + currency,
                                style: GoogleFonts.montserrat(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: trend.dailyGain >= 0
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                              const Spacer(),
                              Column(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      FontAwesomeIcons.chartLine,
                                      size: 38,
                                      color: Colors.white70,
                                    ),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          backgroundColor: Colors.transparent,
                                          builder: (BuildContext context) {
                                            return ClipRRect(
                                              borderRadius:
                                              const BorderRadius.vertical(
                                                top: Radius.circular(25),
                                              ),
                                              child: Container(
                                                color: Theme.of(context)
                                                    .scaffoldBackgroundColor,
                                                height: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                    0.55,
                                                child: OverflowBox(
                                                  alignment: Alignment.topCenter,
                                                  maxHeight:
                                                  MediaQuery.of(context)
                                                      .size
                                                      .height,
                                                  child: Column(
                                                    children: [
                                                      Expanded(
                                                        child: CandlesticksView(
                                                          ticker: trend.ticker,
                                                          name: trend.name,
                                                          controller: controller,
                                                          iconPath: trend.icon,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      }
                                  ),
                                  Text(
                                    strings!.get('viewChart') ?? "View chart",
                                    style: GoogleFonts.montserrat(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w200),
                                  )
                                ],
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TrendContainer extends StatefulWidget {
  final Trend trend;
  final int index;
  final VoidCallback onFavoriteUpdated;
  final MainMenuPageController controller;

  const TrendContainer(
      {super.key,
      required this.trend,
      required this.index,
      required this.onFavoriteUpdated,
      required this.controller});

  @override
  TrendContainerState createState() => TrendContainerState();
}

class TrendContainerState extends State<TrendContainer> {
  String _currencyChar = '€';

  void popTrendDialog(BuildContext context, Trend trend, int index,
      MainMenuPageController controller) {
    loadCurrency();
    showGeneralDialog(
      context: context,
      pageBuilder: (BuildContext buildContext, Animation<double> animation,
          Animation<double> secondaryAnimation) {
        return TrendDialog(trend: trend, index: index, controller: controller, currency: _currencyChar);
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

  Future<void> loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('dollarCurrency') ?? false) {
      _currencyChar = '\$';
    }
  }

  Widget _buildTopBadge(IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        shape: BoxShape.circle,
      ),
      padding: const EdgeInsets.all(2),
      child: Icon(
        icon,
        color: Colors.white,
        size: 25,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // El propio TrendContainer clicable
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => {
                Common().vibrate(),
                popTrendDialog(
                    context, widget.trend, widget.index, widget.controller)
              },
              onLongPress: () => {
                Common().vibrate(),
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (BuildContext context) {
                    return ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(25.0)),
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.55,
                        child: OverflowBox(

                          alignment: Alignment.topCenter,
                          maxHeight: MediaQuery.of(context).size.height,
                          child: Column(
                            children: [
                              Expanded(
                                child: CandlesticksView(
                                  ticker: widget.trend.ticker,
                                  name: widget.trend.name,
                                  controller: widget.controller,
                                  iconPath: widget.trend.icon,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                )
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
                      color: Colors.black.withValues(alpha: 0.3),
                      spreadRadius: 1,
                      blurRadius: 1,
                      offset: const Offset(0, 1),
                    ),
                  ],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Stack(
                  children: [
                    // número grande de fondo
                    Positioned(
                      top: 0,
                      right:
                          (widget.index == 0 || widget.index >= 9) ? -20 : -5,
                      child: Text(
                        '${widget.index + 1}',
                        style: TextStyle(
                          letterSpacing: 0,
                          fontSize: 120,
                          color: Colors.white.withValues(alpha: 0.1),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),

                    // contenido principal
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.trend.icon != "null" &&
                              !widget.trend.icon.startsWith("http")) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.memory(
                                base64Decode(widget.trend.icon),
                                height: 42,
                                width: 42,
                                errorBuilder: (context, error, stackTrace) =>
                                    Text(
                                  widget.trend.name,
                                  maxLines: 1,
                                  style: GoogleFonts.roboto(
                                      fontSize: 36,
                                      fontWeight: FontWeight.w100),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                          ] else if (widget.trend.icon.startsWith("http")) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.network(
                                widget.trend.icon,
                                width: 42,
                                height: 42,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    Text(
                                  widget.trend.name,
                                  maxLines: 1,
                                  style: GoogleFonts.roboto(
                                      fontSize: 36,
                                      fontWeight: FontWeight.w100),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                          ] else ...[
                            AutoSizeText(
                              Common().createTrendViewName(widget.trend),
                              maxLines: 1,
                              style: GoogleFonts.josefinSans(
                                fontSize: 40,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ],
                          const Spacer(),
                          AutoSizeText(
                            widget.trend.name,
                            maxLines: 1,
                            style: GoogleFonts.robotoCondensed(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                          Row(
                            children: [
                              (widget.trend.dailyGain >= 0.0)
                                  ? Icon(FontAwesomeIcons.arrowTrendUp,
                                      color: Colors.green, size: 12)
                                  : Icon(FontAwesomeIcons.arrowTrendDown,
                                      color: Colors.red, size: 12),
                              Text(
                                (widget.trend.dailyGain >= 0.0)
                                    ? ' ${(widget.trend.dailyGain).toStringAsFixed(2)}%'
                                    : ' ${(widget.trend.dailyGain.abs()).toStringAsFixed(2)}%',
                                style: GoogleFonts.montserrat(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w300,
                                  color: widget.trend.dailyGain >= 0.0
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // badge arriba a la izquierda, fuera del contenedor
          if (widget.index == 0)
            Positioned(
              top: -8,
              left: -8,
              child: _buildTopBadge(Icons.emoji_events, Colors.amber),
            )
          else if (widget.index == 1)
            Positioned(
              top: -8,
              left: -8,
              child: _buildTopBadge(Icons.emoji_events, Colors.grey),
            )
          else if (widget.index == 2)
            Positioned(
              top: -8,
              left: -8,
              child: _buildTopBadge(Icons.emoji_events, Colors.brown),
            ),
        ],
      ),
    );
  }
}
