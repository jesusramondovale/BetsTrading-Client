import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/common.dart';
import '../locale/localized_texts.dart';
import '../services/bets_service.dart';
import '../ui/candlesticks_view.dart';
import '../ui/layout_page.dart';

class Favorite {
  final String id;
  final String name;
  final String icon;
  final double dailyGain;
  final double close;
  final double current;
  final String userId;
  final String ticker;

  Favorite(this.id, this.icon, this.dailyGain, this.name, this.close,
      this.current, this.userId, this.ticker);

  Favorite.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        name = json['name'],
        icon = json['icon'],
        dailyGain = (json['daily_gain'] as num).toDouble(),
        close = (json['close'] as num).toDouble(),
        current = (json['current'] as num).toDouble(),
        userId = json['user_id'].toString(),
        ticker = json['ticker'];
}

class Favorites {
  final List<Favorite> favorites;
  final int length;

  Favorites(this.favorites, this.length);

  bool containsTicker(String ticker) {
    if (favorites.isEmpty) return false;
    return favorites.any((favorite) => favorite.ticker == ticker);
  }
}

class FavoriteDialog extends StatefulWidget {
  final Favorite favorite;
  final MainMenuPageController controller;
  final String currency;

  const FavoriteDialog({
    super.key,
    required this.favorite,
    required this.controller,
    required this.currency,
  });

  @override
  State<FavoriteDialog> createState() => _FavoriteDialogState();
}

