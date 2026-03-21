import 'dart:convert';
import 'dart:ui';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:betrader/services/bets_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/common.dart';
import '../locale/localized_texts.dart';
import '../ui/bets_page.dart';
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
  final double? currentMaxOdd;
  final int? currentMaxOddDirection;
  final int? currentMaxOddZoneId;
  final int? currentMaxOddTimeframe;

  Trend(this.id, this.icon, this.dailyGain, this.name, this.close, this.current,
      this.ticker, {this.currentMaxOdd, this.currentMaxOddDirection, this.currentMaxOddZoneId, this.currentMaxOddTimeframe});

  static double _toDouble(dynamic v) =>
      (v == null) ? 0.0 : (v as num).toDouble();

  static int? _toIntOrNull(dynamic v) =>
      (v == null) ? null : (v as num).toInt();

  Trend.fromJson(Map<String, dynamic> json)
      : id = (json['id'] as num?)?.toInt() ?? 0,
        name = json['name'] as String? ?? '',
        icon = json['icon'] as String? ?? '',
        dailyGain = _toDouble(json['dailyGain']),
        close = _toDouble(json['close']),
        current = _toDouble(json['current']),
        ticker = json['ticker'] as String? ?? '',
        currentMaxOdd = json['currentMaxOdd'] != null
            ? _toDouble(json['currentMaxOdd'])
            : null,
        currentMaxOddDirection = _toIntOrNull(json['currentMaxOddDirection']),
        currentMaxOddZoneId = _toIntOrNull(json['currentMaxOddZoneId']),
        currentMaxOddTimeframe = _toIntOrNull(json['currentMaxOddTimeframe']);
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
  bool _maxOddLoading = false;
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
                          if (widget.trend.currentMaxOdd != null && widget.trend.currentMaxOddDirection != null) ...[
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: _maxOddLoading ? null : () async {
                                final zoneId = widget.trend.currentMaxOddZoneId;
                                if (zoneId == null || zoneId <= 0) return;
                                Common().vibrate(20, 60);
                                setState(() => _maxOddLoading = true);
                                try {
                                  final prefs = await SharedPreferences.getInstance();
                                  final currency = (prefs.getBool('dollarCurrency') ?? false) ? 'USD' : 'EUR';
                                  final timeframe = widget.trend.currentMaxOddTimeframe ?? 24;
                                  final zones = await BetsService().fetchBetZones(widget.trend.ticker, timeframe, null, currency: currency);
                                  final matching = zones.where((z) => z.id == zoneId).toList();
                                  final zone = matching.isEmpty ? null : matching.first;
                                  if (zone == null || !mounted) return;
                                  final rectZones = Common().getRectangleZonesFromBetZones([zone], widget.trend.current);
                                  if (rectZones.isEmpty || !mounted) return;
                                  Navigator.of(context).pop();
                                  if (!mounted) return;
                                  await Navigator.of(context).push(
                                    PageRouteBuilder(
                                      pageBuilder: (_, __, ___) => BetConfirmationPage(
                                        name: widget.trend.name,
                                        menuController: widget.controller,
                                        chartTimeframeHours: timeframe,
                                        zone: rectZones.first,
                                        currentValue: widget.trend.current,
                                        iconPath: widget.trend.icon,
                                        fromDirectMaxOddFlow: true,
                                      ),
                                      transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
                                    ),
                                  );
                                } finally {
                                  if (mounted) setState(() => _maxOddLoading = false);
                                }
                              },
                              child: Row(mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  MaxOddRectangleZone(
                                    maxOdd: widget.trend.currentMaxOdd!,
                                    direction: widget.trend.currentMaxOddDirection!,
                                    currentPrice: widget.trend.current,
                                    isLarge: true,
                                    timeframeHours: widget.trend.currentMaxOddTimeframe ?? 24,
                                    isLoading: _maxOddLoading,
                                  ),
                                ],
                              ),
                            ),
                          ],
                          Row(
                            children: [
                              Column(
                                children: [
                                  Text(
                                    '${strings?.get('close') ?? 'Close'}: '
                                        '${(widget.trend.close > 1 ? widget.trend.close.toStringAsFixed(2) : widget.trend.close.toStringAsFixed(4))}'
                                        '${widget.currency}',
                                    style: GoogleFonts.montserrat(
                                      fontSize: ( widget.trend.close < 1000 ? 20 : 15),
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  Text(
                                    '${strings?.get('current') ?? 'Current'}: '
                                        '${(widget.trend.current > 1 ? widget.trend.current.toStringAsFixed(2) : widget.trend.current.toStringAsFixed(4))}'
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
                                  Common().applyImmersive();
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
    const double size = 65;

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
                Common().applyImmersive(),
                popTrendDialog(
                    context, widget.trend, widget.index, widget.controller)
              },
              onLongPress: () => {
                Common().vibrate(),
                Common().applyImmersive(),
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (BuildContext context) {
                    return ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(25.0)),
                      child: SizedBox(
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
          if (widget.trend.currentMaxOdd != null && widget.trend.currentMaxOddDirection != null)
            Positioned(
              top: 8,
              right: 8,
              child: MaxOddRectangleZone(
                maxOdd: widget.trend.currentMaxOdd!,
                direction: widget.trend.currentMaxOddDirection!,
                currentPrice: widget.trend.current,
              ),
            ),
        ],
      ),
    );
  }
}

/// Widget para dibujar el pequeño RectangleZone del max odd. Público para usar en listas (grid 2x2).
class MaxOddRectangleZone extends StatelessWidget {
  final double maxOdd;
  final int direction; // +1 verde, 0 amarillo, -1 rojo
  final double currentPrice;
  final bool isLarge;
  /// Timeframe en horas (1, 2, 4, 24). Si no null y isLarge, se muestra "XH" igual que en markets_page pero escalado.
  final int? timeframeHours;
  /// Mientras true se muestra un CircularProgressIndicator como en store (mismo estilo).
  final bool isLoading;

  const MaxOddRectangleZone({super.key,
    required this.maxOdd,
    required this.direction,
    required this.currentPrice,
    this.isLarge = false,
    this.timeframeHours,
    this.isLoading = false,
  });

  Color _getFillColor() {
    if (direction == 1) {
      return Colors.green.withValues(alpha: 1);
    } else if (direction == -1) {
      return Colors.red.withValues(alpha: 1);
    } else {
      return Colors.orange.withValues(alpha: 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    const double largeW = 74;
    const double largeH = 45;
    const double smallW = 40;
    const double smallH = 24;
    final double w = isLarge ? largeW : smallW;
    final double h = isLarge ? largeH : smallH;
    final showTimeframe = isLarge && timeframeHours != null;

    final content = CustomPaint(
      size: Size(w, h),
      painter: _MaxOddRectangleZonePainter(
        maxOdd: maxOdd,
        fillColor: _getFillColor(),
        isLarge: isLarge,
        hideText: isLoading,
      ),
    );

    Widget inner;
    if (!showTimeframe) {
      inner = content;
    } else {
      const double refW = 155, refH = 90;
      final double scaleW = largeW / refW;
      final double scaleH = largeH / refH;
      final double timeframeFontSize = 32 * (scaleW + scaleH) / 2;
      final double timeframeTop = -20 * scaleH;
      final double timeframeLeft = -15 * scaleW;
      inner = Stack(
        clipBehavior: Clip.none,
        children: [
          content,
          Positioned(
            top: timeframeTop,
            left: timeframeLeft,
            child: Text(
              '${timeframeHours!.clamp(1, 24)}H',
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: timeframeFontSize,
                fontWeight: FontWeight.w600,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    offset: const Offset(1, 1),
                    blurRadius: 2,
                  ),
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: timeframeTop,
            right: -20 * scaleW,
            child: Icon(
              FontAwesomeIcons.fireFlameSimple,
              color: const Color(0xFFE25822),
              size: timeframeFontSize * 1.3,
            ),
          ),
        ],
      );
    }

    if (isLoading) {
      return SizedBox(
        width: w,
        height: h,
        child: Stack(
          children: [
            inner,
            Positioned.fill(
              child: Center(
                child: CircularProgressIndicator(
                  color: Colors.white70,
                  strokeWidth: 2.5
                ),
              ),
            ),
          ],
        ),
      );
    }
    return SizedBox(width: w, height: h, child: inner);
  }
}

class _MaxOddRectangleZonePainter extends CustomPainter {
  final double maxOdd;
  final Color fillColor;
  final bool isLarge;
  final bool hideText;

  _MaxOddRectangleZonePainter({
    required this.maxOdd,
    required this.fillColor,
    this.isLarge = false,
    this.hideText = false,
  });

  Color oddsToColor(double odds, Color fillColor) {
    const double minOdds = 1.0;
    const double maxOdds = 6.0;

    final double clamped = odds.clamp(minOdds, maxOdds).toDouble();

    const double minAlpha = 0.65;
    const double maxAlpha = 0.85;

    final double t = (clamped - minOdds) / (maxOdds - minOdds);
    final double alpha = minAlpha + (maxAlpha - minAlpha) * t;

    return fillColor.withValues(alpha: alpha);
  }

  Shader buildZoneShader(Color base, double odds, Rect rect) {
    const double minOdds = 1.0;
    const double maxOdds = 6.0;

    final double t = ((odds.clamp(minOdds, maxOdds) - minOdds) / (maxOdds - minOdds)).toDouble();

    final hsl = HSLColor.fromColor(base);

    final double baseLight = hsl.lightness;

    final double darkFactor = lerpDouble(0.65, 0.8, t)!;
    final double lightFactor = lerpDouble(1.02, 1.15, t)!;

    const double transparencyFactor = 0.92;

    final Color startColor = hsl
        .withLightness((baseLight * darkFactor).clamp(0.0, 1.0))
        .toColor()
        .withValues(alpha: transparencyFactor);

    final Color endColor = hsl
        .withLightness((baseLight * lightFactor).clamp(0.0, 1.0))
        .toColor()
        .withValues(alpha: transparencyFactor);

    return LinearGradient(
      colors: [
        startColor,
        endColor,
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(rect);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrectRadius = Radius.circular(12);
    final RRect rrect = RRect.fromRectAndRadius(rect, rrectRadius);

    // Calcular factor de elevación basado en las odds
    const double minOdds = 1.0;
    const double maxOdds = 6.0;
    final double clampedOdds = maxOdd.clamp(minOdds, maxOdds).toDouble();
    final double elevationFactor = (clampedOdds - minOdds) / (maxOdds - minOdds);

    // Desplazamiento de sombra proporcional a las odds
    final double shadowOffset = 1.5 + (elevationFactor * 2.0);
    final RRect shadowRrect = RRect.fromRectAndRadius(
      rect.shift(Offset(shadowOffset, shadowOffset)),
      rrectRadius,
    );

    // Intensidad de sombra proporcional a las odds
    final double shadowAlpha1 = 0.25 + (elevationFactor * 0.25);
    final double shadowAlpha2 = 0.3 + (elevationFactor * 0.3);
    final double blurRadius1 = 3.0 + (elevationFactor * 3.0);
    final double blurRadius2 = 1.5 + (elevationFactor * 1.5);

    // Primera capa de sombra
    final paintShadow1 = Paint()
      ..isAntiAlias = true
      ..color = Colors.black.withValues(alpha: shadowAlpha1)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurRadius1)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(shadowRrect, paintShadow1);

    // Segunda capa de sombra
    final paintShadow2 = Paint()
      ..isAntiAlias = true
      ..color = Colors.black.withValues(alpha: shadowAlpha2)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurRadius2)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(shadowRrect, paintShadow2);

    // Relleno con shader
    final paintFill = Paint()
      ..isAntiAlias = true
      ..shader = buildZoneShader(fillColor, maxOdd, rect)
      ..color = oddsToColor(maxOdd, fillColor)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect, paintFill);

    // Borde fino con efecto cristal pálido
    final paintBorder = Paint()
      ..isAntiAlias = true
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;
    canvas.drawRRect(rrect, paintBorder);

    if (!hideText) {
      // Texto con las odds - más grande y sin tanto padding
      final fontSize = isLarge ? 20.0 : 12.0;
      final oddsTextSpan = TextSpan(
        text: 'x${maxOdd.toStringAsFixed(isLarge ? 2 : 1)}',
        style: GoogleFonts.montserrat(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w400,
        ),
      );

      final textPainter = TextPainter(
        text: oddsTextSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout(minWidth: 0, maxWidth: size.width);
      final textX = (size.width - textPainter.width) / 2;
      final textY = (size.height - textPainter.height) / 2;
      textPainter.paint(canvas, Offset(textX, textY));
    }
  }

  @override
  bool shouldRepaint(covariant _MaxOddRectangleZonePainter oldDelegate) =>
      oldDelegate.maxOdd != maxOdd || oldDelegate.fillColor != fillColor || oldDelegate.hideText != hideText;
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
