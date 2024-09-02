import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:client_0_0_1/services/BetsService.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';

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

  Trend(
      this.id, this.icon, this.dailyGain, this.name, this.close, this.current);

  Trend.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        name = json['name'],
        icon = json['icon'],
        dailyGain = (json['daily_gain'] as num).toDouble(),
        close = (json['close'] as num).toDouble(),
        current = (json['current'] as num).toDouble();
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
  const TrendDialog({super.key, required this.trend, required this.index, required this.controller});

  static get decodedBody => null;

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
                    (index + 1).toString(),
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
                          if (trend.icon != "null") ...[
                            Image.memory(
                              base64Decode(trend.icon),
                              height: 160,
                              width: 160,
                            )
                          ] else ...[
                            AutoSizeText(
                              Common().createTrendViewName(trend),
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
                                  bool ok = await BetsService().postNewFavorite(
                                      await _storage.read(
                                              key: "sessionToken") ??
                                          "none",
                                      trend.name);
                                  if (ok) {
                                    Common().newFavoriteCompleted(
                                        context,
                                        LocalizedStrings.of(context)!
                                                .updatedFavs ??
                                            "Updated favs!");
                                    Navigator.of(context).pop(true);
                                  }
                                },
                                icon: const Icon(Icons.star_border),
                              ),
                              const SizedBox(height: 90),
                            ],
                          ),
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
                          const Spacer(),
                          IconButton(
                            icon: const Icon(
                                size: 42,
                                Icons.auto_graph_sharp,
                                color: Colors.white),
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
                                              child: CandlesticksView(ticker: trend.id.toString(), name: trend.name, controller: this.controller, iconPath: trend.icon),
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

class TrendContainer extends StatefulWidget {
  final Trend trend;
  final int index;
  final VoidCallback onFavoriteUpdated;
  final MainMenuPageController controller;
  const TrendContainer(
      {super.key,
      required this.trend,
      required this.index,
      required this.onFavoriteUpdated, required this.controller});

  @override
  TrendContainerState createState() => TrendContainerState();
}

class TrendContainerState extends State<TrendContainer> {
  void _showTrendDialog() async {
    bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return TrendDialog(
          trend: widget.trend,
          index: widget.index, controller: widget.controller,
        );
      },
    );
    if (ok == true) {
      widget.onFavoriteUpdated();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showTrendDialog,
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
                  top: 0,
                  right: (widget.index == 0 || widget.index >= 9) ? -20 : -5,
                  child: Text(
                    '${widget.index + 1}',
                    style: TextStyle(
                      letterSpacing: 0,
                      fontSize: 120,
                      color: Colors.white.withOpacity(0.1),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),

                // Main content
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.trend.icon != "null") ...[
                        Image.memory(
                          base64Decode(widget.trend.icon),
                          height: 42,
                          width: 42,
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
                      Text(
                        (widget.trend.dailyGain > 0.0)
                            ? '▲ ${(widget.trend.dailyGain).toStringAsFixed(2)}%'
                            : '▼ ${(widget.trend.dailyGain.abs()).toStringAsFixed(2)}%',
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight:
                              Theme.of(context).brightness == Brightness.dark
                                  ? FontWeight.w200
                                  : FontWeight.w500,
                          color: widget.trend.dailyGain > 0.0
                              ? Colors.green
                              : Colors.red,
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
