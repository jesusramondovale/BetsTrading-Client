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

class TrendDialog extends StatefulWidget {
  final Trend trend;
  final int index;
  final MainMenuPageController controller;
  final String currency;

  const TrendDialog({
    super.key,
    required this.trend,
    required this.index,
    required this.controller,
    required this.currency,
  });

  @override
  State<TrendDialog> createState() => _TrendDialogState();
}

class _TrendDialogState extends State<TrendDialog> with SingleTickerProviderStateMixin {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  bool isFavorite = false;
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    isFavorite = marketsPageKey.currentState?.isFavorite(widget.trend.ticker) ?? false;

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
      lowerBound: 0.0,
      upperBound: 1.0,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = LocalizedStrings.of(context);

    return Dialog(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
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
                      right: (widget.index == 0 || widget.index >= 9) ? -40 : -25,
                      child: Text(
                        (widget.index + 1).toString(),
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
                              if (widget.trend.icon != "null") ...[
                                if (widget.trend.icon.startsWith('http')) ...[
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.network(
                                      widget.trend.icon,
                                      height: 120,
                                      width: 120,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                ] else ...[
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.memory(
                                      base64Decode(widget.trend.icon),
                                      height: 120,
                                      width: 120,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                ]
                              ] else ...[
                                AutoSizeText(
                                  Common().createTrendViewName(widget.trend),
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
                                      final newState = !isFavorite;

                                      final ok = await BetsService().postNewFavorite(
                                        await _storage.read(key: "sessionToken") ?? "none",
                                        widget.trend.ticker,
                                      );

                                      if (ok) {
                                        if (!mounted) return;
                                        setState(() {
                                          isFavorite = newState;
                                        });
                                        homeScreenKey.currentState?.refreshFavorites();
                                        marketsPageKey.currentState?.toggleFavorite(
                                          widget.trend.ticker,
                                          onlyLocal: true,
                                        );
                                      }
                                    },
                                    icon: Icon(
                                      isFavorite
                                          ? FontAwesomeIcons.solidStar
                                          : FontAwesomeIcons.star,
                                      size: 32,
                                      color: Colors.yellow,
                                    ),
                                  ),
                                  const SizedBox(height: 80),
                                ],
                              ),
                            ],
                          ),
                          AutoSizeText(
                            widget.trend.name,
                            maxLines: 2,
                            style: GoogleFonts.syncopate(
                              fontSize: 30,
                              fontWeight: FontWeight.w100,
                              color: Colors.white,
                            ),
                          ),
                          Row(
                            children: [
                              (widget.trend.dailyGain >= 0)
                                  ? const Icon(FontAwesomeIcons.arrowTrendUp,
                                  color: Colors.green, size: 22)
                                  : const Icon(FontAwesomeIcons.arrowTrendDown,
                                  color: Colors.red, size: 22),
                              const SizedBox(width: 6),
                              Text(
                                ' ${widget.trend.dailyGain.abs().toStringAsFixed(2)}%',
                                style: GoogleFonts.montserrat(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w400,
                                  color: widget.trend.dailyGain >= 0
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),

                          Row(
                            children: [
                              Column(
                                children: [
                                  Text(
                                    '${strings?.get('close') ?? 'Close'}: '
                                        '${(widget.trend.close > 1 ? '${widget.trend.close.toStringAsFixed(2)}' : '${widget.trend.close.toStringAsFixed(4)}')}'
                                        '${widget.currency}',
                                    style: GoogleFonts.montserrat(
                                      fontSize: ( widget.trend.close < 1000 ? 20 : 15),
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  Text(
                                    '${strings?.get('current') ?? 'Current'}: '
                                        '${(widget.trend.current > 1 ? '${widget.trend.current.toStringAsFixed(2)}' : '${widget.trend.current.toStringAsFixed(4)}')}'
                                        '${widget.currency}',
                                    style: GoogleFonts.montserrat(
                                      fontSize:  ( widget.trend.current < 1000 ? 20 : 15),
                                      fontWeight: FontWeight.w600,
                                      color: widget.trend.dailyGain >= 0
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              _ViewChartCTA(
                                controller: _pulseCtrl,
                                label: strings!.get('viewChart') ?? "View chart",
                                heroTag: 'chart-${widget.trend.ticker}',
                                onTap: () {
                                  Common().vibrate(20, 60);
                                  Navigator.of(context).pop();
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (BuildContext context) {
                                      return ClipRRect(
                                        borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(25),
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
                                                  child: Hero(
                                                    tag: 'chart-${widget.trend.ticker}',
                                                    child: CandlesticksView(
                                                      ticker: widget.trend.ticker,
                                                      name: widget.trend.name,
                                                      controller: widget.controller,
                                                      iconPath: widget.trend.icon,
                                                    ),
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

class _ViewChartCTA extends StatefulWidget {
  final AnimationController controller;
  final VoidCallback onTap;
  final String label;
  final String heroTag;

  const _ViewChartCTA({
    required this.controller,
    required this.onTap,
    required this.label,
    required this.heroTag,
  });

  @override
  State<_ViewChartCTA> createState() => _ViewChartCTAState();
}

class _ViewChartCTAState extends State<_ViewChartCTA> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final t = CurvedAnimation(parent: widget.controller, curve: Curves.easeInOut);
    const double size = 80;

    return Column(
      children: [
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTapDown: (_) => setState(() => _pressed = true),
            onTapCancel: () => setState(() => _pressed = false),
            onTapUp: (_) => setState(() => _pressed = false),
            onTap: widget.onTap,
            child: AnimatedBuilder(
              animation: t,
              builder: (_, __) {
                final glow = 6 + 10 * (t.value);
                final scale = _pressed ? 0.96 : (1.0 + 0.02 * (t.value - 0.5));

                return Transform.scale(
                  scale: scale,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Halo “breathing”
                      Container(
                        width: size + 18,
                        height: size + 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.greenAccent.withValues(alpha: 0.18),
                              blurRadius: 24 + glow,
                              spreadRadius: 2 + t.value * 2,
                            ),
                          ],
                        ),
                      ),
                      // Anillo exterior translúcido
                      Container(
                        width: size + 8,
                        height: size + 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.20),
                            width: 1.2,
                          ),
                        ),
                      ),
                      // Botón principal con Hero
                      Hero(
                        tag: widget.heroTag,
                        child: Container(
                          width: size,
                          height: size,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.08),
                            border: Border.all(
                              color: Colors.white70.withValues(alpha: 0.18),
                              width: 1.1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              FontAwesomeIcons.chartLine,
                              size: 32,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.label,
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w200,
            color: Colors.white,
          ),
        ),
      ],
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
                        height: MediaQuery.of(context).size.height * 0.56,
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

//------- SKELETON

class SkeletonTrendContainer extends StatelessWidget {
  const SkeletonTrendContainer({super.key});

  Widget _box(double width, double height, {double radius = 6}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  Widget _circle(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        shape: BoxShape.circle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      width: 120,
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            spreadRadius: 1,
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Stack(
        children: [

          Positioned(
            top: 0,
            right: -5,
            child: Text(
              '•',
              style: TextStyle(
                fontSize: 120,
                color: Colors.white.withValues(alpha: 0.1),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _box(42, 42, radius: 6),
                const Spacer(),
                _box(80, 14, radius: 4),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _circle(10),
                    const SizedBox(width: 6),
                    _box(40, 10, radius: 4),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            top: -8,
            left: -8,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.emoji_events,
                color: Colors.white.withValues(alpha: 0.08),
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
