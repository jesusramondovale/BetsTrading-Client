import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';

import '../helpers/common.dart';
import '../locale/localized_texts.dart';
import '../services/BetsService.dart';
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

  Favorite(this.id, this.icon, this.dailyGain, this.name, this.close,
      this.current, this.userId);

  Favorite.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        name = json['name'],
        icon = json['icon'],
        dailyGain =  (json['daily_gain'] as num).toDouble(),
        close = (json['close'] as num).toDouble(),
        current = (json['current'] as num).toDouble(),
        userId = json['user_id'].toString();
}

class Favorites {
  final List<Favorite> favorites;
  final int length;

  Favorites(this.favorites, this.length);
}

class FavoriteDialog extends StatelessWidget {
  final Favorite favorite;
  final MainMenuPageController controller;
  const FavoriteDialog({super.key, required this.favorite, required this.controller});
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

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
                  right: -100,
                  child: Icon(Icons.star,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey.withOpacity(0.1)
                          : Colors.grey,
                      size: 350),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: <Widget>[
                          if (favorite.icon != "null") ... [
                            Image.memory(
                              base64Decode(favorite.icon),
                              height: 100,
                              width: 100,
                            )
                          ]
                          else ... [
                            AutoSizeText(
                              Common().createFavViewName(favorite),
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
                                      favorite.name);
                                  if (ok) {
                                    Common().newFavoriteCompleted(context,
                                        LocalizedStrings.of(context)!.updatedFavs ?? "Updated favs!");
                                    Navigator.of(context).pop(true);
                                  }
                                },
                                icon: const Icon(Icons.star),
                              ),
                              const SizedBox(height: 90),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      AutoSizeText(
                        favorite.name,
                        maxLines: 1,
                        style: GoogleFonts.robotoCondensed(
                          fontSize: 40,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        (favorite.dailyGain > 0.0)
                            ? '▲ ${(favorite.dailyGain).toStringAsFixed(2)}%'
                            : '▼ ${(favorite.dailyGain.abs()).toStringAsFixed(2)}%',
                        style: GoogleFonts.montserrat(
                          fontSize: 25,
                          fontWeight: FontWeight.w400,
                          color: favorite.dailyGain > 0.0
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${strings?.close ?? 'Close'}: ${favorite.close.toStringAsFixed(2)}€',
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            '${strings?.current ?? 'Current'}: ${favorite.current.toStringAsFixed(2)}€',
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: favorite.dailyGain >= 0.0
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
                                              child: CandlesticksView(favorite.id.toString(), favorite.name, controller: this.controller, iconPath: favorite.icon ),
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

class FavoriteContainer extends StatefulWidget {
  final Favorite favorite;
  final VoidCallback onFavoriteUpdated;
  final MainMenuPageController controller;
  const FavoriteContainer({super.key, required this.favorite, required this.onFavoriteUpdated, required this.controller});

  @override
  FavoriteContainerState createState() => FavoriteContainerState();
}

class FavoriteContainerState extends State<FavoriteContainer> {

  void _showFavoriteDialog() async {
    bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return FavoriteDialog(favorite: widget.favorite, controller: widget.controller,);
      },
    );

    if (ok == true){
      widget.onFavoriteUpdated(); // Llamar al callback
    }

  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showFavoriteDialog,
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
                //Background star
                Positioned(
                  top: 0,
                  right: -30,
                  child: Icon(Icons.star,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey.withOpacity(0.1)
                          : Colors.grey,
                      size: 150),
                ),

                // Main content
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.favorite.icon != "null") ... [
                        Image.memory(
                          base64Decode(widget.favorite.icon),
                          height: 40,
                          width: 40,
                        )
                      ]
                      else ... [
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
                      const Spacer(),
                      AutoSizeText(
                        widget.favorite.name,
                        maxLines: 1,
                        style: GoogleFonts.robotoCondensed(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        (widget.favorite.dailyGain > 0.0)
                            ? '▲ ${(widget.favorite.dailyGain).toStringAsFixed(2)}%'
                            : '▼ ${(widget.favorite.dailyGain.abs()).toStringAsFixed(2)}%',
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight:
                              Theme.of(context).brightness == Brightness.dark
                                  ? FontWeight.w200
                                  : FontWeight.w500,
                          color: widget.favorite.dailyGain > 0.0
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