class _FavoriteDialogState extends State<FavoriteDialog> with SingleTickerProviderStateMixin {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  bool isFavorite = true;
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
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
                  clipBehavior: Clip.hardEdge,
                  children: [
                    Positioned(
                      top: 0,
                      right: -100,
                      child: Icon(
                        FontAwesomeIcons.solidStar,
                        color: Colors.grey.withValues(alpha: 0.08),
                        size: 350,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (widget.favorite.icon != "null") ...[
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: widget.favorite.icon.startsWith('http')
                                      ? Image.network(
                                    widget.favorite.icon,
                                    height: 130,
                                    width: 130,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, _) => Text(
                                      widget.favorite.name,
                                      maxLines: 1,
                                      style: GoogleFonts.roboto(
                                        fontSize: 36,
                                        fontWeight: FontWeight.w100,
                                        color: Colors.white,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  )
                                      : Image.memory(
                                    base64Decode(widget.favorite.icon),
                                    height: 130,
                                    width: 130,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, _) => Text(
                                      widget.favorite.name,
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
                              ] else ...[
                                AutoSizeText(
                                  Common().createFavViewName(widget.favorite),
                                  maxLines: 1,
                                  style: GoogleFonts.josefinSans(
                                    fontSize: 60,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                              const Spacer(),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    iconSize: 50,
                                    onPressed: () async {
                                      final newState = !isFavorite;
                                      bool ok = await BetsService().postNewFavorite(
                                        await _storage.read(key: "sessionToken") ?? "none",
                                        widget.favorite.ticker,
                                      );
                                      if (ok) {
                                        if (!mounted) return;
                                        setState(() => isFavorite = newState);
                                        homeScreenKey.currentState?.refreshFavorites();
                                        marketsPageKey.currentState?.toggleFavorite(
                                          widget.favorite.ticker,
                                          onlyLocal: true,
                                        );
                                      }
                                    },
                                    icon: Icon(
                                      isFavorite ? FontAwesomeIcons.solidStar : FontAwesomeIcons.star,
                                      color: Colors.yellow,
                                      size: 36,
                                    ),
                                  ),
                                  const SizedBox(height: 90),
                                ],
                              ),
                            ],
                          ),
                          AutoSizeText(
                            widget.favorite.name,
                            maxLines: 1,
                            style: GoogleFonts.syncopate(
                              fontSize: 30,
                              fontWeight: FontWeight.w100,
                              color: Colors.white,
                            ),
                          ),
                          Row(
                            children: [
                              (widget.favorite.dailyGain >= 0.0)
                                  ? const Icon(FontAwesomeIcons.arrowTrendUp, color: Colors.green, size: 22)
                                  : const Icon(FontAwesomeIcons.arrowTrendDown, color: Colors.red, size: 22),
                              Text(
                                ' ${(widget.favorite.dailyGain).abs().toStringAsFixed(2)}%',
                                style: GoogleFonts.montserrat(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w400,
                                  color: widget.favorite.dailyGain >= 0.0 ? Colors.green : Colors.red,
                                ),
                              ),
                            ],
                          ),

                          Row(
                            children: [
                              Column(
                                children: [
                                  Text(
                                    '${strings?.get('close') ?? 'Close'}: '
                                        '${(widget.favorite.close > 1 ? widget.favorite.close.toStringAsFixed(2) : widget.favorite.close.toStringAsFixed(4))}'
                                        '${widget.currency}',
                                    style: GoogleFonts.montserrat(
                                      fontSize: ( widget.favorite.close < 1000 ? 20 : 15),
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    '${strings?.get('current') ?? 'Current'}: '
                                      '${(widget.favorite.current > 1 ? widget.favorite.current.toStringAsFixed(2) : widget.favorite.current.toStringAsFixed(4))}'
                                        '${widget.currency}',
                                    style: GoogleFonts.montserrat(
                                      fontSize:  ( widget.favorite.current < 1000 ? 20 : 15),
                                      fontWeight: FontWeight.w500,
                                      color: widget.favorite.dailyGain >= 0.0 ? Colors.green : Colors.red,
                                    ),
                                  )
                                ],
                              ),
                              const Spacer(),
                              _ViewChartCTA(
                                controller: _pulseCtrl,
                                label: strings!.get('viewChart') ?? "View chart",
                                heroTag: 'chart-${widget.favorite.ticker}',
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
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
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
                                                    tag: 'chart-${widget.favorite.ticker}',
                                                    child: CandlesticksView(
                                                      ticker: widget.favorite.ticker,
                                                      name: widget.favorite.name,
                                                      controller: widget.controller,
                                                      iconPath: widget.favorite.icon,
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

class FavoriteContainer extends StatefulWidget {
  final Favorite favorite;
  final VoidCallback onFavoriteUpdated;
  final MainMenuPageController controller;

  const FavoriteContainer(
      {super.key,
      required this.favorite,
      required this.onFavoriteUpdated,
      required this.controller});

  @override
  FavoriteContainerState createState() => FavoriteContainerState();
}

class FavoriteContainerState extends State<FavoriteContainer> {
  String _currencyChar = '€';

  Future<void> loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('dollarCurrency') ?? false) {
      _currencyChar = '\$';
    }
  }

  void popFavoritesDialog(
      BuildContext context, Favorite fav, MainMenuPageController controller) {
    loadCurrency();
    showGeneralDialog(
      context: context,
      pageBuilder: (BuildContext buildContext, Animation<double> animation,
          Animation<double> secondaryAnimation) {
        return FavoriteDialog(favorite: fav, controller: controller, currency: _currencyChar);
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

  Color calculateShadowColor(double dailyGain) {
    const double maxGain = 7;
    const double minAlpha = 0.01;
    const double maxAlpha = 0.5;

    double normalized = (dailyGain.abs() / maxGain).clamp(0.0, 1.0);
    double alpha = minAlpha + (maxAlpha - minAlpha) * sqrt(normalized);

    if (dailyGain > 0.15) {
      return Colors.green.withValues(alpha: alpha);
    } else if (dailyGain < (-0.15)) {
      return Colors.red.withValues(alpha: alpha);
    } else {
      return Colors.grey.withValues(alpha: 0.15);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 20),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(

          onTap: () {
            Common().vibrate();
            Common().applyImmersive();
            popFavoritesDialog(context, widget.favorite, widget.controller);
          },
          onLongPress: () {
            Common().vibrate();
            Common().applyImmersive();
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (BuildContext context) {
                return ClipRRect(
                  borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(25.0)),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.56,
                    child: OverflowBox(
                      alignment: Alignment.topCenter,
                      maxHeight: MediaQuery.of(context).size.height,
                      child: Column(
                        children: [
                          Expanded(
                            child: CandlesticksView(
                              ticker: widget.favorite.ticker,
                              name: widget.favorite.name,
                              controller: widget.controller,
                              iconPath: widget.favorite.icon,
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
          splashColor: Colors.white12,
          borderRadius: BorderRadius.circular(8),
          child: Ink(
            decoration: BoxDecoration(
              color: calculateShadowColor(widget.favorite.dailyGain),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 0.8, sigmaY: 0.8),
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.favorite.icon != "null" &&
                          !widget.favorite.icon.startsWith("http")) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.memory(
                            base64Decode(widget.favorite.icon),
                            height: 40,
                            width: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Text(
                              widget.favorite.name,
                              maxLines: 1,
                              style: GoogleFonts.roboto(
                                fontSize: 36,
                                fontWeight: FontWeight.w100,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      ] else if (widget.favorite.icon.startsWith("http")) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            widget.favorite.icon,
                            width: 40,
                            height: 40,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => Text(
                              widget.favorite.name,
                              maxLines: 1,
                              style: GoogleFonts.roboto(
                                fontSize: 36,
                                fontWeight: FontWeight.w100,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      ] else ...[
                        AutoSizeText(
                          Common().createFavViewName(widget.favorite),
                          maxLines: 1,
                          style: GoogleFonts.josefinSans(
                            fontSize: 30,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      AutoSizeText(
                        widget.favorite.name,
                        maxLines: 1,
                        style: GoogleFonts.robotoCondensed(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          (widget.favorite.dailyGain >= 0.0)
                              ? const Icon(
                            FontAwesomeIcons.arrowTrendUp,
                            color: Colors.green,
                            size: 12,
                          )
                              : const Icon(
                            FontAwesomeIcons.arrowTrendDown,
                            color: Colors.red,
                            size: 12,
                          ),
                          Text(
                            (widget.favorite.dailyGain >= 0.0)
                                ? ' ${(widget.favorite.dailyGain).toStringAsFixed(2)}%'
                                : ' ${(widget.favorite.dailyGain.abs()).toStringAsFixed(2)}%',
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              fontWeight: FontWeight.w300,
                              color: widget.favorite.dailyGain >= 0.0
                                  ? Colors.green
                                  : Colors.red,
                            ),
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
      ),
    );
  }



}

//------- SKELETON

class SkeletonFavoriteContainer extends StatelessWidget {
  const SkeletonFavoriteContainer({super.key});

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
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.07),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 20),
      width: (Random().nextBool() ? 80 : 110),
      decoration: BoxDecoration(
        color: (Random().nextBool() ? Colors.green.withValues(alpha: 0.35) : Colors.red.withValues(alpha: 0.35)) ,
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
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            top: 0,
            right: -30,
            child: Icon(
              FontAwesomeIcons.solidStar,
              color: Colors.grey.withValues(alpha: 0.1),
              size: 120,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _box(40, 40, radius: 6),
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
        ],
      ),
    );
  }
}


